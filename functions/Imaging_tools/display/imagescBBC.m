function imagescBBC(Ia)


% ss = get(0,'ScreenSize');

% if(ss(3)==1920&&ss(4)==1080)
    figure('Position',[1 41 1920 963],'Color','w'),imagesc(Ia),axis equal
    set(gca,'Position',[0.02 0.02 0.96 0.96])
    
% else
%     error('define screen new figure position for the current screen resolution')
% end




if(size(Ia,3)==1)
    ButtonMode = uicontrol('style','pushbutton','position',[1850 10 40 30],'String','slider','Enable','on','FontWeight','bold');
    addlistener(ButtonMode, 'Value', 'PostSet', @callImagesMode);
end






    function callImagesMode(source, eventdata)
        if(isa(Ia,'uint8'))
            sliderSin_BBC(0,255)
        elseif(isa(Ia,'uint16'))
            sliderSin_BBC(0,65535)
        elseif(isa(Ia,'double'))
            sliderSin_BBC(0,max(Ia(:)))
        end
    end




    function sliderSin_BBC(cmin,cmax)
        
        cx = caxis;
        
        SliderH = uicontrol('style','slider','position',[400 50 600 20],...
            'min', cmin, 'max', cmax,'SliderStep',[0.00001 0.00001],'Value',cx(2));
        
        addlistener(SliderH, 'Value', 'PostSet', @callbackfn);
        
        function callbackfn(source, eventdata)
            caxis([0 get(eventdata.AffectedObject, 'Value')])
        end
        
    end










end