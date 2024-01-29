# 相机内外参数标定

项目中data文件夹下存放项目所需的图片资源。

(啊啊啊啊啊，由于LM算法的复杂度有亿点点高，在“运行标定算法”步骤时卡住了，跑不完一点)

## 提取棋盘格角点

```cpp
/***********************************************************************
***********输入*********** 
image: 用于检测角点的棋盘格图像。
iPatternSize: 棋盘格的规模，它是一个cv::Size对象，表示棋盘格每行和每列的角点数。
flags: 一个可选参数，可以是几个预定义标志的组合，例如CALIB_CB_ADAPTIVE_THRESH, CALIB_CB_NORMALIZE_IMAGE和					CALIB_CB_FAST_CHECK，它们用于改进角点检测的性能和准确性。
***********输出***********	  
cornersPerImg: 检测到的角点的位置，它是一个vector<Point2f>对象。每个Point2f包含图像中角点的x和y坐标。
***********************************************************************/
bool patternfound = findChessboardCorners(image, iPatternSize, cornersPerImg, CALIB_CB_ADAPTIVE_THRESH + CALIB_CB_NORMALIZE_IMAGE + CALIB_CB_FAST_CHECK);
```

使用`findChessboardCorners`函数找到标定板上的角点，这些点用于后续的内参计算。这里的`findChessboardCorners`是Opencv库自带的系统函数。

1. **预处理**: 首先将图像转换为灰度图，因为棋盘格角点检测是在灰度图上进行的。
2. **角点检测**: 然后，函数内部使用一个特定的算法（如Harris角点检测或更高级的变体）来识别这些角点。
3. **角点排序**: 一旦检测到角点，算法还会对它们进行排序，确保它们的顺序与棋盘格上的实际顺序相对应。
4. **子像素精化**（可选）: 如果启用，`cornerSubPix`函数会被用来提高角点的定位精度，通常使用迭代最小二乘法将角点位置精细调整到亚像素级别。

## 角点亚像素精度提取

```cpp
/***********************************************************************
***********输入*********** 
imageGray: 进行角点提取的灰度图像。
cornersPerImg: findChessboardCorners函数检测到的角点的初始位置。
Size(11, 11): 搜索窗口的大小，决定了每个角点周围考虑的像素区域大小。
Size(-1, -1): 死区的半径，在这个区域内的像素不会被用于计算。
TermCriteria(CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 30, 0.1): 迭代搜索的终止条件。这里设定为最多30次迭代或者搜索窗口移动小于0.1像素。
***********输出***********	  
cornersPerImg: 经过亚像素精度调整后的角点位置。它将覆盖输入时的初始角点位置。
***********************************************************************/
cornerSubPix(imageGray, cornersPerImg, Size(11, 11), Size(-1, -1), TermCriteria(CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 30, 0.1));
```

使用`cornerSubPix`函数对角点位置进行更精确的调整，以提高标定的准确性。通过考虑角点附近像素的强度值，并通过拟合一个局部二次函数来细化角点位置。这个过程基于图像梯度的方法，它会寻找梯度变化最小的点，这通常对应于真实角点的位置。

## 收集标定数据

 将提取的角点数据以及它们在世界坐标系中的对应位置（通常设定为`z=0`平面上的点）收集起来。

```cpp
	for (int t = 0; t < successImageNum; t++)
	{
		vector<Point3f> tempPointSet;
		for (int i = 0; i < iPatternSize.height; i++)
		{
			for (int j = 0; j < iPatternSize.width; j++)
			{
				/*for each board, for all the corner points, z=0 */
				Point3f tempPoint;
				tempPoint.x = i * square_size.width;
				tempPoint.y = j * square_size.height;
				tempPoint.z = 0;
				tempPointSet.push_back(tempPoint);
			}
		}
		object_Points.push_back(tempPointSet);
	}
```

## 运行标定算法

调用`cvCalibrateCamera2Internal`函数进行实际的标定计算，这个函数内部使用了Levenberg-Marquardt优化算法来最小化重投影误差。

