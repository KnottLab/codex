function longLegend(hf,hp,us,clr,title)

nl = 50; % number of elements per column
font_size = 14;

if(length(us)>45)
    
    nc = ceil(length(us)/nl);
    
    hf2 = figure('color','w','position',[1 41 120 950]);
    
    %% Plot dots and text
    i = 1; j = 0.1; 
    for k = 1:length(us)
        hold on,plot(j,i,'Marker','o','MarkerFaceColor',clr(k,:),'MarkerEdgeColor','k')
        text(j+0.1,i,us{k},'HorizontalAlignment','left','FontName','Consolas','FontSize',font_size,'FontWeight','bold');
        if(mod(k,nl)==0); j = j+0.65; i = 0; end
        i = i+1;
    end
    
    %% Add box 
    set(gca, 'YDir','reverse')
    hold on,plot([0 0],[-1 nl+1],'k','LineWidth',1)
    hold on,plot([0.6 0.6]*nc,[-1 nl+1],'k','LineWidth',1)
    hold on,plot([0 0.6*nc],[0.2 0.2],'k','LineWidth',1)
    hold on,plot([0 0.6*nc],[nl+1 nl+1],'k','LineWidth',1)
    hold on,plot([0 0.6*nc],[-1 -1],'k','LineWidth',1)
    text((nc-1)/2,-0.5,title,'HorizontalAlignment','center','FontSize',font_size,'FontWeight','bold');
    ylim([-1 nl+1])
    axis off
    
    %% Add to the main figure
    axes1 = hf.Children(end);
    axes2 = hf2.Children(end);
    set(axes2,'Parent',hf);
    p1 = get(axes1,'Position');
    p2 = get(axes2,'Position');
    set(axes1,'Position',p1-[0.06 0 0 0])
    if(nc==2)
        set(axes2,'Position',p2+[0.7 0 -0.7 0])
    else
        set(axes2,'Position',p2+[0.7 0 -0.65 0])
    end
    close(hf2)
    
    
    
    
    
else
    
    lgh = legend([hp{:}],us,'Location','northeastoutside','FontSize',font_size,'FontWeight','bold');
    lgh.Title.String = title; %title(stnorm);
    
    
    
end

