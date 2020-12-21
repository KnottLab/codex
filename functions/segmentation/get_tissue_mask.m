function tissue_mask = get_tissue_mask(CODEXobj)

disp(' ')
disp('generating tissue mask ...')

    

ch = 1;
if(strcmp(CODEXobj.sample_id,'200804_HumanFFPE_BreastTumor_50x_HIER_Raw_200729'))
    cl = 7;
else
    cl = 1;
end

I = read_CODEX_image(CODEXobj,'1_processed',cl,ch);
% figure,imagesc(I)

tissue_mask = imbinarize(I);
% figure,imagesc(tissue_mask)

tissue_mask = imclose(tissue_mask,strel('disk',80));
tissue_mask = imfill(tissue_mask,'holes');
tissue_mask = imopen(tissue_mask,strel('disk',20));
% figure,imagesc(tissue_mask)


L = bwlabel(tissue_mask,4);
stats = regionprops(L,'Area');
area = cat(1,stats.Area);
[~,pm] = max(area);

tissue_mask = L==pm;



end










function It = read_CODEX_image(CODEXobj,load_folder,cl,ch)

if(strcmp(CODEXobj.processor,'Matlab_CODEX'))
    
    It = imread(['./data/',load_folder,'/',CODEXobj.sample_id,'/images/',CODEXobj.sample_id,'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'],'tif');
    
elseif(strcmp(CODEXobj.processor,'Akoya_Proc'))
    image_folder = strrep(cellstr(ls([CODEXobj.data_path,'/',CODEXobj.sample_id,'/*'])),' ','');
    image_folder = image_folder{startsWith(image_folder,'processed')};
        
    It = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/',image_folder,'/',...
                '/stitched/reg',num2str2(CODEXobj.roi),'/reg',num2str2(CODEXobj.roi),'_cyc',num2str2(cl),'_ch',num2str2(ch),'_',CODEXobj.markers2{cl,ch},'.tif']);
            
end

end









