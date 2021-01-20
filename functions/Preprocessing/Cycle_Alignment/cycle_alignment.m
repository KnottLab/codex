function [I,CODEXobj] = cycle_alignment(I,CODEXobj,cl,ch)

tic



if(cl>1&&ch==1)
    
    disp('Cycle Alignment ...')
    
    %% Reference Image
    Iref = imread(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_1_',CODEXobj.markers{1},'.tif'],'tif');
    sz_ref = size(Iref);
    

    %% Registration Transform
    tform = imregcorr(imresize(I,0.5),imresize(Iref,0.5),'translation');
    tform.T(3,1:2) = 2*tform.T(3,1:2);
    
    
    %% Alignment
    cr1 = corr2(Iref,I);
    I = imwarp(I,tform,'OutputView',imref2d(sz_ref));
    cr2 = corr2(Iref,I);
    
    
    %%
    cycle_alignment_info.tform = tform;
    cycle_alignment_info.sz_ref = sz_ref;
    cycle_alignment_info.cr1 = cr1;
    cycle_alignment_info.cr2 = cr2;

    CODEXobj.cycle_alignment_info{cl} = cycle_alignment_info;
    
    

elseif(cl>1&&ch>1)
    
    disp('Cycle Alignment ...')

    I = imwarp(I,CODEXobj.cycle_alignment_info{cl}.tform,'OutputView',imref2d(CODEXobj.cycle_alignment_info{cl}.sz_ref));

end



%%
if(ch==1&&sum(cellfun(@isempty,CODEXobj.cycle_alignment_info))==1)
    mkdir(['./figures/1_processing/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),])
    save_cycle_alignment_eval_figure(CODEXobj,['./figures/1_processing/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_5_cycle_alignment.png'])
end




toc
end


















