function display_random_sampling(Xn)

r = randperm(size(Xn,4),min([32 size(Xn,4)]));

figure('Position',[1 41 1920 963],'Color','w')

k = 1;
for x = 1:4
    for y = 1:8
        if(k<=size(Xn,4))
            axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
            imshow(Xn(:,:,:,r(k)));
            k = k+1;
        end
    end
end

annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String','random','FontSize',44,...
        'FontWeight','bold','EdgeColor','none','Color',[0 1 0])
    
    
end