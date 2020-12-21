function display_visium_gene_expression_v7(I,Tv,val,ylabel_str)



%% Background image
figure('color','w','position',[1 41 1920 963]);
Ia = 255*ones(size(I),'uint8');
Ia(:,1:10,2:3) = 0; Ia(:,end-10:end,2:3) = 0;
Ia(1:10,:,2:3) = 0; Ia(end-10:end,:,2:3) = 0;
imagesc(Ia),axis equal tight
% set(gca,'Position',[0.02 0.02 0.96 0.96])


%% Scatter plot
clr = flipud(cbrewer('div','RdBu',100,'linear'));
hold on,scatter(Tv.X,Tv.Y,120,val,'filled','MarkerEdgeColor','none','LineWidth',0.5)
colormap(clr)


%% Colorbar
cb = colorbar; cb.FontSize = 20;
cb.Label.String = ylabel_str;


%% Title
% blk = unique(Tv.Region);
% stt = unique(Tv.state);
% title(['ROI ',num2str(unique(Tv.ROI)),' | Block ',blk{:},' | ',stt{:},' | ',gene_name],'FontSize',26)


%% Axis limits
xlim([min(Tv.X)-100 max(Tv.X)+100])
ylim([min(Tv.Y)-100 max(Tv.Y)+100])




end

