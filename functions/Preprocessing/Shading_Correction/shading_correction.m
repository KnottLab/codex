function I = shading_correction(CODEXobj,I,cl,ch)


% if(ch>1&&cl>1&&cl<CODEXobj.Ncl)
if(ch>1)

    disp('shading correction ... ')
    tic
    
    %% Concatenation
    IF = [];
    for x = 1:CODEXobj.RNx
        for y = 1:CODEXobj.RNy
            dx = 1+(x-1)*CODEXobj.Height:x*CODEXobj.Height;
            dy = 1+(y-1)*CODEXobj.Width:y*CODEXobj.Width;
            IF = cat(3,IF,I(dx,dy));
        end
    end
    
    
    
    %% estimate flatfield and darkfield
    % For fluorescence images, darkfield estimation is often necessary (set 'darkfield' to be true)
    [flatfield,darkfield] = BaSiC(IF,'darkfield','true');
    
    
    
    %% image correction
    for x = 1:CODEXobj.RNx
        for y = 1:CODEXobj.RNy
            dx = 1+(x-1)*CODEXobj.Height:x*CODEXobj.Height;
            dy = 1+(y-1)*CODEXobj.Width:y*CODEXobj.Width;
            I(dx,dy) = uint16((double(I(dx,dy))-darkfield)./flatfield);
        end
    end
    
    
    
    %% plot estimated shading files
    % note here darkfield does not only include the contribution of microscope offset, 
    % but also scattering light that entering to the light path, which adds to every image tile
    
    hf = figure('Position',[510 330 725 645],'Color','w');
    subplot(121); imagesc(flatfield);colorbar;title([strrep(CODEXobj.markers2{cl,ch},'_',' | '),'  | Estimated flatfield']);axis tight equal
    subplot(122); imagesc(darkfield);colorbar;title([strrep(CODEXobj.markers2{cl,ch},'_',' | '),'  | Estimated darkfield']);axis tight equal
    set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
    
    mkdir(['./figures/1_processing/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/2_shading_correction'])
    saveas(hf,['./figures/1_processing/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/2_shading_correction/',CODEXobj.markers2{cl,ch},'_shading_correction.png'],'png')
    
    delete(hf)
    
    toc
    
    
    
end




end




