function [Ia,Io] = overlay_markers_4blocks(I,mrk,marker_list,MrkColor)



% MrkColor = [1 0 0;0 1 0;0 0 1];
% marker_list = {'PanCytoK','CD45','DAPI'};


[~,ia,ib] = intersect(upper(mrk(:,1)),upper(marker_list),'stable');



%% Whole Slide Image
It = zeros(size(I{1},1),size(I{1},2),3,'uint8');
l = 1;
for k = ia'
    cmax{k} = double(quantile(I{k}(:),0.9));
    It(:,:,1) = It(:,:,1) + uint8(255*MrkColor(ib(l),1)*double(I{k})/cmax{k});
    It(:,:,2) = It(:,:,2) + uint8(255*MrkColor(ib(l),2)*double(I{k})/cmax{k});
    It(:,:,3) = It(:,:,3) + uint8(255*MrkColor(ib(l),3)*double(I{k})/cmax{k});
    l = l+1;
end
imagescBBC(It)
l = 1;
for k = ia'
    annotation('rectangle',[.01 .9-l*0.03 0.01 0.02],'Color',MrkColor(ib(l),:),'FaceColor',MrkColor(ib(l),:),'FaceAlpha',1)
    annotation('textbox',[.02 .907-l*0.03 0.01 0.02],'String',mrk{k,1},'FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
    l = l+1;
end
axis tight

Io = It;
It = getframe(gcf);
Ia{1} = It.cdata;







%% 4 Blocks

Dx = floor(size(I{1},1)/2);
Dy = floor(size(I{1},2)/2);

for x = 1:2
    for y = 1:2
        
        dx = 1+(x-1)*Dx:x*Dx;
        dy = 1+(y-1)*Dy:y*Dy;
        
        It = zeros(Dx,Dy,3,'uint8');
        l = 1;
        for k = ia'
            It(:,:,1) = It(:,:,1) + uint8(255*MrkColor(ib(l),1)*double(I{k}(dx,dy))/cmax{k});
            It(:,:,2) = It(:,:,2) + uint8(255*MrkColor(ib(l),2)*double(I{k}(dx,dy))/cmax{k});
            It(:,:,3) = It(:,:,3) + uint8(255*MrkColor(ib(l),3)*double(I{k}(dx,dy))/cmax{k});
            l = l+1;
        end
        imagescBBC(It)
        l = 1;
        for k = ia'
            annotation('rectangle',[.01 .9-l*0.03 0.01 0.02],'Color',MrkColor(ib(l),:),'FaceColor',MrkColor(ib(l),:),'FaceAlpha',1)
            annotation('textbox',[.02 .907-l*0.03 0.01 0.02],'String',mrk{k,1},'FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
            l = l+1;
        end
        axis tight
        
        It = getframe(gcf);
        Ia{length(Ia)+1} = It.cdata;
        
    end
    
end










end






















