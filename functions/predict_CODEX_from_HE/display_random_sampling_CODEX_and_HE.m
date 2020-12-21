function display_random_sampling_CODEX_and_HE(Xn,X3n,Xn_pred)

r = randperm(size(Xn,4),min([32 size(Xn,4)]));




figure('Position',[1 41 1920 963],'Color','w')

k = 1;
for x = 1:4
    for y = 1:8
        if(k<=size(Xn,4))
            axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
            Ia = Xn(:,:,[3 2 1],r(k));
            Ia(:,:,1) = imadjust(Ia(:,:,1),[0 0.8]);
            Ia(:,:,2) = imadjust(Ia(:,:,2),[0 0.8]);
            Ia(:,:,3) = imadjust(Ia(:,:,3),[0 0.9]);
            imshow(Ia);
            %             imshow(Xn(:,:,[3 2 1],r(k)));
            k = k+1;
        end
    end
end

annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String','random','FontSize',44,...
    'FontWeight','bold','EdgeColor','none','Color',[0 1 0])





figure('Position',[1 41 1920 963],'Color','w')

k = 1;
for x = 1:4
    for y = 1:8
        if(k<=size(X3n,4))
            axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
            imshow(X3n(:,:,:,r(k)));
            k = k+1;
        end
    end
end

annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String','random','FontSize',44,...
    'FontWeight','bold','EdgeColor','none','Color',[0 1 0])



if(nargin==3)
    
    figure('Position',[1 41 1920 963],'Color','w')
    
    k = 1;
    for x = 1:4
        for y = 1:8
            if(k<=size(Xn_pred,4))
                axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
                Ia = Xn_pred(:,:,[3 2 1],r(k));
                Ia(:,:,1) = imadjust(Ia(:,:,1),[0 0.4]);
                Ia(:,:,2) = imadjust(Ia(:,:,2),[0 0.8]);
                Ia(:,:,3) = imadjust(Ia(:,:,3),[0 0.9]);
                imshow(Ia);
                k = k+1;
            end
        end
    end
    
    annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String','random','FontSize',44,...
        'FontWeight','bold','EdgeColor','none','Color',[0 1 0])
    
end




end










