%此程序完整实现了SIFT特征点检测、描述子构造、描述子匹配、图像平面间射影变换估计以及图像变换与拼接
%这里的SIFT特征点检测及描述子构造调用了matlab的内置函数。如要深入了解SIFT的实现机制，请参见与教材配套的另一个学习程序opensiftVS。
%张林, 同济大学, 2022年7月

clc;clear;close all;

imgColor1 = imread('sse1.bmp');
imgColor2 = imread('sse2.bmp');

I1 = rgb2gray(imgColor1);
I2 = rgb2gray(imgColor2);

imgColor1 = single(imgColor1);
imgColor2 = single(imgColor2);

%SIFT特征点检测算法是基于灰度图像的
%分别在I1和I2之上检测SIFT特征点，并挑选DoG尺度空间中响应值最高的400个显示出来
%显示的特征点的圆圈半径为该点的特征尺度

% (wwd) points1[SIFTPoints]包含以下五个数据结构
% Location: m-by-2 双精度矩阵，其中每行表示一个特征点的[x, y]坐标。
% Scale: m-by-1 双精度向量，表示每个特征点的尺度。尺度与检测到该特征的高斯图像金字塔的尺度有关。
% Metric: m-by-1 双精度向量，表示每个特征点的指标值。对于SIFT，这通常与特征点的对比度或者其它稳定性指标有关。
% Orientation: m-by-1 双精度向量，表示每个特征点的方向，其值范围在[-π, π]。
% Count: m-by-1 双精度向量，表示每个特征点在不同的尺度上被检测到的次数。
points1 = detectSIFTFeatures(I1);
figure;
imshow(uint8(imgColor1),[]);
hold on;
strong1 = points1.selectStrongest(400);

for index = 1:strong1.length
    x = strong1.Location(index, 1);
    y = strong1.Location(index, 2);
    plot(x, y, 'Marker', 'o', 'MarkerEdgeColor', 'y', 'MarkerSize', strong1.Scale(index));
end

points2 = detectSIFTFeatures(I2);
figure;
imshow(uint8(imgColor2),[]);
hold on;

strong2 = points2.selectStrongest(400);

for index = 1:strong2.length
    x = strong2.Location(index, 1);
    y = strong2.Location(index, 2);
    plot(x, y, 'Marker', 'o', 'MarkerEdgeColor', 'y', 'MarkerSize', strong2.Scale(index));
end

%在两张图像I1和I2之上，根据已经检测到的特征点的信息（位置以及特征尺度），构建描述子
%对于某些太靠近图像边界的特征点以及可能是落在边缘上的点，后续就不用了，保留下来的特征点放在了valid_points里面
%另外，由于一个特征点可能会有多个主方向，对每个主方向都会复制一个独立的特征点出来，因此
%valid_points中点的个数可能反而会比points1多

% (wwd) extractFeatures的返回值
% features：一个 M×N 的矩阵，其中 M 是检测到的关键点数量，N 是每个关键点的特征描述子长度（对于 SIFT，N = 128）。
% valid_points：实际用于提取特征的关键点的位置(无边缘点、多主方向复制)。
[features1, valid_points1] = extractFeatures(I1, points1,'Method','SIFT');
[features2, valid_points2] = extractFeatures(I2, points2,'Method','SIFT');

%对描述子集合进行匹配，匹配的特征的索引返回在了indexPairs中

% matchFeatures用于特征点匹配
% Metric'：用于比较特征的度量。在这里，您选择了 'SAD'，这代表 "Sum of Absolute Differences"。
indexPairs = matchFeatures(features1,features2,'MatchThreshold',10,'Metric','SAD');
%根据匹配的特征索引，找出匹配的特征点集合
matchedPoints1 = valid_points1(indexPairs(:,1),:);
matchedPoints2 = valid_points2(indexPairs(:,2),:);

%把通过描述子匹配建立起来的特征点之间的匹配关系可视化出来
%注意：这里面一般来说会有错误匹配的情况
pp1 = matchedPoints1.Location;
pp2 = matchedPoints2.Location;

[rows1, cols1] = size(I1);
[rows2, cols2] = size(I2);

rows = max([rows1, rows2]);
cols = cols1 + cols2 + 3;
im = zeros(rows, cols,3);

