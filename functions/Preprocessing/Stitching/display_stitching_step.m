function display_stitching_step(J,CODEXobj,I1,I2,I2r,reg_info,tform)


W = CODEXobj.Width;
w = CODEXobj.width;
D = W - w;



figure('Position',[1 41 1920 963],'Color','w')
subplot(1,2,1),imagesc(J),axis tight equal;set(gca,'Position',[0.01 0.2 0.475 0.6])
for x = 1:CODEXobj.Nx; hold on,plot([1 size(J,2)],[x*w x*w]+D,'r','LineWidth',2); end
for y = 1:CODEXobj.Ny; hold on,plot([y*w y*w]+D,[1 size(J,1)],'r','LineWidth',2); end
for y = 1:CODEXobj.Ny; hold on,plot([y*w y*w],[1 size(J,1)],'k--','LineWidth',2); end
for x = 1:CODEXobj.Nx; hold on,plot([1 size(J,2)],[x*w x*w],'k--','LineWidth',2); end


if(strcmp(reg_info.orientation,'east'))
    pos1 = [w 1 D W];
    pos2 = [1 1 D W];
    pos3 = [0.55 0.001 0.03 0.45];
    pos4 = [0.65 0.001 0.03 .45];
    pos5 = [0.487 0.14 0.1 0.1];
    pos6 = [0.59 0.14 0.1 0.1];
elseif(strcmp(reg_info.orientation,'west'))
    pos1 = [1 1 D W];
    pos2 = [w 1 D W];
    pos3 = [0.55 0.001 0.03 0.45];
    pos4 = [0.65 0.001 0.03 .45];
    pos5 = [0.487 0.14 0.1 0.1];
    pos6 = [0.59 0.14 0.1 0.1];
elseif(strcmp(reg_info.orientation,'north'))
    pos1 = [1 1 W D];
    pos2 = [1 w W D];
    pos3 = [0.505 0.3 0.228 0.1];
    pos4 = [0.505 0.17 0.228 0.1];
    pos5 = [0.6 0.31 0.1 0.1];
    pos6 = [0.6 0.18 0.1 0.1];
elseif(strcmp(reg_info.orientation,'south'))
    pos1 = [1 w W D];
    pos2 = [1 1 W D];
    pos3 = [0.505 0.3 0.228 0.1];
    pos4 = [0.505 0.17 0.228 0.1];
    pos5 = [0.6 0.31 0.1 0.1];
    pos6 = [0.6 0.18 0.1 0.1];
end


subplot(2,4,3),imagesc(I1),axis tight equal; hold on,rectangle('Position',pos1,'EdgeColor','r','LineWidth',2);set(gca,'Position',[0.5 0.5 0.24 0.45]),annotation('textbox',[0.52 0.88 0.2 0.1],'String',['Fixed: avrg(O1)=',num2str(reg_info.meanO1)],'FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
subplot(2,4,4),imagesc(I2),axis tight equal; hold on,rectangle('Position',pos2,'EdgeColor','r','LineWidth',2);set(gca,'Position',[0.75 0.5 0.24 0.45]),annotation('textbox',[0.80 0.88 0.2 0.1],'String',['Moving: avrg(O2)=',num2str(reg_info.meanO2),'  | ',reg_info.orientation{:}],'FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
subplot(2,4,8),imagesc(I2r),axis tight equal; set(gca,'Position',[0.75 0.001 0.24 0.45])        
subplot('Position',pos3),imshowpair(reg_info.O1,reg_info.O2,'Scaling','joint');annotation('textbox',pos5,'String',['corr = ',num2str(reg_info.corr1)],'FontSize',12,'FontWeight','bold','EdgeColor','none','Color','k');
subplot('Position',pos4),imshowpair(reg_info.O1,reg_info.O2r,'Scaling','joint');annotation('textbox',pos6,'String',['corr = ',num2str(reg_info.corr2)],'FontSize',12,'FontWeight','bold','EdgeColor','none','Color','k');


annotation('textbox',[0.71 0.35 0.1 0.1],'String',num2str(round(tform.T(3,2))),'FontSize',12,'FontWeight','bold','EdgeColor','none','Color','k');
annotation('textbox',[0.71 0.32 0.1 0.1],'String',num2str(round(tform.T(3,1))),'FontSize',12,'FontWeight','bold','EdgeColor','none','Color','k');
annotation('textbox',[0.70 0.365 0.1 0.1],'String','(','FontSize',40,'FontWeight','normal','EdgeColor','none','Color','k');
annotation('textbox',[0.73 0.365 0.1 0.1],'String',')','FontSize',40,'FontWeight','normal','EdgeColor','none','Color','k');


annotation('textbox',[0.71 0.035 0.1 0.05],'String',num2str(round(reg_info.tf{1}.T(3,2))),'FontSize',12,'FontWeight','bold','EdgeColor','none','Color',[.4 .4 .4]);
annotation('textbox',[0.71 0.005 0.1 0.05],'String',num2str(round(reg_info.tf{1}.T(3,1))),'FontSize',12,'FontWeight','bold','EdgeColor','none','Color',[.4 .4 .4]);
annotation('textbox',[0.70 0.050 0.1 0.05],'String','(','FontSize',40,'FontWeight','normal','EdgeColor','none','Color',[.4 .4 .4]);
annotation('textbox',[0.73 0.050 0.1 0.05],'String',')','FontSize',40,'FontWeight','normal','EdgeColor','none','Color',[.4 .4 .4]);


set(findall(gcf,'-property','TickDir'),'TickDir','out')


end





