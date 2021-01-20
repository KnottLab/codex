clc
close all force
clear all
addpath(genpath([pwd,'\functions']));
addpath(genpath('D:\Bassem\Imaging_tools'));


D = get_CODEX_dataset_info(); disp(D)


%%
for i = 32
    
    
    %% Create CODEX object
    CODEXobj = create_CODEX_object(D,i); disp(CODEXobj)
    mkdir(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images'])
    save(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/CODEXobj_',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'.mat'],'CODEXobj')
    
    
    %% Process CODEX images
    CODEXobj = process_CODEX_images(CODEXobj,true,true); disp(CODEXobj)
    
    return   
    %% Processing: H&E
    [I3,HEinfo] = stitching_HandE(data_path,CODEXobj.sample_id); disp(HEinfo)
    %imagescBBC(I3),title(D.sampleNames{i})
    
    
    %% CODEX / H&E Alignment
    I3 = align_HE_to_CODEX(CODEXobj.sample_id,I3,Tinfo,HEinfo,channels);
    
    
    %% Save aligned H&E image
    mkdir(['./data/0_HandE/',CODEXobj.sample_id])
    imwrite(I3,['./data/0_HandE/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_HandE.tif'],'tif')
    
    
end