im(1:rows1, 1:cols1,:) = imgColor1;
im(1:rows2, cols1+4:cols,:) = imgColor2;

pp2(:, 1) = pp2(:, 1) + cols1 + 3;

figure;
imshow(uint8(im));
hold on
for index = 1:size(pp1, 1)
    x1 = pp1(index, 1);
    y1 = pp1(index, 2);
    plot(x1, y1, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    x2 = pp2(index, 1);
    y2 = pp2(index, 2);
    plot(x2, y2, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    line([x1, x2], [y1, y2], 'Color', 'y');
end

%接下来，根据对应点对关系，在RANSAC框架之下，估计两张图像之间的射影变换矩阵H
pp1 = matchedPoints1.Location;
pp2 = matchedPoints2.Location;
%把二维平面坐标转换成三维的齐次坐标表示，pp1Homo和pp2Homo中都是每列为一个坐标点
pp1Homo = [(pp1(:,1))'; (pp1(:,2))'; ones(1,size(pp1,1))];
pp2Homo = [(pp2(:,1))'; (pp2(:,2))'; ones(1,size(pp2,1))];

t = 2.0;  %RANSAC框架中由于内点判定的阈值，点带入模型之后，误差大于t，则认为是外点
[H, inliers] = ransacfithomography(pp1Homo, pp2Homo, t);

inliers1 = pp1(inliers',:);
inliers2 = pp2(inliers',:);
[rows1, cols1] = size(I1);
[rows2, cols2] = size(I2);

rows = max([rows1, rows2]);
cols = cols1 + cols2 + 3;
im = zeros(rows, cols,3);

im(1:rows1, 1:cols1,:) = imgColor1;
im(1:rows2, cols1+4:cols,:) = imgColor2;

inliers2(:, 1) = inliers2(:, 1) + cols1 + 3;

figure;
imshow(uint8(im));
hold on
for index = 1:size(inliers1, 1)
    x1 = inliers1(index, 1);
    y1 = inliers1(index, 2);
    plot(x1, y1, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    x2 = inliers2(index, 1);
    y2 = inliers2(index, 2);
    plot(x2, y2, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerSize', 5);
    line([x1, x2], [y1, y2], 'Color', 'y');
end
hold off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Apply H to image%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 将I1变换到I2的坐标系下
% 1. 初始化空白图像尺寸
% 2. 变换I1的四个角
% 3. 初始化结果图像
% 4. 对I1进行逆变换和双线性插值获得颜色值
% 5. 把I2放入正确的位置
% 6. 显示结果
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InverseOfH = inv(H); %我们把img1变换到img2所在的坐标系之下
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%坐标的解释%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [rowsIm1, colsIm1] 和 [rowsIm2, colsIm2]：两个输入图像I1和I2的行数和列数。
% finalLeft, finalRight, finalTop, finalBot：拼接后图像的边界。
%    这四个边界的初值是图像I2的大小。随后根据I1经过变换后的四个角的坐标来更新这些边界
% mergeRows 和 mergeCols：拼接后的图像的总行数和总列数
%    由finalBot - finalTop + 1和finalRight - finalLeft + 1计算得出的。
% currentCoord：当前遍历到的拼接图像的点的齐次坐标
%    CoordInOriImage为其对应齐次坐标
% xInSrcImage 和 yInSrcImage：在原始图像I1中的非整数坐标
% y1, x1, y2, x2：围绕(xInSrcImage, yInSrcImage)的四个最近的整数像素坐标。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%首先要准备好能装载拼接图像的空白图像
[rowsIm1, colsIm1] = size(I1);
[rowsIm2, colsIm2] = size(I2);
finalLeft = 1;
finalRight = colsIm2;
finalTop = 1;
finalBot = rowsIm2;

% (wwd) 变换I1的四个角[笛卡尔->齐次->应用H->笛卡尔]
leftTopCornerCoord = H * [1;1;1];
leftTopCornerCoord = leftTopCornerCoord / leftTopCornerCoord(3,1);
if leftTopCornerCoord(1) < finalLeft
    finalLeft = floor(leftTopCornerCoord(1));
end
if leftTopCornerCoord(2) < finalTop
    finalTop = floor(leftTopCornerCoord(2));
end

RightTopCornerCoord = H * [colsIm1;1;1];
RightTopCornerCoord = RightTopCornerCoord / RightTopCornerCoord(3,1);
if RightTopCornerCoord(1) > finalRight
    finalRight = floor(RightTopCornerCoord(1));
end
if RightTopCornerCoord(2) < finalTop
    finalTop = floor(RightTopCornerCoord(2));
end

leftBotCornerCoord = H * [1;rowsIm1;1];
leftBotCornerCoord = leftBotCornerCoord / leftBotCornerCoord(3,1);
if leftBotCornerCoord(1) < finalLeft
    finalLeft = floor(leftBotCornerCoord(1));
end
if leftBotCornerCoord(2) > finalBot
    finalBot = floor(leftBotCornerCoord(2));
end

RightBotCornerCoord = H * [colsIm1;rowsIm1;1];
RightBotCornerCoord = RightBotCornerCoord / RightBotCornerCoord(3,1);
if RightBotCornerCoord(1) > finalRight
    finalRight = floor(RightBotCornerCoord(1));
end
if RightBotCornerCoord(2) > finalBot
    finalBot = floor(RightBotCornerCoord(2));
end

mergeRows = finalBot - finalTop + 1;
mergeCols = finalRight - finalLeft + 1;
transformedImage = single(zeros(mergeRows, mergeCols,3));
for row = 1:mergeRows
    for col = 1: mergeCols
        % 对当前的row和col坐标进行齐次坐标变换，以确定它在imgColor1中对应的位置。
        currentCoord = [col+finalLeft-1;row+finalTop-1;1];
        CoordInOriImage = InverseOfH * currentCoord;
        CoordInOriImage = CoordInOriImage / CoordInOriImage(3,1);

        xInSrcImage = CoordInOriImage(1,1);
        yInSrcImage = CoordInOriImage(2,1);

        y1 = floor(yInSrcImage);
        x1 = floor(xInSrcImage);
        y2 = ceil(yInSrcImage);
        x2 = ceil(xInSrcImage);

        if (x1 >= 1 && y1 >=1 && x2 <= colsIm1 && y2 <= rowsIm1)
            % 红
            f1 = imgColor1(y1,x1,1);
            f2 = imgColor1(y1,x2,1);
            f3 = imgColor1(y2,x1,1);
            f4 = imgColor1(y2,x2,1);
            
            % (wwd)双线性插值
            % 考虑图像中的一个像素点，该点并不正好位于整数像素坐标上。我们想要估计这个点的像素值。
            % 这时，我们找到这个点周围的四个最近的整数像素坐标。
            % 对其分别加权平均，权重为(xt-x)(yt-y)
            transformedImage(row,col,1) = (y2-yInSrcImage)*(x2-xInSrcImage)*f1 + ...
                (y2-yInSrcImage)*(xInSrcImage-x1)*f2 + ...
                (yInSrcImage-y1)*(x2-xInSrcImage)*f3 + ...
                (yInSrcImage-y1)*(xInSrcImage-x1)*f4;

            % 绿
            f1 = imgColor1(y1,x1,2);
            f2 = imgColor1(y1,x2,2);
            f3 = imgColor1(y2,x1,2);
            f4 = imgColor1(y2,x2,2);
            transformedImage(row,col,2) = (y2-yInSrcImage)*(x2-xInSrcImage)*f1 + ...
                (y2-yInSrcImage)*(xInSrcImage-x1)*f2 + ...
                (yInSrcImage-y1)*(x2-xInSrcImage)*f3 + ...
                (yInSrcImage-y1)*(xInSrcImage-x1)*f4;

            % 蓝
            f1 = imgColor1(y1,x1,3);
            f2 = imgColor1(y1,x2,3);
            f3 = imgColor1(y2,x1,3);
            f4 = imgColor1(y2,x2,3);
            transformedImage(row,col,3) = (y2-yInSrcImage)*(x2-xInSrcImage)*f1 + ...
                (y2-yInSrcImage)*(xInSrcImage-x1)*f2 + ...
                (yInSrcImage-y1)*(x2-xInSrcImage)*f3 + ...
                (yInSrcImage-y1)*(xInSrcImage-x1)*f4;
        end
    end
end

transformedImage(-finalTop + 2 : -finalTop + 1 + rowsIm2, -finalLeft + 2 : -finalLeft + 1 + colsIm2,:) = imgColor2;
figure;
imshow(uint8(transformedImage),[]);
