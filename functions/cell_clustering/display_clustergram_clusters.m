function Ia = display_clustergram_clusters(F,CL,markerUse,celltype)

close all force

[~,~,ib] = intersect(markerUse,F.Properties.VariableNames,'stable');



%% Calculate average intensity per cluster
M = [];
[Ucl,~,Zcl] = unique(strrep(CL,'_',' '));
for cl = 1:length(Ucl)
    Mt = [];
    for f = ib'
        Mt = [Mt mean(F{Zcl==cl,f})];
    end
    M = [M;Mt];
end
% M = (M - repmat(min(M,[],1),[size(M,1) 1]))./repmat(max(M,[],1)-min(M,[],1),[size(M,1) 1]);
% M(strcmp(Ucl,'25')|strcmp(Ucl,'16'),:) = 0;
% M(strcmp(Ucl,'10'),:) = 0;



%% Clustergram
clr = flipud(cbrewer('div','RdBu',100,'linear'));
cgo = clustergram(M',...
    'Cluster','all',...
    'Standardize','row',...
    'DisplayRange',2,...
    'RowLabels',strrep(F.Properties.VariableNames(ib),'_',' '),...
    'ColumnLabels',Ucl,...
    'Colormap',clr,...
    'OptimalLeafOrder',false,...
    'Symmetric',true,...
    'DisplayRatio',1/20);pause(1)
set(0,'showhiddenhandles','on');
hp = plot(cgo);
hf = hp.Parent;
set(hf,'Position',[1 41 1920 963],'Color','w')
set(findall(hf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
hf.Children

[us,~,zs] = unique(Ucl);
%clr = cbrewer('qual','Set1',length(us),'linear');
clr = get_celltype_color(Ucl);
sz.Labels = Ucl;
sz.Colors = cell(size(sz.Labels,1),1);
for x = 1:length(us)
    sz.Colors(zs==x,1) = {clr(x,:)};
end
set(cgo,'ColumnLabels',sz.Labels,...
    'ColumnLabelsColor',sz,...
    'LabelsWithMarkers',1);
set(findall(hf,'-property','FontSize'),'FontSize',12,'FontWeight','bold')

cb = colorbar(hp,'Position',[0.05 0.3 0.015 0.3]);
cb.Label.String = {'Mean intensity'};
cb.FontSize = 12;
hf.Children

cls = get(findobj(hf,'Tag','XLabeledAxes'),'Xticklabels');

Ia = getframe(hf); Ia = Ia.cdata;


%% Add legend
if(nargin<4&&length(us)<25)
    
    hp2 = {};
    for x = 1:length(us)
        hold on,hp2{x} = plot([20000 20000],[1 2],'s','color',clr(x,:),'MarkerFaceColor',clr(x,:),'linewidth',5);
    end
    uistack(hp)
    hlg = legend([hp2{:}],strrep(us,'_','-'),'Location','northeastoutside','Position',[0.02 0.76 0.07 0.08],'FontSize',10,'FontWeight','bold');
    title(hlg,'cell type')
    hf = hp.Parent;
    hf.Children
    %annotation('textbox',[.205 .125 0.5 0],'String','cell type','FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
    
    Ia2 = getframe(hf); Ia2 = Ia2.cdata;
    
    Ia(1:380,5:250,:) = Ia2(1:380,5:250,:);

end





%% Add celltype
if(nargin>=4)
    
    Uc = {};
    for cl = 1:length(Ucl)
        Uc = [Uc unique(celltype(Zcl==cl))];
    end
    
    [us,~,zs] = unique(Uc);
    clr = get_celltype_color(us);
    %clr = cbrewer('qual','Set1',length(us),'linear');
    sz.Labels = Uc;
    sz.Colors = cell(size(sz.Labels,1),1);
    for x = 1:length(us)
        sz.Colors(zs==x,1) = {clr(x,:)};
    end
    set(cgo,'ColumnLabels',sz.Labels,...
        'ColumnLabelsColor',sz,...
        'LabelsWithMarkers',1);
    set(cgo,'ColumnLabels',{})
    
    hp2 = {};
    for x = 1:length(us)
        hold on,hp2{x} = plot([20000 20000],[1 2],'s','color',clr(x,:),'MarkerFaceColor',clr(x,:),'linewidth',5);
    end
    uistack(hp)
    hlg = legend([hp2{:}],strrep(us,'_','-'),'Location','northeastoutside','Position',[0.02 0.76 0.07 0.08],'FontSize',10,'FontWeight','bold');
    title(hlg,'cell type')
    hf = hp.Parent;
    hf.Children
    %annotation('textbox',[.205 .125 0.5 0],'String','cell type','FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
    
    Ia2 = getframe(hf); Ia2 = Ia2.cdata;
    
    Ia(1:380,5:250,:) = Ia2(1:380,5:250,:);
    Ia((845:880)+80,255:1580,:) = Ia2(845:880,255:1580,:);
    
    
end




%% Number of cells
N = [];
for cl = 1:length(Ucl)
    N = [N sum(Zcl==cl)];
end

[~,~,ib] = intersect(cls,Ucl,'stable');
N = N(ib');

figure('Position',[1 41 1920 80],'Color','w','Visible','off')
clr = cbrewer('seq','Greens',100,'linear');
imagesc(N),colormap(clr)
set(gca,'Position',get(findobj(hf,'Tag','HeatMapAxes'),'Position'))
xticks([]),yticks([]),
for cl = 1:length(Ucl)
    if(N(cl)>2*mean(N)); clr = [1 1 1]; else; clr = [0 0 0]; end
    text(cl,1,num2str(N(cl)),'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color',clr)
end
% annotation('textbox',[.01 .01 0.1 0.01],'String','Nbr. cells','FontSize',14,'FontWeight','bold','EdgeColor','none','Color','k');
Ia1 = getframe(gcf); Ia1 = Ia1.cdata;



%% Percentage of cells
P = N./sum(N);

figure('Position',[1 41 1920 80],'Color','w','Visible','off')
clr = cbrewer('seq','Purples',100,'linear');
imagesc(P),colormap(clr)
set(gca,'Position',get(findobj(hf,'Tag','HeatMapAxes'),'Position'))
xticks([]),yticks([]),
for cl = 1:length(Ucl)
    if(N(cl)>2*mean(N)); clr = [1 1 1]; else; clr = [0 0 0]; end
    text(cl,1,[num2str(round(100*P(cl))),'%'],'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color',clr)
end
Ia2 = getframe(gcf); Ia2 = Ia2.cdata;



%%
close all force
Ia = [Ia;Ia1;Ia2];
figure,imshow(Ia)



end

















