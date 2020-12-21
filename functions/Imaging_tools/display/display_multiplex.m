function display_multiplex(I1,mrk1,I3,mrk3,E,M,T,G)

disp('Opening Multiplex Viewer ...')

if(nargin<8); G = []; end
if(nargin<7); T = []; end
if(nargin<6); M = []; end
if(nargin<5); E = []; end
if(nargin<4); mrk3 = []; end
if(nargin<3); I3 = []; end



%% Initialization

if(~isempty(I1))
    mrk1 = strrep(mrk1(:,1),'_',' ');
    [cmin,cmax,cval] = get_intensity_range(I1);
end

k1 = 1;
k3 = 1;


if(~isempty(I3))    
    if(~iscell(I3)); It{1} = I3; I3 = It; end
    if(~iscell(mrk3)); mrk3 = cellstr(mrk3) ; end
    if(isempty(I1))
        figure('Position',[1 41 1920 963],'Color',[0.94 0.94 0.94])
        imagesc(I3{k3}); axis equal; title(mrk3{k3},'FontSize',20)
        cb = colorbar; set(cb,'Visible','off')
        J = I3{k3};
    else
        figure('Position',[1 41 1920 963],'Color',[0.94 0.94 0.94])
        imagesc(I1{k1}); axis equal; title(mrk1{k1},'FontSize',20)
        cb = colorbar; set(cb,'Visible','on')
        J = I1{k1}; caxis([cmin{k1} cval{k1}])
    end
else
    figure('Position',[1 41 1920 963],'Color',[0.94 0.94 0.94])
    imagesc(I1{k1}); axis equal; title(mrk1{k1},'FontSize',20)
    cb = colorbar; set(cb,'Visible','on')
    J = I1{k1}; caxis([cmin{k1} cval{k1}])
end
set(gca,'Position',[0.08 0.11 0.9 0.815])


MrkColor = cell(length(I1),1);
NodeColor = {};
NodeSize = 6;








%% RGB images
ButtonMode1 = uicontrol('style','pushbutton','position',[1700 20 130 30],'String','RGB mode','Enable','on','FontWeight','bold','Visible','off');
addlistener(ButtonMode1, 'Value', 'PostSet', @callRGBmode);

button1 = cell(length(I3),1);
a = imageButtonOrganizer(mrk3);
for k = 1:length(I3)
    button1{k} = uicontrol('style','pushbutton','position',[20 900-k*a(1) 80 a(2)],'String',mrk3{k},'FontWeight','bold','FontSize',a(3),'Visible','off');
    addlistener(button1{k}, 'Value', 'PostSet', @callRGBimage);
end






%% Gray-level images
ButtonMode2 = uicontrol('style','pushbutton','position',[1564 20 130 30],'String','Gray-level mode','Enable','off','FontWeight','bold','Visible','off');
addlistener(ButtonMode2, 'Value', 'PostSet', @callGrayMode);


button2 = cell(length(I1),1);
radioButton = cell(length(I1),1);
rectanColor = cell(length(I1),1);
a = imageButtonOrganizer(mrk1);
for k = 1:length(I1)
    button2{k} = uicontrol('style','pushbutton','position',[20 900-k*a(1) 80 a(2)],'String',mrk1{k},'FontWeight','bold','FontSize',a(3),'Visible','off');
    addlistener(button2{k}, 'Value', 'PostSet', @callGrayImage);
    radioButton{k} = uicontrol('style','radiobutton','position',[102 900-k*a(1) 15 a(2)],'Tag',mrk1{k},'Visible','off');
    addlistener(radioButton{k}, 'Value', 'PostSet', @callbackRadioButton);
    rectanColor{k} = uicontrol('style','text','position',[119 900-k*a(1) 15 a(2)],'Tag',mrk1{k},'Visible','off');
end


slider = cell(length(I1),1);
txtbox = cell(length(I1),1);
maxpos = cell(length(I1),1);
for k = 1:length(I1)
    slider{k} = uicontrol('style','slider','Units','normalized','position',[.4 .05 .2 .02],'min',cmin{k},'max',cmax{k},'Value',cval{k},'SliderStep',[1 1]*(10^-4),'Visible','off');
    addlistener(slider{k}, 'Value', 'PostSet', @callSlider);
    pos = get(slider{k},'Position');
    txtbox{k} = annotation('textbox',[0.95*pos(1) pos(2) .05 pos(4)],'String',[num2str(round(100*cval{k}/cmax{k})),'%'],'FontSize',10,...
        'FontWeight','normal','EdgeColor','none','Color','k','HorizontalAlignment','left','VerticalAlignment','middle','Visible','off');
    maxpos{k} = annotation('line',[1 1]*(pos(1)+pos(3)*0.04+pos(3)*0.92*cval{k}/cmax{k}),[0.8*pos(2) pos(2)+1.5*pos(4)],'Units','normalized','Visible','off');
