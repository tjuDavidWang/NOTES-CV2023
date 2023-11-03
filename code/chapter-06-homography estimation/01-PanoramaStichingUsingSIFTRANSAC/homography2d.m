%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 从点对集合中按照最小二乘法估计射影矩阵
% Input
%   data: 数据集合，6xN的矩阵，其中前三行是x1的归一化齐次坐标，后三行是x2的归一化齐次坐标。
% Return
%   H: 3x3的射影矩阵，描述了从x1到x2的2D射影变换，即x2 = H*x1。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function H = homography2d(data)
    points1 = data(1:3,:); %得到点对关系中的第1组点
    points2 = data(4:6,:); %得到点对关系中的第2组点
    Npts = length(points1); % 确定了点对的数量
    A = zeros(2*Npts,9); %初始化系数矩阵
    
    O = [0 0 0];
    %下面这个循环时构造系数矩阵A
    for i = 1:Npts
	    point1i = points1(:,i)';

	    xiprime = points2(1,i); 
        yiprime = points2(2,i); 
        % 经过归一化了，z为1

        A(2*i-1,:) = [point1i   O    -point1i*xiprime];
	    A(2*i  ,:) = [O     point1i  -point1i*yiprime];
    end
    
    %计算与矩阵A'*A最小特征值所对对应的特征向量smallestEigVector
    [smallestEigVector, ~] = eigs(A'*A, 1, 'smallestabs');
    H = reshape(smallestEigVector,3,3)';
    