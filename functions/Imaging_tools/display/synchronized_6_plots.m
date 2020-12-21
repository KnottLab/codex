function synchronized_6_plots(I1,I2,I3,I4,I5,I6)



figure('Position',[1 41 1920 963],'Color','w')

ax1 = axes('Position',[0.02 0.535 0.3 0.46]);
imagesc(I1), axis tight equal

ax2 = axes('Position',[0.35 0.535 0.3 0.46]);
imagesc(I2), axis tight equal

ax3 = axes('Position',[0.68 0.535 0.3 0.46]);
imagesc(I3), axis tight equal

ax4 = axes('Position',[0.02 0.05 0.3 0.46]);
imagesc(I4), axis tight equal

ax5 = axes('Position',[0.35 0.05 0.3 0.46]);
imagesc(I5), axis tight equal

ax6 = axes('Position',[0.68 0.05 0.3 0.46]);
imagesc(I6), axis tight equal



%%
sliderSin_BBC_6Images(ax1,ax2,ax3,ax4,ax5,ax6,0,65536)


%%
linkaxes([ax1 ax2 ax3 ax4 ax5 ax6],'xy')
cb = colorbar('southoutside');
cb.Position = [0.78 0.01 0.2 0.022];


end



function sliderSin_BBC_6Images(ax1,ax2,ax3,ax4,ax5,ax6,cmin,cmax)

cx = caxis;

SliderH = uicontrol('style','slider','position',[600 5 800 20],...
    'min', cmin, 'max', cmax,'SliderStep',[0.001 0.001],'Value',cx(2));

addlistener(SliderH, 'Value', 'PostSet', @callbackfn);

    function callbackfn(source, eventdata)
        set(ax1,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax2,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax3,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax4,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax5,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
        set(ax6,'CLim',[0 get(eventdata.AffectedObject, 'Value')])
    end

end