end





%% Overlay Buttons
overlayButton = uicontrol('style','pushbutton','position',[10 30 100 40],'String','overlay markers','FontWeight','bold','Visible','off');
addlistener(overlayButton, 'Value', 'PostSet', @callbackOverlayMarkers);

overlayNucleiButton = uicontrol('style','pushbutton','position',[115 30 80 40],'String','nuclei segm.','FontWeight','bold','Visible','off');
addlistener(overlayNucleiButton, 'Value', 'PostSet', @callbackOverlayNuclei);

overlayCentroidsButton = uicontrol('style','pushbutton','position',[200 30 60 40],'String','centroids','FontWeight','bold','Visible','off');
addlistener(overlayCentroidsButton, 'Value', 'PostSet', @callbackOverlayCentroids);

overlayMembraneButton = uicontrol('style','pushbutton','position',[265 30 70 40],'String','membrane','FontWeight','bold','Visible','off');
addlistener(overlayMembraneButton, 'Value', 'PostSet', @callbackOverlayMembrane);

overlayClassButton = uicontrol('style','pushbutton','position',[340 30 50 40],'String','nodes','Visible','on','FontWeight','bold','Visible','off');
addlistener(overlayClassButton, 'Value', 'PostSet', @callbackOverlayClasses);

overlayGraphButton = uicontrol('style','pushbutton','position',[395 30 50 40],'String','graph','FontWeight','bold','Visible','off');
addlistener(overlayGraphButton, 'Value', 'PostSet', @callbackOverlayGraph);






%% Node classes Mode
ButtonMode3 = uicontrol('style','pushbutton','position',[10 910 90 40],'String','select markers','Enable','off','FontWeight','bold','Visible','off');
addlistener(ButtonMode3, 'Value', 'PostSet', @callImagesMode);

ButtonMode4 = uicontrol('style','pushbutton','position',[105 910 90 40],'String','select nodes','Enable','on','FontWeight','bold','Visible','off');
addlistener(ButtonMode4, 'Value', 'PostSet', @callNodesMode);


button3 = {};
radioButton3 = {};
rectanColor3 = {};
popUpList = [];
if(~isempty(T))
    
    set(overlayCentroidsButton,'Visible','on')
    
    choices = T.Properties.VariableNames;
    choices = choices(contains(lower(choices),'cell_type')|contains(lower(choices),'cluster'));
    
    if(~isempty(choices))
        
        set(ButtonMode3,'Visible','on')
        set(ButtonMode4,'Visible','on')
        set(overlayClassButton,'Visible','on')
        
        popUpList = uicontrol('style','popup','position',[10 870 200 30],'string',choices,'FontWeight','bold','Visible','off');
        addlistener(popUpList, 'Value', 'PostSet', @callPopUp);
        
        for l = 1:length(choices)
            
            Uc = unique(T{:,choices{l}});
            
            [pn,ss] = nodeButtonOrganizer(Uc);
            
            for c = 1:length(Uc)
                button3{l,c} = uicontrol('style','pushbutton','position',pn{c,1},'String',Uc{c},'Visible','off','FontWeight','bold','FontSize',ss);
                addlistener(button3{l,c}, 'Value', 'PostSet', @callNodeClass);
                radioButton3{l,c} = uicontrol('style','radiobutton','position',pn{c,2},'Tag',Uc{c},'Visible','off');
                addlistener(radioButton3{l,c}, 'Value', 'PostSet', @callbackRadioButton4);
                rectanColor3{l,c} = uicontrol('style','text','position',pn{c,3},'Tag',Uc{c},'Visible','off');
            end
            
        end
        
        
    end
    
end






%% Background and node size
ButtonBG1 = uicontrol('style','pushbutton','position',[1800 110 70 30],'String','white BG','Enable','on','FontWeight','bold','Visible','off');
addlistener(ButtonBG1, 'Value', 'PostSet', @callBG1);

