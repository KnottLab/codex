function [I,Dust] = remove_dust_v3(I,mrk)
% close all


Dust = zeros(size(I{1}));
for k = 2:length(mrk)
    disp(['finding dust spots: ',mrk{k,1},' ...'])
    Dust = Dust+double(I{k});
end
% imagescBBC(Dust),colorbar

Dust = imclose(Dust,strel('disk',30));
Dust = imopen(Dust,strel('disk',5));


% Dust = imreconstruct(reshape(isoutlier(Dust,'median','ThresholdFactor',10),size(Dust)),...
%     reshape(isoutlier(Dust,'median','ThresholdFactor',5),size(Dust)));

Dust = reshape(isoutlier(Dust,'median','ThresholdFactor',10),size(Dust));


Dust = imdilate(Dust,strel('disk',50));
Dust = imclose(Dust,strel('disk',30));


for k = 2:length(mrk)
    disp(['removing dust spots: ',mrk{k,1},' ...'])
    I{k}(Dust) = 0;
end





end




















