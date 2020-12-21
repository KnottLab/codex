function [I,Dust] = remove_dust_v2(I,mrk)
% close all

Dust = false(size(I{1}));
for k = 1:length(mrk)
    
    disp(['finding dust spots: ',mrk{k,1},' ...'])
    
    %Ia = I{k};
    %figure('Position',[1 41 1920 963]),imagesc(Ia);sliderSin_BBC(0,65535)
    
    %bw = I{k}*20*mad(I{k}(:))>median(I{k}(:));
    
%     bw = I{k}>min(I{k}(isoutlier(double(I{k}(:)))));
%     bw = reshape(isoutlier(double(I{k}(:))),size(I{k}));
    bw = reshape(isoutlier(double(I{k}(:)),'mean','ThresholdFactor',50),size(I{k}));
    %figure('Position',[1 41 1920 963]),imagesc(bw)
    
    %bw = imdilate(bw,strel('disk',20));
    %figure('Position',[1 41 1920 963]),imagesc(bw)
    
    %cmax{k} = double(quantile(I{k}(:),0.999));
    %Ia = ind2rgb(I{k},parula(round(cmax{k})+1));
    %Ia = labeloverlay(Ia,imdilate(bw,strel('disk',5))-bw,'Colormap',[1 0 0],'Transparency',0);
    %figure('Position',[1 41 1920 963]),imagesc(Ia)
    
    Dust = Dust|bw;
    
end
Dust = imdilate(Dust,strel('disk',30));
Dust = imclose(Dust,strel('disk',10));



% [~,n] = bwlabel(Dust);
% disp([num2str(n),' dust spots were found'])
% disp(' ')



for k = 1:length(mrk)
    disp(['removing dust spots: ',mrk{k,1},' ...'])
    I{k}(Dust) = mean(I{k}(:));
end





end