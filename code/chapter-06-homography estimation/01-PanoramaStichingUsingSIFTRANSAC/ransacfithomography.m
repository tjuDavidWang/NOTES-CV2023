% 该函数从输入点对关系pp1Homo和pp2Homo中估计出点集之间的射影变换
% pp1Homo和pp2Homo都是3xN的数组，每一列是一对对应平面点齐次坐标

% H，点集之间的摄影矩阵，使得x2 = H*x1.
% inliers，索引，指明pp1Homo和pp2Homo的哪些列是H的一致集

% pp1Homo，pp2Homo都是齐次坐标
% pp1Homo，pp2Homo必须要有相同的列，即相同的点数，且列数要大于4，因为最少需要4个点对才能唯一确定出平面间的射影变换矩阵
function [H, inliers] = ransacfithomography(pp1Homo, pp2Homo, t)    
    s = 4;  %最少需要4个点对能唯一确定两个平面间的射影变换
    
    fittingfn = @homography2d; % 从数据点进行模型估计
    distfn    = @homogdist2d;  % 计算模型中某点误差
    degenfn   = @isdegenerate; % 判断用于模型估计的点是否是合理的
                               % 如果给定的4个点都是共线的，那是不可能确定出射影变换的
    
    % 喂给ransac函数的数据是6xN的格式
    inliers = ransac([pp1Homo; pp2Homo], fittingfn, distfn, degenfn, s, t);
   
    %最后，从最大的一致集中再用最小二乘法拟合出H
    H = homography2d([pp1Homo(:,inliers); pp2Homo(:,inliers)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 计算模型中某点的误差[双向计算]
% 比如x1与x1'对应，那么需要计算||x1'-Hx1||^2+||x1-H^(-1)x1'||^2
% Input
%   H: 射影矩阵。
%   x: 数据集合，6xN的矩阵，其中前三行是x1的齐次坐标，后三行是x2的齐次坐标。
%   t: 误差阈值。
% Return
%   inliers: 与当前射影矩阵H相一致的的内点索引。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function inliers = homogdist2d(H, x, t)
    
    x1 = x(1:3,:);   % Extract x1 and x2 from x
    x2 = x(4:6,:);    
    
    % Calculate, in both directions, the transfered points    
    Hx1    = H*x1;
    % (wwd) 避免计算矩阵的逆，相当于是invHx2 = inv(H) * x2;
    invHx2 = H\x2;
    
    %计算距离之前转换成归一化齐次坐标    
    x1     = hnormalise(x1);
    x2     = hnormalise(x2);     
    Hx1    = hnormalise(Hx1);
    invHx2 = hnormalise(invHx2); 
    
    d2 = sum((x1-invHx2).^2)  + sum((x2-Hx1).^2);
    inliers = find(abs(d2) < t);    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 判断四个点对中是否有三点共线 
% Input
%  x: [6,4],共有8个点，前三行是I1的，后三行是I2的，列表示点
% Return
%   r: true/false
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = isdegenerate(x)

    x1 = x(1:3,:);    % Extract x1 and x2 from x
    x2 = x(4:6,:);    
    
    r = ...
    iscolinear(x1(:,1),x1(:,2),x1(:,3)) | ...
    iscolinear(x1(:,1),x1(:,2),x1(:,4)) | ...
    iscolinear(x1(:,1),x1(:,3),x1(:,4)) | ...
    iscolinear(x1(:,2),x1(:,3),x1(:,4)) | ...
    iscolinear(x2(:,1),x2(:,2),x2(:,3)) | ...
    iscolinear(x2(:,1),x2(:,2),x2(:,4)) | ...
    iscolinear(x2(:,1),x2(:,3),x2(:,4)) | ...
    iscolinear(x2(:,2),x2(:,3),x2(:,4));
    