ButtonBG2 = uicontrol('style','pushbutton','position',[1800 78 70 30],'String','black BG','Enable','on','FontWeight','bold','Visible','off');
addlistener(ButtonBG2, 'Value', 'PostSet', @callBG2);

edit = uicontrol('style','edit','position',[1800 145 70 30],'String','node size','Callback',@user_edit,'Visible','off');















%% Functions

m1 = 2;
    function callRGBmode(~, ~)
        set(cb,'Visible','off')
        set(ButtonMode1,'Enable','off')
        set(ButtonMode2,'Enable','on')
        set(ButtonMode3,'Enable','off')
        set(ButtonMode4,'Enable','on')
        ih = get(gca,'Children');
        ih(end).CData = I3{k3};
        title(mrk3{k3},'FontSize',20)
        for k = 1:length(I3)
            set(button1{k},'Visible','on')
        end
        for k = 1:length(I1)
            set(button2{k},'Visible','off')
            set(radioButton{k},'Visible','off')
            set(rectanColor{k},'Visible','off')
            set(slider{k},'Visible','off')
            set(txtbox{k},'Visible','off')
            set(maxpos{k},'Visible','off')
        end
        set(overlayButton,'Visible','off')
        m1 = 1;
        callImagesMode()
    end


    function callGrayMode(~, ~)
        set(ButtonMode1,'Enable','on')
        set(ButtonMode2,'Enable','off')
        set(ButtonMode3,'Enable','off')
        set(ButtonMode4,'Enable','on')
        ih = get(gca,'Children');
        ih(end).CData = J;
        if(size(J,3)==1)
            caxis([cmin{k1} cval{k1}]); 
            title(mrk1{k1},'FontSize',20)
            set(slider{k1},'Visible','on')
            set(txtbox{k1},'Visible','on')
            set(maxpos{k1},'Visible','on')
            set(cb,'Visible','on')
        else
            title('','FontSize',20)
        end
        for k = 1:length(I3)
            set(button1{k},'Visible','off')
        end
        for k = 1:length(I1)
            set(button2{k},'Visible','on')
            set(radioButton{k},'Visible','on')
            set(rectanColor{k},'Visible','on')
        end
        set(overlayButton,'Visible','on')
        m1 = 2;
        callImagesMode()
    end


    function callRGBimage(~, eventdata)
        k3 = find(strcmp(mrk3,eventdata.AffectedObject.String));
        ih = get(gca,'Children');
        ih(end).CData = I3{k3};
        title(mrk3{k3},'FontSize',20)
    end


    function callSlider(~, eventdata)
        fh = get(gcf,'Children');
        caxis(fh(end),[0 get(eventdata.AffectedObject,'Value')])
        clm = get(gca,'CLim');
        cval{k1} = clm(2);
        set(txtbox{k1},'String',[num2str(round(100*cval{k1}/cmax{k1})),'%'])
    end


    function callGrayImage(~, eventdata)
        set(slider{k1(1)},'Visible','off')
        set(txtbox{k1(1)},'Visible','off')
        set(maxpos{k1(1)},'Visible','off')
        k1 = find(strcmp(mrk1,eventdata.AffectedObject.String));
        J = I1{k1};
        ih = get(gca,'Children');
        ih(end).CData = J;
        caxis([cmin{k1} cval{k1}]);
        title(mrk1{k1},'FontSize',20)
        set(slider{k1},'Visible','on')
        set(txtbox{k1},'Visible','on')
        set(maxpos{k1},'Visible','on')
        cb = colorbar;
    end


    function callbackRadioButton(~, eventdata)
        set(slider{k1},'Visible','off')
        set(txtbox{k1},'Visible','off')
        set(maxpos{k1},'Visible','off')
        k1 = find(strcmp(mrk1,eventdata.AffectedObject.Tag));
        ih = get(gca,'Children');
        ih(end).CData = I1{k1};
        caxis([cmin{k1} cval{k1}])
        title(mrk1{k1},'FontSize',20)
        set(slider{k1},'Visible','on')
        set(txtbox{k1},'Visible','on')
        set(maxpos{k1},'Visible','on')
        if(get(radioButton{k1},'Value')==1)
            MrkColor{k1} = uisetcolor([1 1 1],mrk1{k1});
            set(rectanColor{k1},'Visible','on','BackgroundColor',MrkColor{k1})
        else
            set(rectanColor{k1},'Visible','off')
        end
    end


    function callbackOverlayMarkers(~, ~)
        hn = {};
        set(cb,'Visible','off')
        title({})
        set(slider{k1},'Visible','off')
        set(txtbox{k1},'Visible','off')
        set(maxpos{k1},'Visible','off')
        J = zeros(size(I1{1},1),size(I1{1},2),3,'uint8');
        for k = 1:length(I1)
            if(get(radioButton{k},'Value')==1)
                J(:,:,1) = J(:,:,1) + uint8(255*MrkColor{k}(1)*double(I1{k})/cval{k});
                J(:,:,2) = J(:,:,2) + uint8(255*MrkColor{k}(2)*double(I1{k})/cval{k});
                J(:,:,3) = J(:,:,3) + uint8(255*MrkColor{k}(3)*double(I1{k})/cval{k});
            end
        end
        ih = get(gca,'Children');
        ih(end).CData = J;
    end


