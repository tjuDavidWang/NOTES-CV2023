%此程序完整实现了Harris角点检测、block描述子提取、描述子匹配，同时增加了权重的可视化展示
%wwd, Tongji Univ., Nov. 2023

%此程序完整实现了Harris角点检测、block描述子提取、描述子匹配
%Lin Zhang, Tongji Univ., Jun. 2022

clc; clear;

imgColor1 = imread('sse1.bmp');
imgColor2 = imread('sse2.bmp');

% wwd:需要转化为灰度图后才可执行后续过程 
I1 = rgb2gray(imgColor1);
I2 = rgb2gray(imgColor2);

% 参数设定
sigma = 4.0;
thresh = 200000;
nonmaxrad = 5;

% Harris角点检测
[rows, cols] = harrisCornerDetector(I1, sigma, thresh, nonmaxrad);
points1 = [cols, rows];
[rows, cols] = harrisCornerDetector(I2, sigma, thresh, nonmaxrad);
points2 = [cols, rows];

% 描述子提取
[descriptors1, valid_points1] = extractBlockDescriptors(I1, points1, 11);
[descriptors2, valid_points2] = extractBlockDescriptors(I2, points2, 11);

% 参数设定
maxRatioThreshold = 0.6;
match_thresh = 0.04;

% 描述子匹配
[indexPairs, matchDistances] = matchDescriptorsWeight(descriptors1', descriptors2', match_thresh, maxRatioThreshold);

% 匹配的点
matchedPoints1 = valid_points1(indexPairs(:, 1), :);
matchedPoints2 = valid_points2(indexPairs(:, 2), :);

% 确保所有距离是正的
assert(all(matchDistances >= 0), 'Negative match distance found!');
% 线的颜色根据matchDistances确定
normalizedDistances = (matchDistances - min(matchDistances)) / (max(matchDistances) - min(matchDistances));
% 创建一个从深蓝到浅蓝的颜色映射
colormapColors = [linspace(0,1,256)', linspace(0,1,256)', ones(256,1)];
lineColors = interp1(linspace(0, 1, size(colormapColors, 1)), colormapColors, normalizedDistances);

% 可视化结果
[rows1, cols1] = size(I1);
[rows2, cols2] = size(I2);

rows = max([rows1, rows2]);
cols = cols1 + cols2 + 3;
im = zeros(rows, cols);

im(1:rows1, 1:cols1) = I1;
im(1:rows2, cols1 + 4:cols) = I2;

matchedPoints2(:, 1) = matchedPoints2(:, 1) + cols1 + 3;

figure;
imshow(im, []);
hold on;
for index = 1:size(matchedPoints1, 1)
    x1 = matchedPoints1(index, 1);
    y1 = matchedPoints1(index, 2);
    plot(x1, y1, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    x2 = matchedPoints2(index, 1);
    y2 = matchedPoints2(index, 2);
    plot(x2, y2, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    line([x1, x2], [y1, y2], 'Color', lineColors(index, :));
end
hold off;
