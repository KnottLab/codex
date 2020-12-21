function [Ia,Io] = overlay_markers(I,mrk,marker_list,MrkColor)



% MrkColor = [1 0 0;0 1 0;0 0 1];
% marker_list = {'PanCytoK','CD45','DAPI'};


[~,ia,ib] = intersect(upper(mrk(:,1)),upper(marker_list),'stable');


Ia = zeros(size(I{1},1),size(I{1},2),3,'uint8');
l = 1;
for k = ia'
    cmax{k} = double(quantile(I{k}(:),0.9));
    Ia(:,:,1) = Ia(:,:,1) + uint8(255*MrkColor(ib(l),1)*double(I{k})/cmax{k});
    Ia(:,:,2) = Ia(:,:,2) + uint8(255*MrkColor(ib(l),2)*double(I{k})/cmax{k});
    Ia(:,:,3) = Ia(:,:,3) + uint8(255*MrkColor(ib(l),3)*double(I{k})/cmax{k});
    l = l+1;
end
imagescBBC(Ia)
l = 1;
for k = ia'
    annotation('rectangle',[.01 .9-l*0.03 0.01 0.02],'Color',MrkColor(ib(l),:),'FaceColor',MrkColor(ib(l),:),'FaceAlpha',1)
    annotation('textbox',[.02 .907-l*0.03 0.01 0.02],'String',mrk{k,1},'FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
    l = l+1;
end
axis tight

Io = Ia;
Ia = getframe(gcf);
Ia = Ia.cdata;




end