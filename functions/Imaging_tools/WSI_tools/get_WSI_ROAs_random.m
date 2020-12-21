function R = get_WSI_ROAs_random(file_name,tissue_mask,size_of_ROA,nbr_of_ROA)


I = imread(file_name,'Index',2);
% disp(['Image Size: ',num2str(size(I,1)),' x ',num2str(size(I,2))])
% imagescBBC(I)

info = imfinfo(file_name);
cx = info(1).Height/info(2).Height;
cy = info(1).Width/info(2).Width;

sz = size_of_ROA/cx;

% imagescBBC(tissue_mask)
tissue_mask = imerode(tissue_mask,strel('disk',round(sz)));


R = [];
for r = 1:nbr_of_ROA

    [X,Y] = find(tissue_mask==1);
    P = randi(length(X),1,1);
    P = [X(P) Y(P)];

    dx = P(1)-sz/2:P(1)+sz/2;
    dy = P(2)-sz/2:P(2)+sz/2;

    tissue_mask(round(P(1)-sz:P(1)+sz),round(P(2)-sz:P(2)+sz)) = 0;
    
    R = [R; [min(round(cx*dx)) min(round(cx*dx))+size_of_ROA-1 min(round(cy*dy)) min(round(cy*dy))+size_of_ROA-1]];
    
    if(sum(tissue_mask)==0)
        break;
    end
      
end
R = array2table(R,'VariableNames',{'x_start','x_end','y_start','y_end'});





figure('Position',[14 570 560 420]),imagesc(I),axis tight equal
for r = 1:size(R,1)

    x1 = R.x_start(r)/cx;
    x2 = R.x_end(r)/cx;
    
    y1 = R.y_start(r)/cy;
    y2 = R.y_end(r)/cy;
    
    hold on,rectangle('Position',[y1 x1 y2-y1 x2-x1],'EdgeColor',[1 0 0])
    
end
title(strrep(file_name,'_',' '))



end







