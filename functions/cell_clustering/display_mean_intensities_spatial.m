function Ia = display_mean_intensities_spatial(F,E,markerUse)


disp('generating mean intensities UMAP plots ...')


[~,~,ib] = intersect(markerUse,F.Properties.VariableNames,'stable');


It = {};
for f = ib'

    %val = zscore(table2array(F(:,f)));
    val = table2array(F(:,f));
    
    figure('color','w','position',[1 41 1100 954]);
    Ia = 255*ones(size(E,1),size(E,2),3,'uint8');
    imagesc(Ia),hold on,set(gca,'TickDir','out'),axis tight equal; hold on,
    hold on,
    
    %clr = flipud(cbrewer('div','RdBu',100,'linear'));
    clr = flipud(colorGradient([1 0 0],[0.5 0.8 1],100));
    scatter(F.X,F.Y,6,val,'filled','MarkerEdgeColor','none','LineWidth',0.5)
    set(findall(gcf,'-property','FontSize'),'FontSize',20,'FontWeight','bold')
    colormap(clr),cb = colorbar; cb.FontSize = 40; cb.Label.String = 'mean intensity';
    %caxis([-1 1]*max(abs([quantile(val,0.03) quantile(val,0.97)])));
    caxis([quantile(val,0.05) quantile(val,0.95)]);
    title(strrep(strrep(F.Properties.VariableNames{f},'meanIntensity_',''),'_',' '),'FontSize',60)
    fr = getframe(gcf); fr = fr.cdata; It{length(It)+1} = fr;
    
    close all
end


% concatenate figures
Ia = imageStruct2BigImage(It);
figure,imshow(Ia)



end




