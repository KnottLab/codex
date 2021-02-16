function [CODEXobj,J] = stitching_v2(CODEXobj,I,r,cl,ch,QC,display)

disp('Stitching ... ')
tic

if(ch==1&&cl==1)
    new_tf = true;
    SI = calculate_all_pairwise_registrations_v2(CODEXobj,I,r);
else
    new_tf = false;
    SI = CODEXobj.Proc{r,1}.stitching.SI{1,1};
    %SI = rmfield(SI,'Ic');
end


% if(display==1)
%     QC = 1;
%     Ia = {};
% end




% %% Display overlap correlations
% if(new_tf&&QC==1)
%     Ic = display_overlap_correlations_v2(CODEXobj,SI,r);
% else
%     Ic = [];
% end



%% %%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[J,M,mask,V,C3] = stitch_first_tile_v2(CODEXobj,r,I,SI,new_tf);

if(new_tf)
    SI.tile1 = [];
    SI.tile2 = [];
    SI.V = V;
end



%% %%%%%%%%%%%%%%%%%%%%%%%%   Stitching   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
k = 1;
real_tiles = ~cellfun(@isempty, CODEXobj.real_tiles);
while(sum(mask(:))<sum(real_tiles(:)))
    
    disp(['Stitching:  reg',num2strn(r,3),'  :  CL=',num2str(cl),' CH=',num2str(ch),' : ',num2str(round(100*(numel(mask)-sum(mask(:)==0))/numel(mask))),'%  : ',CODEXobj.markerNames{cl,ch}])
    
    if(new_tf==true)
        
        [x1,y1,x2,y2,reg_info] = get_pair_tiles_v2(SI,mask);
        
        SI.tile1 = [SI.tile1;[x1 y1]];
        SI.tile2 = [SI.tile2;[x2 y2]];
        SI.V{x2,y2} = round(reg_info.tf.T(3,1:2)) + SI.V{x1,y1};
        
    end
    
    [J,M,I1,I2,I2r,mask] = stitch_new_tile_v2(CODEXobj,r,I,J,M,SI,k,mask);
    
    
%     if(QC==1)
%         [C3,Ic] = get_new_overlap_correlations(CODEXobj,r,SI,I1,I2r,SI.tile2(k,1),SI.tile2(k,2),C3,Ic);
%     end
    
%     if(display==1)
%         Ia{length(Ia)+1} = display_stitching_steps_v2(CODEXobj,J,M,I1,I2,I2r,SI,k,reg_info,r,C3,mask);
%     end
    
    k = k+1;
    
end



%% Smooth stitches
% M = (imdilate(M,strel('disk',1))-M)>0;
% M = imdilate(M,strel('disk',1));
% 
% Jf = imfilter(J,fspecial('average',3));
% J(M>0) = Jf(M>0);



%%
% if(ch==1&&cl==1)
%     mkdir(['./figures/1_processing/',CODEXobj.sample_id])
%     save_registration_eval_figure(SI,['./figures/1_processing/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_4_Stitching_cycle_',num2str(cl),'.png'])
% end



%%
% if(QC==1)
%     SI.Ic = Ic;
% end

CODEXobj.Proc{r,1}.stitching.SI{cl,ch} = SI;
CODEXobj.Proc{r,1}.stitching.time{cl,ch} = toc;



%%
% if(display==1)
%     imageStruct2GIF(Ia,'./stitching_process.gif',0.3)
% end




disp(['Stitching time: ',num2str(toc),' seconds'])








end






