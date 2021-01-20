clc
close all force
clear all
addpath(genpath([pwd,'\functions']));
addpath(genpath('E:\Imaging_tools'));


D = get_CODEX_dataset_info(); disp(D)


for i = 31
    
    load(['./data/1_processed/',D.sampleID{i},'_reg',num2str(D.region(i)),'/CODEXobj_',D.sampleID{i},'_reg',num2str(D.region(i)),'.mat'],'CODEXobj'); disp(CODEXobj)
    
    
    %% Load all processed images
    %[I,CODEXobj] = load_CODEX_images(CODEXobj,'All','1_processed');
    %[I,CODEXobj] = load_CODEX_images(CODEXobj,{'DAPI','CD8','PD-1'},'1_processed');
    [I,CODEXobj] = load_CODEX_images(CODEXobj,'CODEX','1_processed');
    
    
    %% Display Multiplex
    display_multiplex(I,CODEXobj.antibody)
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% Get Tissue Mask
    tissue_mask = get_tissue_mask(CODEXobj);
    
    mkdir(['./outputs/3_Segmentation/',CODEXobj.sample_id])
    imwrite(tissue_mask,['./outputs/3_Segmentation/',CODEXobj.sample_id,'_reg',CODEXobj.region,'/',CODEXobj.sample_id,'_reg',CODEXobj.region,'_1_tissue.tif'],'tif')
    
    
    %% Get Nuclei Mask CODEX
    CODEXobj = get_nuclei_mask(CODEXobj);
    
    
    %% Get Membrane Mask CODEX
    CODEXobj = get_membrane_mask(CODEXobj);
    
    
    %% Display Nuclei Segmentation CODEX
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells)
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% save nuclei segmentation data CODEX
    mkdir(['./outputs/3_Segmentation/',CODEXobj.sample_id,'_reg',CODEXobj.region])
    save(['./outputs/3_Segmentation/',CODEXobj.sample_id,'_reg',CODEXobj.region,'/',CODEXobj.sample_id,'_reg',CODEXobj.region,'_CODEXobj.mat'],'CODEXobj','-v7.3'); disp(CODEXobj)
    
    return
    % %% Load H&E image
    % I3 = imread(['./data/0_HandE/',D.sampleID{i},'/',D.sampleID{i},'_HandE.tif'],'tif');
    
    
    % %% Display Multiplex and H&E
    % display_multiplex(I,I3,CODEXobj.antibody,[],[],[])
    % axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    % %% Get Nuclei Mask H&E
    % [L3,E3,T3] = get_nuclei_mask_HE(D.sampleID{i},I3);
    
    
    % %% Display Nuclei Segmentation H&E
    % display_multiplex(I,I3,mrk,E3,T3,[])
    % %axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    

    % %% save nuclei segmentation data CODEX
    % mkdir('./outputs/3_Segmentation/2_nuclei/2_Final')
    % save(['./outputs/3_Segmentation/2_nuclei/2_Final/',D.sampleID{i},'_HE.mat'],'L3','E3','T3','-v7.3');
    
    
    
    
    
    
    
end








