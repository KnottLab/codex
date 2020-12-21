function display_clusters_spatial(F,E,CL)


[us,~,zs] = unique(CL);
% clr = cbrewer('qual','Set1',max(zs),'linear'); clr = clr(1:max(zs),:);
clr = get_celltype_color(us);


hf = figure('color','w','position',[1 41 1920 963]);
Ia = 255*ones(size(E,1),size(E,2),3,'uint8');
imagesc(Ia),hold on,set(gca,'TickDir','out'),axis tight equal; hold on,

hp = {}; 
for z = 1:length(us)
    hold on,hp{z} = plot(0,0,'Marker','o','MarkerSize',7,'MarkerFaceColor',clr(z,:),'MarkerEdgecolor',[.2 .2 .2],'LineWidth',0.5,'LineStyle','None');
end
hold on,plot(0,0,'Marker','o','MarkerSize',10,'MarkerFaceColor','w','MarkerEdgecolor','w','LineWidth',0.5,'LineStyle','None');

scatter(F.X,F.Y,3,zs,'filled','MarkerEdgeColor','none','LineWidth',0.5),colormap(clr)

longLegend(hf,hp,strrep(us,'_',' '),clr,'cluster')


end
