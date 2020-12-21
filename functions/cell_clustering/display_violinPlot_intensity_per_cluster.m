function display_violinPlot_intensity_per_cluster(CODEXobj,CL)


% F = CODEXobj.marker_intensity{:,CODEXobj.antibody(:,1)};
% F = log10(10000*F./repmat(sum(F,2),[1 size(F,2)])+1);

F = CODEXobj.marker_intensity_normalized{:,CODEXobj.antibody(:,1)};
for k = 1:size(F,2)
    mx = quantile(F(:,k),0.8);
    F(F(:,k)>mx,k) = mx;
end


[us,~,zs] = unique(CL,'stable');

for z = 1:length(us)

    figure('Position',[1 560 1914 435],'Color','w')
    vs = violinplot(F(zs==z,:));
    set(gca,'TickDir','out'),xlim([0.5 size(F,2)+0.5]),box on
    xticks(1:size(F,2)),xticklabels(strrep(CODEXobj.antibody(:,1),'_',' ')),xtickangle(45);
    set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
    %ylabel(strrep([CODEXobj.norm_info.log_norm,' | ',CODEXobj.norm_info.intensity_norm],'_',' '),'FontSize',20)
    title(strrep(us{z},'_',' '))
    
end



end


