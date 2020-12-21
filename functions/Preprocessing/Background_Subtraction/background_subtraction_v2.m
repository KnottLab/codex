function [I,CODEXobj] = background_subtraction_v2(CODEXobj,I,cl,ch,proc_unit)


if(ch>1)
    
    
    if(cl==1)
        
        CODEXobj.BG1{ch} = I;
        
    elseif(cl==CODEXobj.Ncl)
        
        CODEXobj.BG2{ch} = I;
        
    else
        
        tic
        disp('Background Subtraction ...')
        
        % proc_unit: 'GPU' or 'CPU'
        
        
        
        %% Get Blank images for the same channel
        I = int16(I);
        BG1 = int16(CODEXobj.BG1{ch});
        BG2 = int16(CODEXobj.BG2{ch});
        
        
        %% Align Bachground images with current image
        tform = CODEXobj.cycle_alignment_info{cl}.tform;
        tform.T(3,1:2) = -tform.T(3,1:2);
        BGt = imwarp(BG1,tform,'OutputView',imref2d(size(BG1)));
        BGt(BGt==0) = BG1(BGt==0); % fix border effects
        BG1 = BGt;
        
        tform = CODEXobj.cycle_alignment_info{cl}.tform;
        tform2 = CODEXobj.cycle_alignment_info{CODEXobj.Ncl}.tform;
        tform.T(3,1:2) = tform2.T(3,1:2)-tform.T(3,1:2);
        BGt = imwarp(BG2,tform,'OutputView',imref2d(size(BG2)));
        BGt(BGt==0) = BG2(BGt==0); % fix border effects
        BG2 = BGt;
        
        
        
        %% gpuArray if requested
        if(strcmp(proc_unit,'GPU'))
            I = gpuArray(I);
            BG1 = gpuArray(BG1);
            BG2 = gpuArray(BG2);
        end
        
        
        
        %% Apply median filter
        I = medfilt2(I,[5 5]);
        BG1 = medfilt2(BG1,[5 5]);
        BG2 = medfilt2(BG2,[5 5]);
        
        
        
        %%
        k = 1;
        for x = 1:CODEXobj.Nx
            for y = 1:CODEXobj.Ny
                
                disp(['Background Subtraction:  ',CODEXobj.markers2{cl,ch},'  : CL=',num2str(cl),' CH=',num2str(ch),' X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(CODEXobj.Nx*CODEXobj.Ny))),'%'])
        
                dx = 1+(x-1)*CODEXobj.Height:x*CODEXobj.Height;
                dy = 1+(y-1)*CODEXobj.Width:y*CODEXobj.Width;
                
                Va = 0:0.1:2;
                Vb = 0:0.1:2;
                [~,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
                
                Va = max([(a-0.05) 0]):0.01:(a+0.05);
                Vb = max([(b-0.05) 0]):0.01:(b+0.05);
                [~,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
                
                I(dx,dy) = uint16(I(dx,dy) - a*BG1(dx,dy) - b*BG2(dx,dy));
                
                k = k+1;
            end
        end
        I = gather(I);
        
        
        %%
        hf = figure('Position',[510 330 725 645],'Color','w');imagesc(M),axis tight square
        cb = colorbar; cb.Label.String = 'sum( I - \alpha BG1 - \beta BG2 )';
        set(findall(gcf,'-property','TickDir'),'TickDir','out'),title(strrep(CODEXobj.markers2{cl,ch},'_',' | '))
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        xticklabels(cellstr(num2str(str2double(get(gca,'xticklabels'))/10))),xticks(get(gca,'xtick')+1),xlabel('\beta')
        yticklabels(cellstr(num2str(str2double(get(gca,'yticklabels'))/10))),yticks(get(gca,'ytick')+1),ylabel('\alpha')
        hold on,plot(b*10+1,a*10+1,'r*','markers',20,'linewidth',3)
        
        mkdir(['./figures/1_processing/',CODEXobj.sample_id,'/3_background_subtraction'])
        saveas(hf,['./figures/1_processing/',CODEXobj.sample_id,'/3_background_subtraction/',CODEXobj.markers2{cl,ch},'_background_subtraction.png'],'png')
        
        delete(hf)
        
        
        toc
        
    end
    
    
    
end




%% Concatenate Background Subtraction Figures

if((cl==CODEXobj.Ncl-1)&&ch==CODEXobj.Nch)
    
    Ia = [];
    for ch = 2:CODEXobj.Nch
        Iat = [];
        for cl = 2:CODEXobj.Ncl-1
            It = imread(['./figures/1_processing/',CODEXobj.sample_id,'/3_background_subtraction/',CODEXobj.markers2{cl,ch},'_background_subtraction.png'],'png');
            delete(['./figures/1_processing/',CODEXobj.sample_id,'/3_background_subtraction/',CODEXobj.markers2{cl,ch},'_background_subtraction.png'])
            Iat = [Iat;It];
        end
        Ia = [Ia Iat];
    end
    imwrite(Ia,['./figures/1_processing/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_3_background_subtraction.png'])
    rmdir(['./figures/1_processing/',CODEXobj.sample_id,'/3_background_subtraction/'],'s')
    
end





end











function [M,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit)

M = zeros(length(Va),length(Vb));

if(strcmp(proc_unit,'GPU'))
    Va = gpuArray(Va);
    Vb = gpuArray(Vb);
    M = gpuArray(M);
end

for a = 1:length(Va)
    for b = 1:length(Vb)
        J = I - Va(a)*BG1 - Vb(b)*BG2;
        M(a,b) = sum(abs(J(:)));
    end
end

[a,b] = find(M==min(M(:)));
a = a(1);
b = b(1);

a = Va(a);
b = Vb(b);

end














