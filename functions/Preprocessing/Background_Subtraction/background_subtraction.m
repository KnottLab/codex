function [I,CODEXobj] = background_subtraction(CODEXobj,I,cl,ch,proc_unit)


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
        disp('round 1 ...')
        Va = 0:0.1:2;
        Vb = 0:0.1:2;
        [M,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit);
        
        
        
        %%
        disp('round 2 ...')
        Va = max([(a-0.05) 0]):0.01:(a+0.05);
        Vb = max([(b-0.05) 0]):0.01:(b+0.05);
        [~,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit);
        
        
        
        %%
        I = gather(uint16(I - a*BG1 - b*BG2));
        
        
        
        %%
        hf = figure('Position',[510 330 725 645],'Color','w');imagesc(M),axis tight square
        cb = colorbar; cb.Label.String = 'sum( I - \alpha BG1 - \beta BG2 )';
        set(findall(gcf,'-property','TickDir'),'TickDir','out'),title(strrep(CODEXobj.markers2{cl,ch},'_',' | '))
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        xticklabels(cellstr(num2str(str2double(get(gca,'xticklabels'))/10))),xticks(get(gca,'xtick')+1),xlabel('\beta')
        yticklabels(cellstr(num2str(str2double(get(gca,'yticklabels'))/10))),yticks(get(gca,'ytick')+1),ylabel('\alpha')
        hold on,plot(b*10+1,a*10+1,'r*','markers',20,'linewidth',3)
        
        mkdir(['./figures/1_processed/3_background_subtraction/',CODEXobj.sample_id])
        saveas(hf,['./figures/1_processed/3_background_subtraction/',CODEXobj.sample_id,'/',CODEXobj.markers2{cl,ch},'.png'],'png')
        
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
            It = imread(['./figures/1_processed/3_background_subtraction/',CODEXobj.sample_id,'/',CODEXobj.markers2{cl,ch},'.png'],'png');
            delete(['./figures/1_processed/3_background_subtraction/',CODEXobj.sample_id,'/',CODEXobj.markers2{cl,ch},'.png'])
            Iat = [Iat;It];
        end
        Ia = [Ia Iat];
    end
    imwrite(Ia,['./figures/1_processed/3_background_subtraction/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_BG_subtract.png'])
    
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

a = Va(a);
b = Vb(b);

end