sn1 = 0; mh1 = [];
    function callbackOverlayNuclei(~, ~)
        
        if(sn1==0)
            if(isempty(mh1))
                ih = findobj(gcf,'type','image');
                J = ih(end).CData;
                if(size(J,3)==1);cm = 255;else;cm = cmax{k1};end
                mi = 10000*cm*double(E>0);
                hold on,mh1 = imagesc(mi);hold off,set(mh1,'AlphaData',mi);
                if(size(J,3)==1);fh = get(gcf,'Children');caxis(fh(end),[0 cval{k1}]);end
            else
                set(mh1,'Visible','on');
            end
            sn1 = 1;
        else
            set(mh1,'Visible','off')
            sn1 = 0;
        end
        
    end


sm1 = 0; mh2 = [];
    function callbackOverlayMembrane(~, ~)
        
        if(sm1==0)
            if(isempty(mh2))
                ih = findobj(gcf,'type','image');
                J = ih(end).CData;
                if(size(J,3)==1);cm = 255;else;cm = cmax{k1};end
                mi = 10000*cm*double(M>0);
                hold on,mh2 = imagesc(mi);hold off,set(mh2,'AlphaData',mi);
                if(size(J,3)==1);fh = get(gcf,'Children');caxis(fh(end),[0 cval{k1}]);end
            else
                set(mh2,'Visible','on');
            end
            sm1 = 1;
        else
            set(mh2,'Visible','off')
            sm1 = 0;
        end
        
    end


h0 = {};
s0 = 0;
    function callbackOverlayCentroids(~, ~)
        if(s0==1)
            set(h0,'Visible','off')
            s0 = 0;
        else
            hold on,h0 = plot(T.X,T.Y,'Marker','o','MarkerSize',NodeSize,'LineStyle','none','MarkerEdgeColor',0.4*[1 0 0],'MarkerFaceColor',[1 0 0]);
            s0 = 1;
        end
    end


    function callImagesMode(~, ~)
        set(ButtonMode3,'Enable','off')
        set(ButtonMode4,'Enable','on')
        if(~isempty(popUpList)); set(popUpList,'Visible','off'); end
        set(ButtonBG1,'Visible','off')
        set(ButtonBG2,'Visible','off')
        set(edit,'Visible','off')
        if(m1==1)
            for k = 1:length(I3)
                set(button1{k},'Visible','on')
            end
            for k = 1:length(I1)
                set(button2{k},'Visible','off')
            end
        elseif(m1==2)
            for k = 1:length(I3)
                set(button1{k},'Visible','off')
            end
            for k = 1:length(I1)
                set(button2{k},'Visible','on')
                set(radioButton{k},'Visible','on')
                if(get(radioButton{k},'Value')==1)
                    set(rectanColor{k},'Visible','on')
                end
            end
        end
        
        for l = 1:size(button3,1)
            for c = 1:size(button3,2)
                set(button3{l,c},'Visible','off')
                set(radioButton3{l,c},'Visible','off')
                set(rectanColor3{l,c},'Visible','off')
            end
        end
        
    end


    function callNodesMode(~, ~)
        set(ButtonMode3,'Enable','on')
        set(ButtonMode4,'Enable','off')
        set(popUpList,'Visible','on')
        for k = 1:length(I3)
            set(button1{k},'Visible','off')
        end
        for k = 1:length(I1)
            set(button2{k},'Visible','off')
            set(radioButton{k},'Visible','off')
            set(rectanColor{k},'Visible','off')
        end
        set(ButtonBG1,'Visible','on')
        set(ButtonBG2,'Visible','on')
        set(edit,'Visible','on')
        
        for c = 1:size(button3,2)
            set(button3{slct,c},'Visible','on')
            set(radioButton3{slct,c},'Visible','on')
            set(rectanColor3{slct,c},'Visible','on')
        end
        
    end


