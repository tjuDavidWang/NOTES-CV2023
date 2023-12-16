# 鸟瞰环视图生成

这个项目包含一个 C++ 程序，用于从四个鱼眼相机的视频生成辅助驾驶的鸟瞰环视图。它使用 OpenCV 库进行图像处理和视觉计算。

## 准备工作

1. 配置实验环境与本机Opencv环境相同

   可参考博客：https://blog.csdn.net/u014361280/article/details/127351257

2. 若打开.sln没有显示`include/birdview.h`与`include/config.h`需要手动添加

4. 从[百度网盘](https://pan.baidu.com/s/1j4hYF8w8T21d77DHiU3DvA?pwd=bp8p)下载四个侧向的视频放到data下（提取码：bp8p ）

## 代码实现

### 数据文件

在data文件夹下包含以下三种文件，其作用如下：

- **视频文件**：`f.avi`, `l.avi`, `b.avi`, `r.avi` 是四个鱼眼相机拍摄的视频文件，分别代表车辆的前、左、后、右视角。
- **单应矩阵文件**：`homofor4cams.txt` 包含从鸟瞰视图到四个相机成像平面的单应矩阵。这些矩阵用于映射从一个视图平面到另一个视图平面。
- **相机内参数文件**：`intrinsics.xml` 包含四个相机的内部参数，如相机矩阵和畸变参数。

### main函数

- 调用 `GenerateMappingTable` 函数，使用相机内参数和单应矩阵生成映射表。这些映射表用于将鸟瞰视图上的点映射到鱼眼图像上的点。

  ```cpp
  GenerateMappingTable(dataDir + "intrinsics.xml", dataDir+ "homofor4cams.txt");
  ```

- 调用 `GenerateBirdView` 函数，根据生成的映射表和原始鱼眼视频，生成鸟瞰环视图。

  ```cpp
  GenerateBirdView(dataDir+ "f.avi", dataDir+"l.avi",
  	             dataDir+"b.avi", dataDir + "r.avi",
  	             dataDir+"front_table.txt", 
  				 dataDir+"left_table.txt", 
  			     dataDir+"back_table.txt", 
  				 dataDir+"right_table.txt");
  ```

### 生成映射表 

在`GenerateMappingTable`函数中实现

1. 读取并处理相机内参数和单应矩阵。

   相机内参数包括相机的内参矩阵（K）和畸变系数（D）。这些参数是从 `intrinsics.xml` 文件中读取的。其内容如下：

   ```xml
   <?xml version="1.0"?>
   <opencv_storage>
   <f_intrinsic type_id="opencv-matrix">
     <rows>3</rows>
     <cols>3</cols>
     <dt>d</dt>
     <data>
       4.2254733249957701e+02 0. 6.2411613466011192e+02 0.
       4.2130848186628549e+02 5.3764552798679233e+02 0. 0. 1.</data></f_intrinsic>
   <f_distortion type_id="opencv-matrix">
     <rows>4</rows>
     <cols>1</cols>
     <dt>d</dt>
     <data>
       -6.8892222773595149e-02 6.7469688985097044e-05
       -8.6085058046905577e-04 2.8704800194953320e-05</data></f_distortion>
   <f_P type_id="opencv-matrix">
     <rows>3</rows>
     <cols>3</cols>
     <dt>d</dt>
     <data>
       4.2254733249957701e+02 0. 6.2411613466011192e+02 0.
       4.2130848186628549e+02 5.3764552798679233e+02 0. 0. 1.</data></f_P>
       
   <l_intrinsic type_id="opencv-matrix">
   <l_distortion type_id="opencv-matrix">
   <l_P type_id="opencv-matrix">
   
   <b_intrinsic type_id="opencv-matrix">
   <b_distortion type_id="opencv-matrix">
   <b_P type_id="opencv-matrix">
   
   <r_intrinsic type_id="opencv-matrix">
   <r_distortion type_id="opencv-matrix">
   <r_P type_id="opencv-matrix">
   
   </opencv_storage>
   ```

2. 对每个相机调用 `GenerateSingleMappingTable`，生成鸟瞰视图到鱼眼图像的映射表。

   ```cpp
   vector<vector<cv::Point2f>> gMappingTableFront = GenerateSingleMappingTable(mHomographyFront, iBirdsEyeSize, mFrontK, mFrontD);
   ```

   每个相机的映射表是使用其相应的单应矩阵和内参数生成的。这些映射表将用于将鸟瞰视图上的点映射到鱼眼图像上的相应点。

   - 通过下面的代码将homofor4cams.txt（从鸟瞰视图平面到4个相机平面[去畸变后的]的单应矩阵）读到gHomographyMatrices中

     ```cpp
     gHomographyMatrices = ReadHomography(aHomographyPath);
     ```

   - `GenerateSingleMappingTable` 的实现逻辑：

     - 鸟瞰视图-----><mHomography>----->相机成像平面上（去畸变）
     - 相机成像平面上（去畸变）-----><mK.inv() >----->归一化成像平面
     - 归一化成像平面----->齐次坐标/z----->普通成像平面
     - 普通成像平面----->畸变----->鱼眼成像平面

     ```cpp
     vector<vector<cv::Point2f>> GenerateSingleMappingTable(cv::Mat mHomography , cv::Size iImageSize , cv::Mat mK , cv::Mat mD )
     {
     	vector<vector<cv::Point2f>> gMappingTable;
     	gMappingTable.reserve(iImageSize.height); //逐行扫描
     	for (int y=0; y < iImageSize.height; y++)
     	{	
     		//生成这一行的映射信息
     		vector<cv::Point2f> gSubMappingTable;
     		gSubMappingTable.reserve(iImageSize.width);
     		for (int x=0; x < iImageSize.width; x++)
     		{
     			cv::Mat mPoint = (cv::Mat_<double>(3 , 1) << x , y , 1); //鸟瞰视图这一点的齐次坐标
     			mPoint = mHomography * mPoint; //乘上单应矩阵之后，映射到相机成像平面上（去畸变）一点
     
     			mPoint = mK.inv() * mPoint; //映射到归一化成像平面坐标系之下
     			//iPoint，归一化成像平面坐标系上的普通坐标
     			cv::Point2f iPoint(mPoint.at<double>(0 , 0)/mPoint.at<double>(2 , 0) , mPoint.at<double>(1 , 0)/mPoint.at<double>(2 , 0));
     			gSubMappingTable.push_back(iPoint);			
     		}
     		//在归一化成像平面上对点进行畸变操作。注意：得到的结果是在最终成像平面上的
     		cv::fisheye::distortPoints(gSubMappingTable, gSubMappingTable, mK, mD);
     		for (auto & item : gSubMappingTable)
     		{
     			if (item.x <= 0.0)
     			{
     				item.x = 0.0;
     			}
     			else if (item.x >= (float)(iCameraImageSize.width-1))
     			{
     				item.x = (float)(iCameraImageSize.width-1);
     			}
     			if (item.y <=0.0)
     			{
     				item.y = 0.0;
     			}
     			else if (item.y >= (float)(iCameraImageSize.height-1))
     			{
     				item.y = (float)(iCameraImageSize.height-1);
     			}
     		}
     		gMappingTable.push_back(gSubMappingTable);
     	}
     	return gMappingTable;
     }
     ```

     - 会生成四个txt，存放鸟瞰视图中的某个点在鱼眼图像中对应的位置坐标（x, y）

3. 保存这些映射表到本地。

   ```cpp
   SaveMappingTable(dataDir+ "front_table.txt", gMappingTableFront);
   SaveMappingTable(dataDir + "left_table.txt", gMappingTableLeft);
   SaveMappingTable(dataDir + "back_table.txt", gMappingTableBack);
   SaveMappingTable(dataDir+"right_table.txt", gMappingTableRight);
   ```

### 生成鸟瞰环视图 

这个 `GenerateBirdView` 函数首先打开四个视频文件，然后读取映射表，并初始化鸟瞰视图和环视图的矩阵。接着，在一个循环中，它逐帧读取每个视频文件，并使用映射表将每个视角的视频帧映射到各自的鸟瞰视图上。最后，这些单独的鸟瞰视图被合成为一个完整的环视图，然后显示并保存。

- 打开四个鱼眼相机的视频文件

- 读取之前生成的映射表

- 初始化鸟瞰视图和最终环视图的矩阵

- 循环读取每个视频的当前帧，然后对每个视角执行以下操作

- 生成单个视角的鸟瞰视图

  ```cpp
  // 示例：生成前视鸟瞰视图
  cv::Mat iFrontFrame;
  bool bRes1 = iCaptureFront.read(iFrontFrame);
  // ... 同理读取其他视角
  for (int v = 0; v <= maxV; v++) {
      for (int u = minU; u <= maxU; u++) {
          cv::Point2f iMapping = gFrontMappingTable[v][u];
          iFrontBirdsEyeFrame.at<cv::Vec3b>(v, u) = iFrontFrame.at<cv::Vec3b>((int)iMapping.y, (int)iMapping.x);
      }
  }
  // ... 同理对于左、后、右视图
  ```

- 合成环视图

  ```cpp
  // 以合成包含前视部分的环视图为例
  for (int v = 0; v <= maxV; v++) {
      for (int u = minU; u <= maxU; u++) {
          iBirdsEyeImage.at<cv::Vec3b>(v, u) = iFrontBirdsEyeFrame.at<cv::Vec3b>(v, u);
      }
  }
  // ... 同理合成包含左、后、右视部分
  ```

- 显示和保存最终的环视图

  ```cpp
  cv::imshow("show", iBirdsEyeImage);
  outputVideo << iBirdsEyeImage;
  // 循环结束后释放资源
  outputVideo.release();
  ```