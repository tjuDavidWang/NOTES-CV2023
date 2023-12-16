

# 相机标定及鱼眼图像畸变校正项目

***需要一开始为Visual Studio配置opencv库，可以参考这篇博客：https://blog.csdn.net/u014361280/article/details/127351257***

这个项目使用 OpenCV 库，用于相机标定及鱼眼图像畸变校正。项目分为三个主要步骤，每一步使用一个独立的 `main` 函数。

## 1. 标定板图像采集

**目的:** 收集用于相机标定的标定板图像。

**原理:** 使用相机捕捉包含棋盘格标定板的图像，自动检测标定板上的交叉点。

**关键代码片段:**
1. 设置相机参数，如分辨率：`inputVideo.set(cv::CAP_PROP_FRAME_HEIGHT, 768);`
2. 捕捉图像并检测棋盘格交叉点：`findChessboardCorners(frame, iPatternSize, gCorners, ...)`
3. 保存交叉点检测成功的图像：`imwrite(imgname, frame);`

***注意：需要提前在根目录下新建imgs文件夹，用于存放从相机捕获的图像(也可以用默认的)***



## 2. 相机内参标定

**目的:** 从标定板图像中计算相机的内部参数。

**原理:** 

- **交叉点检测:** 在标定板（通常为棋盘格）上检测交叉点，为后续的内参计算提供必要数据。
- **内参计算:** 使用检测到的交叉点信息计算相机的内参。内参包括焦距、主点（图像中心）和畸变系数。对于鱼眼相机，畸变系数尤其重要，因为它们能够校正由镜头曲率造成的图像扭曲。

**关键代码片段:**
1. **图像预处理与交叉点检测:**

   ```cpp
   // 读取图像
   cv::Mat iImage = imread(aImageFileName);
   // 转换为灰度图像，以便更好地检测特征点
   Mat iImageGray;
   cvtColor(iImage, iImageGray, cv::COLOR_BGR2GRAY);
   // 在图像中找到棋盘格角点
   bool bPatternFound = findChessboardCorners(iImage, iPatternSize, gCorners, ...);
   ```

2. **优化交叉点位置:**
   使用`cornerSubPix`来精确化交叉点位置，这对于后续的内参计算非常重要。

   ```cpp
   cornerSubPix(iImageGray, gCorners, Size(11, 11), Size(-1, -1), TermCriteria(...));
   ```

3. **计算内参和畸变系数:**

   ```cpp
   // 使用 fisheye::calibrate 函数进行鱼眼相机的标定
   fisheye::calibrate(gObjectPoints, gAllCorners, iImageSize, mIntrinsicMatrix, mDistortion, gRotationVectors, gTranslationVectors, flags, cv::TermCriteria(...));
   ```

4. **重投影误差计算:**
   检查标定的准确性，通过计算图像空间中的交叉点与通过相机参数重投影的交叉点之间的误差。

   ```cpp
   fisheye::projectPoints(gTempPointSet, gImagePoints, gRotationVectors[i], gTranslationVectors[i], mIntrinsicMatrix, mDistortion);
   double nError = norm(mImagePoints2Mat, mTempImagePointMat, NORM_L2);
   ```

5. **展示去畸变效果**

   ```cpp
   	cout << "测试一个图像的去畸变效果..." << endl;
   	Mat iTestImage = gImages[0];
   	Mat undistortedTestImg = iTestImage.clone();
   	//cv::remap(testImage,t,mapx, mapy, INTER_LINEAR);
   	cv::fisheye::undistortImage(iTestImage, undistortedTestImg, mIntrinsicMatrix, mDistortion, mIntrinsicMatrix);
   	cv::imshow("original", iTestImage);
   	cv::waitKey(0);
   	cv::imshow("undistortImage", undistortedTestImg);
   	cv::waitKey(0);
   ```

6. **保存相机内参:**

   ```cpp
   //存储相机内参标定结果的文件
   FileStorage camParamsFile("camParams.xml", FileStorage::WRITE);
   camParamsFile << "intrinsic_matrix" << mIntrinsicMatrix;
   camParamsFile << "distortion_coefficients" << mDistortion;
   ```

**相机内参表示：**

```xml
<?xml version="1.0"?>
<opencv_storage>
<intrinsic_matrix type_id="opencv-matrix">
  <rows>3</rows>
  <cols>3</cols>
  <dt>d</dt>
  <data>
    5.9611389204810939e+02 0. 5.1253850648754997e+02 0.
    5.7471335291027879e+02 4.0471855688245915e+02 0. 0. 1.</data></intrinsic_matrix>
<distortion_coefficients type_id="opencv-matrix">
  <rows>4</rows>
  <cols>1</cols>
  <dt>d</dt>
  <data>
    -4.5430636470917961e-02 7.7254642192410530e-02
    -2.4811301636734204e-01 2.3840698853471495e-01</data></distortion_coefficients>
</opencv_storage>

```

- 其含义如下：

  ```cpp
  // intrinsic_matrix
  [5.9611389204810939e+02  0                       5.1253850648754997e+02]
  [0                       5.7471335291027879e+02  4.0471855688245915e+02]
  [0                       0                       1                     ]
  // distortion_coefficients
  [-4.5430636470917961e-02  7.7254642192410530e-02 -2.4811301636734204e-01  2.3840698853471495e-01]
  ```



## 3. 视频去畸变处理

**目的:** 使用已获得的相机内参对输入视频进行实时畸变校正。

**原理:** 读取相机内参并应用于视频流，实时校正图像畸变。

**关键代码片段:**

- 从文件中读取相机内参：`camPramsFile["intrinsic_matrix"] >> mIntrinsicMatrix;`
- 对视频帧进行畸变校正：

  ```cpp
  inputVideo >> oriframe;
  if (oriframe.empty())
      continue;
  Mat undistortFrame = oriframe.clone();
  
  //去畸变undistortImage
  cv::fisheye::undistortImage(oriframe, undistortFrame, mIntrinsicMatrix, mDistortion, mIntrinsicMatrix);
  
  //为方便显示，缩小原始输入视频帧为0.6倍
  cv::resize(oriframe, shrinkedOriFrame,cv::Size(0,0), 0.6, 0.6); 
  
  cv::resize(undistortFrame, shrinkedUndistortedFrame, cv::Size(0, 0), 0.6, 0.6);
  imshow("原始视频", shrinkedOriFrame);
  imshow("去畸变视频", shrinkedUndistortedFrame);
  waitKey(20);
  ```
- 显示原始和校正后的视频帧：`imshow("原始视频", shrinkedOriFrame);`



