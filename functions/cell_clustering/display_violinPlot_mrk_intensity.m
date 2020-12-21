function display_violinPlot_mrk_intensity(CODEXobj)


figure('Position',[1 560 1914 435],'Color','w')
F = CODEXobj.marker_intensity_normalized{:,CODEXobj.antibody(:,1)};
vs = violinplot(F);
set(gca,'TickDir','out'),xlim([0.5 size(F,2)+0.5]),box on
xticks(1:size(F,2)),xticklabels(strrep(CODEXobj.antibody(:,1),'_',' ')),xtickangle(45);
set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
ylabel(strrep([CODEXobj.norm_info.log_norm,' | ',CODEXobj.norm_info.intensity_norm],'_',' '),'FontSize',20)



end


