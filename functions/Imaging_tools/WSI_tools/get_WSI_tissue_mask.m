function tissue_mask = get_WSI_tissue_mask(file_name)


I = imread(file_name,'Index',2);
% disp(['Image Size: ',num2str(size(I,1)),' x ',num2str(size(I,2))])
% figure,imagesc(I),axis tight equal

info = imfinfo(file_name);
cx = info(1).Height/info(2).Height;
cy = info(1).Width/info(2).Width;


%%
tissue_mask = rgb2gray(I);
% figure,imagesc(tissue_mask),axis tight equal

tissue_mask = ~imbinarize(tissue_mask);
% figure,imagesc(tissue_mask),axis tight equal

tissue_mask = imclose(tissue_mask,strel('disk',5));
tissue_mask = imfill(tissue_mask,'holes');
tissue_mask = imopen(tissue_mask,strel('disk',2));
% figure,imagesc(tissue_mask),axis tight equal

tissue_mask = bwareaopen(tissue_mask,500);
% figure,imagesc(tissue_mask),axis tight equal


end


