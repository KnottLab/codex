function display_clusters_UMAP(F,CL)


% figure('color','w','position',[1 41 1920 963]);
% scatter(F.UMAP1,F.UMAP2,5,'filled','MarkerEdgeColor',[.2 .2 .2],'LineWidth',0.5)%,colormap(clr)
% xlabel('UMAP1'),ylabel('UMAP2'), box on, grid on,set(gca,'TickDir','out'),axis square
% set(findall(gcf,'-property','FontSize'),'FontSize',12,'FontWeight','bold')



[us,~,zs] = unique(CL);
% clr = cbrewer('qual','Set1',max(zs),'linear'); clr = clr(1:max(zs),:);
clr = get_celltype_color(us);
hf = figure('color','w','position',[1 41 1100 954]);
hp = {}; for z = 1:max(zs); hold on,hp{z} = plot(F.UMAP1(zs==z),F.UMAP2(zs==z),'Marker','o','MarkerSize',7,'MarkerFaceColor',clr(z,:),'MarkerEdgecolor',[.2 .2 .2],'LineWidth',0.5,'LineStyle','None');end; hold on,plot(F.UMAP1,F.UMAP2,'Marker','o','MarkerSize',10,'MarkerFaceColor','w','MarkerEdgecolor','w','LineWidth',0.5,'LineStyle','None');
scatter(F.UMAP1,F.UMAP2,6,zs,'filled','MarkerEdgeColor','none','LineWidth',0.5),colormap(clr)
xlabel('UMAP1'),ylabel('UMAP2'), box on, grid on,set(gca,'TickDir','out'),axis square
set(findall(gcf,'-property','FontSize'),'FontSize',12,'FontWeight','bold')
longLegend(hf,hp,strrep(us,'_',' '),clr,'cluster')



end
