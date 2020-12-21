function [L3,E3,T3] = get_nuclei_mask_HE(sample_id,I3)

disp(' ')
disp('processing nuclei mask ...')

nuclei_mask = imread(['./outputs/3_Segmentation/2_nuclei/1_stardist/',sample_id,'/',sample_id,'_HandE.tif']);
%figure('Position',[1 41 1920 963],'Color','w'),imagesc(nuclei_mask),axis tight equal; colorbar;

if(size(nuclei_mask,3)==1)
    
    nuclei_mask = imresize(nuclei_mask,[size(I3,1) size(I3,2)]);

    bw = imdilate(nuclei_mask,strel('disk',1)) - nuclei_mask;
    bw = bw>0;
    %figure('Position',[1 41 1920 963],'Color','w'),imagesc(bw),axis tight equal; colorbar;
    
    nuclei_mask = nuclei_mask>0;
    nuclei_mask(bw>0) = 0;
    
    L3 = bwlabel(nuclei_mask,4);
    
    E3 = imdilate(L3,strel('disk',1)) - L3;
    E3 = E3>0;
    
elseif(size(nuclei_mask,3)==3)
       
    nuclei_mask = imresize(nuclei_mask,[size(I3,1) size(I3,2)]);
    
    nuclei_mask = rgb2gray(nuclei_mask);
    
    bw = imdilate(nuclei_mask,strel('disk',1)) - nuclei_mask;
    bw = bw>0;
    %figure('Position',[1 41 1920 963],'Color','w'),imagesc(bw),axis tight equal; colorbar;
    
    nuclei_mask = nuclei_mask>0;
    nuclei_mask(bw>0) = 0;
    
    L3 = bwlabel(nuclei_mask,4);
    
    E3 = imdilate(L3,strel('disk',1)) - L3;
    E3 = E3>0; 
    
end
    

stats = regionprops(L3,'Area','Centroid');
cell_area = cat(1,stats.Area);
cell_centroid = round(cat(1,stats.Centroid));
cell_ID = cellfun(@(x) ['cell_',x],strrep(cellstr(num2str((1:max(L3(:)))')),' ',''),'UniformOutput',false);

T3 = [table(cell_ID) table(cell_centroid(:,1),'VariableNames',{'X'}) ...
    table(cell_centroid(:,2),'VariableNames',{'Y'}) ...
    table(cell_area(:,1),'VariableNames',{'Size'})];

end