```cpp
lincalibrateCameraRO(object_Points, corners_Seq, image_size, -1, intrinsic_matrix, distortion_coeffs, rotation_vectors, translation_vectors, 0, cv::TermCriteria(cv::TermCriteria::COUNT | cv::TermCriteria::EPS, 100, 1e-6));
```

```cpp
/***********************************************************************
***********输入*********** 
object_Points: 一个三维点的集合，包含了所有标定图像中标定板角点的世界坐标。
corners_Seq: 对应于每张标定图像的二维角点图像坐标。
image_size: 被用于标定的图像的尺寸。
intrinsic_matrix: 用于存储计算出的内在参数的矩阵。
distortion_coeffs: 用于存储计算出的畸变系数的矩阵。
rotation_vectors: 用于存储每张图像的旋转向量。
translation_vectors: 用于存储每张图像的平移向量。
flags: 标定函数的可选参数，可以用来指定额外的约束条件或者优化选项。
cv::TermCriteria: 终止迭代的条件，可以基于迭代次数、误差容限等。
***********输出***********	  
intrinsic_matrix: 经过优化后的相机内在参数矩阵，包括焦距、光心等。
distortion_coeffs: 经过优化后的相机畸变系数。
rotation_vectors: 每张标定图像相对于世界坐标系的旋转向量。
translation_vectors: 每张标定图像相对于世界坐标系的平移向量。
***********************************************************************/
double lincalibrateCameraRO(InputArrayOfArrays _objectPoints, InputArrayOfArrays _imagePoints, Size imageSize, int iFixedPoint, InputOutputArray _cameraMatrix,
	InputOutputArray _distCoeffs, OutputArrayOfArrays _rvecs, OutputArrayOfArrays _tvecs, int flags, TermCriteria criteria)
{
	int rtype = CV_64F;

	//相机内参数矩阵
	Mat cameraMatrix = _cameraMatrix.getMat();
	//畸变系数
	Mat distCoeffs = _distCoeffs.getMat();

	int nimages = int(_objectPoints.total());
	Mat objPt, imgPt, npoints, rvecM, tvecM;

	bool rvecs_mat_vec = _rvecs.isMatVector();
	bool tvecs_mat_vec = _tvecs.isMatVector();

	_rvecs.create(nimages, 1, CV_64FC3);
	rvecM = _rvecs.getMat();
	_tvecs.create(nimages, 1, CV_64FC3);
	tvecM = _tvecs.getMat();

	//这个函数就是把所有标定板的物理点（3D坐标）放在了objPt中，
	//把所有标定板的图像坐标放在了imgPt中
	//npoints是个1维矩阵，与标定板图像个数相同，每个位置存储了对应标定板上的交点个数
	collectCalibrationData(_objectPoints, _imagePoints, objPt, imgPt, npoints);

	int np = npoints.at<int>(0); //第一张标定板图像里面角点个数

	CvMat c_objPt = cvMat(objPt), c_imgPt = cvMat(imgPt), c_npoints = cvMat(npoints);
	CvMat c_cameraMatrix = cvMat(cameraMatrix), c_distCoeffs = cvMat(distCoeffs);
	CvMat c_rvecM = cvMat(rvecM), c_tvecM = cvMat(tvecM);
	//执行实际的标定
	double reprojErr = cvCalibrateCamera2Internal(&c_objPt, &c_imgPt, &c_npoints, cvSize(imageSize),
		&c_cameraMatrix, &c_distCoeffs,
		&c_rvecM, &c_tvecM, flags, cvTermCriteria(criteria));

	// overly complicated and inefficient rvec/ tvec handling to support vector<Mat>
	for (int i = 0; i < nimages; i++)
	{
		if (rvecs_mat_vec)
		{
			_rvecs.create(3, 1, CV_64F, i, true);
			Mat rv = _rvecs.getMat(i);
			memcpy(rv.ptr(), rvecM.ptr(i), 3 * sizeof(double));
		}
		if (tvecs_mat_vec)
		{
			_tvecs.create(3, 1, CV_64F, i, true);
			Mat tv = _tvecs.getMat(i);
			memcpy(tv.ptr(), tvecM.ptr(i), 3 * sizeof(double));
		}
	}

	cameraMatrix.copyTo(_cameraMatrix);
	distCoeffs.copyTo(_distCoeffs);

	return reprojErr;
}
```

