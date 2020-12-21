function CODEXobj = get_nuclei_mask(CODEXobj)

CODEXobj.cells = [];

disp(' ')
disp('processing nuclei mask ...')


%%
if(exist(['./outputs/3_Segmentation/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_1_DAPi1_1.tif'],'file')==2)
    movefile(['./outputs/3_Segmentation/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_1_DAPi1_1.tif'],...
        ['./outputs/3_Segmentation/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_2_stardist.tif']);
end

nuclei_mask = imread(['./outputs/3_Segmentation/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_2_stardist.tif']);
%figure('Position',[1 41 1920 963],'Color','w'),imagesc(nuclei_mask),axis tight equal; colorbar;

tissue_mask = imread(['./outputs/3_Segmentation/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_1_tissue.tif'],'tif');
%figure('Position',[1 41 1920 963],'Color','w'),imagesc(tissue_mask),axis tight equal; colorbar;



%%
if(size(nuclei_mask,3)==1)
    
    nuclei_mask = imresize(nuclei_mask,size(tissue_mask),'nearest').*uint16(tissue_mask);
    
    bw = imdilate(nuclei_mask,strel('disk',1)) - nuclei_mask;
    bw = bw>0;
    %figure('Position',[1 41 1920 963],'Color','w'),imagesc(bw),axis tight equal; colorbar;
    
    nuclei_mask = nuclei_mask>0;
    nuclei_mask(bw>0) = 0;
    nuclei_mask = bwareaopen(nuclei_mask,10,4);
    
    L = bwlabel(nuclei_mask,4);
    
    E = imdilate(L,strel('disk',1)) - L;
    E = E>0;
    
elseif(size(nuclei_mask,3)==3)
    
    nuclei_mask = convert_RGB_code_to_labels(nuclei_mask);
    
    nuclei_mask = imresize(nuclei_mask,size(tissue_mask),'nearest').*double(tissue_mask);
    
    bw = imdilate(nuclei_mask,strel('disk',1)) - nuclei_mask;
    bw = bw>0;
    %figure('Position',[1 41 1920 963],'Color','w'),imagesc(bw),axis tight equal; colorbar;
    
    nuclei_mask = nuclei_mask>0;
    nuclei_mask(bw>0) = 0;
    nuclei_mask = bwareaopen(nuclei_mask,20,4);
    
    L = bwlabel(nuclei_mask,4);
    
    E = imdilate(L,strel('disk',1)) - L;
    E = E>0;
    
end



%%
stats = regionprops(L,'Area','Centroid');
cell_area = cat(1,stats.Area);
cell_centroid = round(cat(1,stats.Centroid));
cell_ID = cellfun(@(x) ['cell_',x],strrep(cellstr(num2str((1:max(L(:)))')),' ',''),'UniformOutput',false);

CODEXobj.cells = [table(cell_ID) table(cell_centroid(:,1),'VariableNames',{'X'}) ...
    table(cell_centroid(:,2),'VariableNames',{'Y'}) ...
    table(cell_area(:,1),'VariableNames',{'Size'})];


CODEXobj.nuclei_mask = L;
CODEXobj.nuclei_boundary = E;





end















function nuclei_mask = convert_RGB_code_to_labels(nuclei_mask)

%nuclei_mask = rgb2gray(nuclei_mask);

bg = (nuclei_mask(:,:,1)==0)&(nuclei_mask(:,:,2)==0)&(nuclei_mask(:,:,3)==0);

[n,p,~] = size(nuclei_mask);
nuclei_mask = reshape(nuclei_mask,[n*p 3]);
[~,~,nuclei_mask] = unique(double(nuclei_mask),'rows');
nuclei_mask = reshape(nuclei_mask,[n p 1]);

nuclei_mask(bg) = 0;

end











