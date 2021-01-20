function CODEXobj = process_CODEX_images(CODEXobj,BG_subtract,correct_shading)


for ch = 1:CODEXobj.Nch
    for cl = [1 CODEXobj.Ncl 2:CODEXobj.Ncl-1]
        
%         if(exist(['./data/1_processed/',CODEXobj.sample_id,'/images/',CODEXobj.sample_id,'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'], 'file')==2)
%             disp(['found output for ',num2str(ch),' ',num2str(cl)])
%             continue
%         end

        %% 0 - Raw image
        
        % z = round(CODEXobj.Nz/2);
        % I = read_image_at_Z(CODEXobj,cl,ch,z);
        % imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        % axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
        
        
        %% 1 - EDOF
        
        I = apply_EDOF(CODEXobj,cl,ch,'GPU');
        
        %imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        %axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
%         imwrite(I,['./intermediate_output/',CODEXobj.sample_id,'/01_preprocess_EDOF.tif'],'tif')

        %% 2 - Shading Correction
        
        if(correct_shading)
            I = shading_correction(CODEXobj,I,cl,ch);
%             imwrite(I,['./intermediate_output/',CODEXobj.sample_id,'/02_preprocess_shading_correction.tif'],'tif')
        end
        
        %imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        %axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
        
        
        %% 3 - Background Subtraction
        
        if(BG_subtract)
            [I,CODEXobj] = background_subtraction_v2(CODEXobj,I,cl,ch,'GPU');
%             imwrite(I,['./intermediate_output/',CODEXobj.sample_id,'/03_preprocess_background_subtraction_v2.tif'],'tif')
        end
        
        %imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        %axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
        

        %% 4 - Stitching
        [I,CODEXobj] = stitch_tiles(I,CODEXobj,cl,ch,false);
        
        % imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        % axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
        

        %% 5 - Cycle Alignment
        [I,CODEXobj] = cycle_alignment(I,CODEXobj,cl,ch);

        % imagescBBC(I),title(strrep([CODEXobj.sample_id,' | ',CODEXobj.markers2{cl,ch}],'_',' ')),colorbar; caxis([0 0.5*65535])
        % axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
        
        
        %% 6 - Deconvolution
        
        
        %% 7 - save processed image
        mkdir(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images'])
        imwrite(I,['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/images/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'],'tif')
        if(ch==1)
            save(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/CODEXobj_',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'.mat'],'CODEXobj')
        end
        
        
        
    end
end





%% clear Background images from CODEXobj and save it
CODEXobj = rmfield(CODEXobj,'BG1');
CODEXobj = rmfield(CODEXobj,'BG2');
save(['./data/1_processed/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/CODEXobj_',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'.mat'],'CODEXobj')
        






end






















