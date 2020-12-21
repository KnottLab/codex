function R = get_WSI_ROIs(file_name,tissue_mask)


I = imread(file_name,'Index',2);
% disp(['Image Size: ',num2str(size(I,1)),' x ',num2str(size(I,2))])
% figure,imagesc(I),axis tight equal

info = imfinfo(file_name);
cx = info(1).Height/info(2).Height;
cy = info(1).Width/info(2).Width;


%%
L = bwlabel(tissue_mask,4);
stats = regionprops(L,'Area');
area = cat(1,stats.Area);
[~,ps] = sort(area,'descend');

R = [];
figure('Position',[14 570 560 420]),imagesc(I),axis tight equal
for r = ps'
    
    [ix,iy] = find(L==r);
    
    x1 = min(ix);
    x2 = max(ix);
    
    y1 = min(iy);
    y2 = max(iy);
    
    hold on,rectangle('Position',[y1 x1 y2-y1 x2-x1],'EdgeColor',[1 0 0])
    
    R = [R; [round(x1*cx) round(x2*cx) round(y1*cy) round(y2*cy)]];
    
end
title(strrep(file_name,'_',' '))
R = array2table(R,'VariableNames',{'x_start','x_end','y_start','y_end'});


end








