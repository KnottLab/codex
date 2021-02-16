function [CODEXobj,I] = shading_correction_v2(CODEXobj,I,r,cl,ch,display)

disp('Shading Correction ... ')
tic

Nx = CODEXobj.RNy;
Ny = CODEXobj.RNx;
W = CODEXobj.Width;
H = W;
CODEXobj.markerNames = CODEXobj.markers2;




%%
if(display==true)
    hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');imagesc(imadjust(I)),axis tight equal
    set(gca,'Position',[0.02 0.02 0.96 0.96]); fr = getframe(hf);
    Ia{1} = fr.cdata; close(hf)
end



%% Create image stack
IF = [];
for x = 1:Nx
    for y = 1:Ny
        if(isempty(CODEXobj.real_tiles{x,y}))
            continue
        end
        dx = 1+(x-1)*H:x*H;
        dy = 1+(y-1)*W:y*W;
        IF = cat(3,IF,I(dx,dy));
    end
end



%% Estimate flatfield and darkfield

% [flatfield,darkfield] = BaSiC(IF,'darkfield','true');

model = cidre(IF);
darkfield = model.z;
flatfield = model.v;



%% Shading Correction
% Jp = I==0;
for x = 1:Nx
    for y = 1:Ny
        if(isempty(CODEXobj.real_tiles{x,y}))
            continue
        end
        dx = 1+(x-1)*H:x*H;
        dy = 1+(y-1)*W:y*W;
        
        % 'intensity range _preserving'
        %I(dx,dy) = uint16(((double(I(dx,dy))-darkfield)./flatfield)*mean(flatfield(:)) + mean(darkfield(:)));
                    
        % 'zero-light_preserving'
        %I(dx,dy) = uint16(((double(I(dx,dy))-darkfield)./flatfield)*mean(flatfield(:)));
        
        % 'direct'    
        I(dx,dy) = uint16((double(I(dx,dy))-darkfield)./flatfield);
               
    end
end
I = I+1;

% I(Jp) = 0;



%%
% if(display==true)
%     
% %     hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');imagesc(imadjust(I)),axis tight equal
% %     set(gca,'Position',[0.02 0.02 0.96 0.96]); fr = getframe(hf);
% %     Ia{2} = fr.cdata; close(hf)
%     
%     hf = figure('Position',[1 41 1920 963],'Color','w','Visible','on');
%     
%     subplot(121)
%     imagesc(flatfield),colorbar,axis tight equal
%     set(findall(gca,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
%     title('Flatfield','FontSize',36),set(gca,'TickDir','out')
%     
%     subplot(122)
%     imagesc(darkfield),colorbar,axis tight equal
%     set(findall(gca,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
%     title('Darkfield','FontSize',36),set(gca,'TickDir','out')
%     
%     annotation('textbox',[.45 .95 0.5 0],'String',[strrep(CODEXobj.markerNames{cl,ch},'_',' '),' (',num2str(cl),',',num2str(ch),')'],...
%         'FontSize',46,'FontWeight','bold','EdgeColor','none','Color','k');
%     %annotation('textbox',[.38 .05 0.5 0],'String','I2 <- ( I1 - Darkfield ) / Flatfield','FontSize',26,'FontWeight','bold','EdgeColor','none','Color','k');
%     
%     fr = getframe(hf);
%     Ia{3} = fr.cdata;
% %     close(hf)
%     
% %     Ia = [imresize([Ia{1} Ia{2}],[round(size(Ia{1},1)*size(Ia{3},2)/(2*size(Ia{1},2))) size(Ia{3},2)]);Ia{3}];
% %     Expr_Info.Proc{r,1}.shading_correction.Ia{cl,ch} = imresize(Ia,0.5);
%     
%     CODEXobj.Proc{r,1}.shading_correction.Ia{cl,ch} = Ia{3};
%     
% end


% Expr_Info.Proc{r,1}.shading_correction.time{cl,ch} = toc;
% Expr_Info.Proc{r,1}.shading_correction.proc_unit{cl,ch} = 'CPU';



% disp(['Shading Correction time: ',num2str(CODEXobj.Proc{r,1}.shading_correction.time{cl,ch}),' seconds'])



end