hp = {};
    function callbackRadioButton4(~, eventdata)
        [Uc,~,Zc] = unique(T{:,choices{slct}});
        c0 = eventdata.AffectedObject.Tag;
        c0 = find(strcmp(Uc,c0));
        if(get(radioButton3{slct,c0},'Value')==1)
            NodeColor{slct,c0} = uisetcolor([1 1 1],Uc{c0});
            set(rectanColor3{slct,c0},'Visible','on','BackgroundColor',NodeColor{slct,c0})
            hold on,hp{slct,c0} = plot(T.X(Zc==c0),T.Y(Zc==c0),'Marker','o','MarkerSize',NodeSize,'LineStyle','none','MarkerEdgeColor',0.4*NodeColor{slct,c0},'MarkerFaceColor',NodeColor{slct,c0});
        else
            set(rectanColor3{slct,c0},'Visible','off')
            set(hp{slct,c0},'Visible','off')
        end
    end


s6 = 0;
    function callNodeClass(~, eventdata)
        h = findobj(gcf,'type','line');
        if(s6==1)
            for n = 1:length(h)
                set(h(n),'Visible','off')
            end
            s6 = 0;
        else
            [Uc,~,Zc] = unique(T{:,choices{slct}});
            c0 = eventdata.AffectedObject.String;
            c0 = find(strcmp(Uc,c0));
            hold on,plot(T.X(Zc==c0),T.Y(Zc==c0),'Marker','o','MarkerSize',NodeSize,'LineStyle','none','MarkerEdgeColor',[0.4 0 0],'MarkerFaceColor',[1 0 0]);
            %hold on,plot(T.X(Zc==c0),T.Y(Zc==c0),'Marker','s','MarkerSize',NodeSize,'LineStyle','none','MarkerEdgeColor',[0 1 0],'MarkerFaceColor','none');
            s6 = 1;
        end
        set(h0,'Visible','off')
    end


s2 = 0;
    function callbackOverlayClasses(~, ~)
        h = findobj(gcf,'type','line');
        if(s2==1)
            for n = 1:length(h)
                set(h(n),'Visible','off')
            end
            s2 = 0;
        else
            for l = 1:size(radioButton3,1)
                Uc = unique(T{:,choices{slct}});
                for c = 1:size(radioButton3,2)
                    if(get(radioButton3{l,c},'Value')==1)
                        set(hp{l,c},'Visible','on')
                    end
                end
            end
            s2 = 1;
        end
        set(h0,'Visible','off')
    end


s3 = 0;
    function callBG1(~, ~)
        if(s3==0)
            set(slider{k1},'Visible','off')
            set(txtbox{k1},'Visible','off')
            set(maxpos{k1},'Visible','off')
            ih = get(gca,'Children');
            J = ih(end).CData;
            ih(end).CData = 255*ones(size(I1{1},1),size(I1{1},2),3,'uint8');
            set(cb,'Visible','off')
            s3 = 1;
        else
            ih = get(gca,'Children');
            ih(end).CData = J;
            if(m1==2)
                set(slider{k1},'Visible','on')
                set(txtbox{k1},'Visible','on')
                set(maxpos{k1},'Visible','on')
                set(cb,'Visible','on')
            end
            s3 = 0;
        end
    end

s4 = 0;
    function callBG2(~, ~)
        if(s4==0)
            set(slider{k1},'Visible','off')
            set(txtbox{k1},'Visible','off')
            set(maxpos{k1},'Visible','off')
            ih = get(gca,'Children');
            J = ih(end).CData;
            ih(end).CData = zeros(size(I1{1},1),size(I1{1},2),3,'uint8');
            set(cb,'Visible','off')
            s4 = 1;
        else
            ih = get(gca,'Children');
            ih(end).CData = J;
            if(m1==2)
                set(slider{k1},'Visible','on')
                set(txtbox{k1},'Visible','on')
                set(maxpos{k1},'Visible','on')
                set(cb,'Visible','on')
            end
            s4 = 0;
        end
    end

    function user_edit(source, ~)
        h = findobj(gcf,'type','line');
        NodeSize = str2double(source.String);
        for n = 1:length(h)
            set(h(n),'MarkerSize',NodeSize)
        end
    end