## 评估标定结果

使用重投影误差来评估标定的准确性。重投影误差是指实际观测到的角点位置和通过标定得到的相机参数预测的角点位置之间的差异。

```cpp
// 计算每个角点的预测图像位置
cv::projectPoints(tempPointSet, rotation_vectors[i], translation_vectors[i], intrinsic_matrix, distortion_coeffs, image_points2);

// 计算预测图像位置和实际图像位置之间的差异
Mat tempImagePointMat = Mat(1, tempImagePoint.size(), CV_32FC2);
Mat image_points2Mat = Mat(1, image_points2.size(), CV_32FC2);
for (size_t i = 0; i != tempImagePoint.size(); i++) {
    image_points2Mat.at<Vec2f>(0, i) = Vec2f(image_points2[i].x, image_points2[i].y);
    tempImagePointMat.at<Vec2f>(0, i) = Vec2f(tempImagePoint[i].x, tempImagePoint[i].y);
}
// 计算重投影误差
err = cv::norm(image_points2Mat, tempImagePointMat, NORM_L2);
```

## 保存标定结果

将计算出的内在参数和外在参数保存到文件中。

```cpp
	cout << "开始保存定标结果………………" << endl;
	Mat rotation_matrix = Mat(3, 3, CV_32FC1, Scalar::all(0)); /* 保存每幅图像的旋转矩阵 */

	fout << "相机内参数矩阵：" << endl;
	fout << intrinsic_matrix << endl;
	fout << "畸变系数：\n";
	fout << distortion_coeffs << endl;
	for (int i = 0; i < image_Seq.size(); i++)
	{
		fout << "第" << i + 1 << "幅图像的旋转向量：" << endl;
		fout << rotation_vectors[i] << endl;

		/* 将旋转向量转换为相对应的旋转矩阵 */
		cv::Rodrigues(rotation_vectors[i], rotation_matrix);
		fout << "第" << i + 1 << "幅图像的旋转矩阵：" << endl;
		fout << rotation_matrix << endl;
		fout << "第" << i + 1 << "幅图像的平移向量：" << endl;
		fout << translation_vectors[i] << endl;
	}
	cout << "完成保存" << endl;
	fout << endl;
```

1. **投影物理点到图像平面**: 使用相机内参和外参将三维世界中的标定板角点投影回二维图像平面。这会得到预测的图像点位置。
2. **计算重投影误差**: 对于每个标定图像，计算其所有角点的预测图像位置和实际检测到的图像位置之间的差异（即重投影误差）。
3. **误差汇总**: 对所有标定图像的误差求和，计算平均误差，以评估标定的整体质量。

## 图像校正

使用`initUndistortRectifyMap`和`remap`函数对图像进行校正，以消除畸变并改善图像质量。

```cpp
cv::initUndistortRectifyMap(intrinsic_matrix, distortion_coeffs, R, intrinsic_matrix, image_size, CV_32FC1, mapx, mapy);

Mat t = image_Seq[i].clone();
cv::remap(image_Seq[i], t, mapx, mapy, INTER_LINEAR);

string imageFileName = fileNames.at(i);
int pos = imageFileName.find_last_of('\\');
string correctedImgFileName = imageFileName.substr(pos + 1, imageFileName.length() - pos - 5) + "_c.jpg";

cout << "图像" << correctedImgFileName << "..." << endl;
imwrite(correctedImgFileName, t);
```

1. **生成映射**: `initUndistortRectifyMap`函数根据提供的内在参数和畸变系数，计算从畸变图像到校正图像的映射。这个映射由两个浮点数矩阵（`mapx`和`mapy`）表示，它们包含了每个图像点在校正后图像中的新位置。
2. **应用映射**: `remap`函数使用`initUndistortRectifyMap`计算出的映射来调整图像中每个像素的位置，以此来校正图像。