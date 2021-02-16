function CODEXobj = process_CODEX_images(CODEXobj,BG_subtract,correct_shading)

scan_raw_data(CODEXobj)

for ch = 1:CODEXobj.Nch
    for cl = [1 CODEXobj.Ncl 2:CODEXobj.Ncl-1]
        imgout = ['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];
%         if(exist(imgout, 'file')==2)
%             disp(['found output for ',num2str(ch),' ',num2str(cl)])
% %             if(ch>1)
% %                 if(cl==1)
% %                     disp(['Reading image for ch=',num2str(ch),' cl=',num2str(cl),' (BG1)'])
% %                     I = imread(imgout);
% %                     BG1{ch} = I;
% %                 elseif(cl==CODEXobj.Ncl)
% %                     disp(['Reading image for ch=',num2str(ch),' cl=',num2str(cl),' (BG2)'])
% %                     BG2{ch} = I;
% %                 end
% %             end
%             continue
%         end
        

        %% 1 - EDOF

        I = apply_EDOF(CODEXobj,cl,ch,'GPU');

        
        %% 2 - Shading Correction
        r=1;
        if(correct_shading)
            [CODEXobj, I] = shading_correction_v2(CODEXobj,I,r,cl,ch,true);
        end
        
%         shading_imgout = ['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/shading_correction/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];
%         mkdir(['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/shading_correction'])
%         imwrite(I,shading_imgout,'tif')

        %% 2.1 - Correct corner distortion
        
%         I = correct_Leica_corners(CODEXobj,I,r,cl,ch);
        
        
        %% 2.2 - Cycle Alignment

        if(ch==1&&cl==1)
            Iref=I;
        else
            [CODEXobj,I] = cycle_alignment_v3(CODEXobj,I,Iref,r,cl,ch);
%             shading_imgout = ['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/cycle_alignment/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];
%             mkdir(['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/cycle_alignment'])
%             imwrite(I,shading_imgout,'tif')
        end


        %% 3 - Background Subtraction
%         mkdir(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/bg_tmp'])
%         bgimg = ['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/bg_tmp/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];

        if(ch>1)
            if(cl==1)
                BG1{ch} = I;
            elseif(cl==CODEXobj.Ncl)
                BG2{ch} = I;
            else
                [CODEXobj,I] = background_subtraction_v6(CODEXobj,I,BG1,BG2,r,cl,ch);
%                 [CODEXobj,I] = background_subtraction_v5(CODEXobj,I,BG1,BG2,r,cl,ch,'GPU');
%                 bg_imgout = ['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/background_subtraction/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];
%                 mkdir(['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/background_subtraction'])
%                 imwrite(I,bg_imgout,'tif')
            end
        end

        
        %% 4 - Stitching
        
        [CODEXobj,I] = stitching_v2(CODEXobj,I,r,cl,ch,false,false);
%         stitched_imgout = ['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/stitching/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'];
%         mkdir(['./data/0_debug/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/stitching'])
%         imwrite(I,stitched_imgout,'tif')
        
        
        %% 6 - Deconvolution
        
        
        %% 7 - save processed image
        mkdir(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images'])
        
        if(~exist(imgout, 'file'))
            imwrite(I,imgout,'tif')
        end
        matf = ['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/CODEXobj_',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'.mat'];
        save(matf, 'CODEXobj', '-v7.3')
      
        
    end
end





% %% clear Background images from CODEXobj and save it
% %% keep these for re-running purposes
% CODEXobj = rmfield(CODEXobj,'BG1');
% CODEXobj = rmfield(CODEXobj,'BG2');
% save(['./data/1_processed/',CODEXobj.sample_id,'/CODEXobj_',CODEXobj.sample_id,'.mat'],'CODEXobj')
        






end






















