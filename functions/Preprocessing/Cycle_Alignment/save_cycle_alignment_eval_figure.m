function save_cycle_alignment_eval_figure(CODEXobj,file_path)


cr1 = [];
cr2 = [];
for cl = 2:CODEXobj.Ncl
    cr1 = [cr1;CODEXobj.cycle_alignment_info{cl}.cr1];
    cr2 = [cr2;CODEXobj.cycle_alignment_info{cl}.cr2];
end

figure('Position',[1 41 1920 963],'Color','w')
bar(2:CODEXobj.Ncl,cr2,'FaceAlpha',0.5),
hold on,
bar(2:CODEXobj.Ncl,cr1,'FaceAlpha',0.5)
legend({'after registration','before registration'},'Location','northeastoutside')
title('Cycle Alignemnt: DAPI Correlation')
ylabel('correlation'),set(gca,'TickDir','out')
xlabel('cycle')
set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')

saveas(gcf,file_path,'png')

close all


end