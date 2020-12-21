function Ia = display_mean_intensities_UMAP(F,markerUse)


disp('generating mean intensities UMAP plots ...')


[~,~,ib] = intersect(markerUse,F.Properties.VariableNames,'stable');

It = {};
for f = ib'

    %val = zscore(table2array(F(:,f)));
    val = table2array(F(:,f));
    
    figure('color','w','position',[1 41 1100 963],'Visible','off');
    %clr = flipud(cbrewer('div','RdBu',100,'linear'));
    clr = flipud(colorGradient([1 0 0],[0.5 0.8 1],100));
    scatter(F.UMAP1,F.UMAP2,6,val,'filled','MarkerEdgeColor','none','LineWidth',0.5)
    set(findall(gcf,'-property','FontSize'),'FontSize',20,'FontWeight','bold')
    colormap(clr),cb = colorbar; cb.FontSize = 40; cb.Label.String = 'mean intensity';
    %caxis([-1 1]*max(abs([quantile(val,0.03) quantile(val,0.97)])));
    caxis([quantile(val,0.05) quantile(val,0.95)]);
    xlabel('UMAP1'),ylabel('UMAP2'),set(gca,'TickDir','out'),box on,grid on,axis square
    title(strrep(strrep(F.Properties.VariableNames{f},'meanIntensity_',''),'_',' '),'FontSize',60)
    fr = getframe(gcf); fr = fr.cdata; It{length(It)+1} = fr;
    
end


% concatenate figures
Ia = imageStruct2BigImage(It);
figure,imshow(Ia)



end




