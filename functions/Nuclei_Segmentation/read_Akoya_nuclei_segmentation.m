function cell_mask = read_Akoya_nuclei_segmentation(CODEXobj)


image_folder = strrep(cellstr(ls([CODEXobj.data_path,'/',CODEXobj.sample_id,'/*'])),' ','');
image_folder = image_folder{startsWith(image_folder,'processed')};


cell_mask = [];
for x = 1:CODEXobj.Nx
    mask2 = [];
    for y = 1:CODEXobj.Ny
        mask1 = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/',image_folder,'/',...
            '/segm/segm-1/masks/reg00',num2str(CODEXobj.roi),'_X0',num2str(y),'_Y0',num2str(x),'/regions_reg00',num2str(CODEXobj.roi),'_X0',num2str(y),'_Y0',num2str(x),'_Z01.png']);
        mask2 = [mask2 mask1];
    end
    cell_mask = [cell_mask ; mask2];
end
clear mask1 mask2
cell_mask = rgb2gray(cell_mask)==0;

cell_mask = ~cell_mask;


end