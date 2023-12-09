% 该程序演示如何利用相机的内参数来进行图像的畸变去除
% 张林，同济大学，2023年4月
% 相机的内参数已经通过前期标定步骤获得，并已存储在磁盘中为文件'cameraParams.mat'


%%%%%%%%%%%%%%%%%%% 导入相机参数数据 %%%%%%%%%%%%%%%%%%%
% 'cameraParams'是一个cameraParameters对象，包含了相机标定的结果。
% 这些参数用于图像的畸变去除和3D场景重建等任务。
% 共拍摄了20张图（19张能用），每张图上有 54个关键点

% ImageSize: 图像的尺寸，格式为 [高度, 宽度]，单位通常为像素。
% RadialDistortion: 径向畸变系数的数组，通常包含两个或三个系数（k1, k2, k3）。
% TangentialDistortion: 切向畸变系数的数组，通常包含两个系数（p1, p2）。
% WorldPoints: 标定图案上的点在世界坐标系中的位置，大小为54x2，表示有54个点，每个点有两个坐标（X,Y）。
% WorldUnits: 世界坐标点的单位，这里是 'millimeters'。
% EstimateSkew: 表示是否估计图像的倾斜（1为是，0为否）。
% NumRadialDistortionCoefficients: 表示使用的径向畸变系数的数量。
% EstimateTangentialDistortion: 表示是否估计切向畸变（1为是，0为否）。
% ReprojectionErrors: 重投影误差的数组，大小为54x2x19，表示54个世界点在19个图像上的X和Y重投影误差。
% DetectedKeypoints: 检测到的关键点的逻辑数组，大小为54x19，表示54个点在19个图像上是否被检测到。
% RotationVectors: 旋转向量的数组，大小为1x9x19，表示19个标定图像的旋转向量，每个旋转向量由3个元素组成。
% K: 内参矩阵，大小为3x3，包含焦距和主点等内参。
% NumPatterns: 使用的标定图案的数量，这里是19。
% Intrinsics: 内参数对象，通常包含多个内参信息。
% PatternExtrinsics: 每个标定图案的外参，包括旋转和平移，大小为1x7x19，每组外参包含一个3x3的旋转矩阵和一个3x1的平移向量。
% FocalLength: 相机的焦距，单位是像素，包含两个元素（fx, fy）。
% PrincipalPoint: 相机的主点，即图像中心，包含两个坐标（cx, cy）。
% Skew: 图像的倾斜系数，通常为0，表示像素轴正交。
% MeanReprojectionError: 平均重投影误差，衡量标定准确性的单个浮点数。
% RejectedPoints: 被拒绝的点，未用于标定的点的数组，其大小取决于在标定过程中被拒绝的点的数量。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
camParamsFile = load('cameraParams.mat');
camPrams = camParamsFile.cameraParams;

%读入由同款相机拍摄的原始图像，该图像带有明显畸变
oriImg = imread('img.png');

%对原始输入图像进行图像去畸变操作，这里需要利用已经获得的相机内参数
undistortedImage = undistortImage(oriImg, camPrams);

%显示结果
figure; 
imshowpair(oriImg, undistortedImage, 'montage');
title('Original Image (left) vs. Corrected Image (right)');

