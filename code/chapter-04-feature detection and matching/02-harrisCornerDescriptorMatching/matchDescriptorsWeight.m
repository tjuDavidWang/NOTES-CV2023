% 在产生配对的同时返回其配对的权重
function [indexPairs, matchDistances] = matchDescriptorsWeight(descriptors1In, descriptors2In, matchThreshold, maxRatioThreshold)

descriptorNums1 = size(descriptors1In,2);
descriptorNums2 = size(descriptors2In,2);

%初始化好描述子集合比对距离矩阵
scores = zeros(descriptorNums1, descriptorNums2);

%计算描述子之间的SSD距离
for descriptorIndex = 1: descriptorNums1
    currentDescriptor = descriptors1In(:, descriptorIndex);
    tmpDescriptorMat = repmat(currentDescriptor,[1,descriptorNums2]);
    distsCurrentDescriptor2features2 = sum((tmpDescriptorMat - descriptors2In).^2);
    scores(descriptorIndex,:) = distsCurrentDescriptor2features2;
end

%得到每一行的前两个最小值以及它们的索引
[matchMetric, topTwoIndices] = vision.internal.partialSort(scores, 2, 'ascend');

indexPairs = vertcat(uint32(1:size(scores,1)), topTwoIndices(1,:));

inds = matchMetric(1,:) <= matchThreshold;
indexPairs = indexPairs(:, inds);
matchMetric = matchMetric(:, inds);

%匹配无歧义准则
topTwoScores = matchMetric;
zeroInds = topTwoScores(2, :) < cast(1e-6, 'like', topTwoScores);
topTwoScores(:, zeroInds) = 1;
ratios = topTwoScores(1, :) ./ topTwoScores(2, :);
unambiguousIndices = ratios <= maxRatioThreshold;
indexPairs  = indexPairs(:, unambiguousIndices);

%双向确认原则
[~, idx] = min(scores(:,indexPairs(2,:)));
uniqueIndices = idx == indexPairs(1,:);

%保存匹配距离
matchDistances = matchMetric(1, uniqueIndices);

indexPairs  = indexPairs(:, uniqueIndices);
indexPairs = indexPairs';

end