h5 = {};
s5 = 0;
    function callbackOverlayGraph(~, ~)
        if(s5==1)
            set(h5,'Visible','off')
            s5 = 0;
        else
            X = G.Nodes.X(unique(G.Edges.EndNodes,'row'))';
            Y = G.Nodes.Y(unique(G.Edges.EndNodes,'row'))';
            ax = axis;
            Jc = sum(X>ax(1)&X<ax(2)&Y>ax(3)&Y<ax(4),1)>0;
            X = X(:,Jc);
            Y = Y(:,Jc);
            hold on,h5 = plot(X,Y,'Color','w');
            s5 = 1;
        end
    end



slct = 1;
    function callPopUp(~, ~)
        slct = get(popUpList,'Value');
        for l = 1:length(choices)
            Uc = unique(T{:,choices{l}});
            if(l==slct)
                for c = 1:length(Uc)
                    set(button3{l,c},'Visible','on')
                    set(radioButton3{l,c},'Visible','on')
                    if(get(radioButton3{l,c},'Value')==1)
                        set(rectanColor3{l,c},'Visible','on')
                    end
                end
            else
                for c = 1:length(Uc)
                    set(button3{l,c},'Visible','off')
                    set(radioButton3{l,c},'Visible','off')
                    set(rectanColor3{l,c},'Visible','off')
                end
            end
        end
        
    end







%% If Gray-Level images exist
if(~isempty(I1))
    set(overlayButton,'Visible','on')
    for k = 1:length(I1)
        set(button2{k},'Visible','on')
        set(radioButton{k},'Visible','on','Value',0)
    end
    set(slider{k1},'Visible','on')
    set(txtbox{k1},'Visible','on')
    set(maxpos{k1},'Visible','on')
end



%% If RGB images exist
if(~isempty(I3))
    set(ButtonMode1,'Visible','on')
    set(ButtonMode2,'Visible','on')
end


%% If Nuclei-mask exist
if(~isempty(E))
    set(overlayNucleiButton,'Visible','on')
end


%% If Membrane-mask exist
if(~isempty(M))
    set(overlayMembraneButton,'Visible','on')
end


%% If Graph exist
if(~isempty(G))
    set(overlayGraphButton,'Visible','on')
end








end














%%
function [cmin,cmax,cval] = get_intensity_range(I)

cmin = cell(length(I),1);
cmax = cell(length(I),1);
cval = cell(length(I),1);
for k = 1:length(I)
    
    cval{k} = double(max(I{k}(:)));
    %cval{k} = double(quantile(I{k}(:),0.999));
    
    if(isa(I{k},'uint8'))
        cmin{k} = 0;
        cmax{k} = 255;
        
    elseif(isa(I{k},'uint16'))
        cmin{k} = 0;
        cmax{k} = 65535;
        
    elseif(isa(I{k},'double'))
        cmin{k} = min(I{k}(:));
        cmax{k} = 65535;
    end
    
end

end









%%
function a = imageButtonOrganizer(mrk)

if(length(mrk)<32)
    a = [25 23 12];
elseif(length(mrk)<38)
    a = [22 21 10];
elseif(length(mrk)<45)
    a = [18 18 8];
else
    a = [15 14 7];
end


end









%%
function [pn,ss] = nodeButtonOrganizer(Uc)

if(length(Uc)<32)
    b = [25 23 10 150];
elseif(length(Uc)<38)
    b = [22 21 10 150];
elseif(length(Uc)<45)
    b = [18 18 8 150];
elseif(length(Uc)<75)
    b = [15 14 7 150];
else
    b = [15 14 7 30];
end

x = 5; t = 1;
pn = cell(length(Uc),3);
for c = 1:length(Uc)
    if(c==51); x = b(4)+40; t = 1; end
    if(c==101); x = b(4)+80; t = 1; end
    pn{c,1} = [x         870-t*b(1) b(4) b(2)];
    pn{c,2} = [x+b(4)+2  870-t*b(1)  15  b(2)];
    pn{c,3} = [x+b(4)+19 870-t*b(1)  15  b(2)];
    t = t+1;
end

ss = b(3);

end




























