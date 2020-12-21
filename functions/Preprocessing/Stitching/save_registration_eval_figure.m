function save_registration_eval_figure(stitching_info,file_path)


cr1 = [];
cr2 = [];
for t = 1:length(stitching_info.reg_info)
    cr1 = [cr1;stitching_info.reg_info{t}.corr1];
    cr2 = [cr2;stitching_info.reg_info{t}.corr2];
end

figure('Position',[1 41 1920 963],'Color','w')
bar(cr2,'FaceAlpha',0.5),hold on,bar(cr1,'FaceAlpha',0.5)
legend({'after registration','before registration'},'Location','northeastoutside')
title('Overlap Correlation')
ylabel('correlation'),set(gca,'TickDir','out')
xlabel('tile')
set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')

saveas(gcf,file_path,'png')

close all


end