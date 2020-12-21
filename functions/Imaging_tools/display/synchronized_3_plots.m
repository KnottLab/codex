function synchronized_3_plots(I1,I2,I3)

figure('Position',[1 41 1920 963],'Color','w')

ax1 = axes('Position',[0.02 0.1 0.3 0.8]);
imagesc(I1), axis tight equal

ax2 = axes('Position',[0.35 0.1 0.3 0.8]);
imagesc(I2), axis tight equal

ax3 = axes('Position',[0.68 0.1 0.3 0.8]);
imagesc(I3), axis tight equal



%%
sliderSin_BBC_3Images(ax1,ax2,ax3,0,65536)

%%
linkaxes([ax1 ax2 ax3],'xy')
cb = colorbar('southoutside');
cb.Position = [0.78 0.05 0.2 0.022];


end



function sliderSin_BBC_3Images(ax1,ax2,ax3,cmin,cmax)

cx = caxis;

SliderH = uicontrol('style','slider','position',[600 20 800 20],...
    'min', cmin, 'max', cmax,'SliderStep',[0.001 0.001],'Value',cx(2));

addlistener(SliderH, 'Value', 'PostSet', @callbackfn);

    function callbackfn(source, eventdata)
        set(ax1,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax2,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax3,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
    end

end












