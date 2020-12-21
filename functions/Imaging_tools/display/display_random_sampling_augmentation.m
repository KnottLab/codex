function display_random_sampling_augmentation(Xn,T,augm_type)

r = randperm(size(Xn,4),min([32 size(Xn,4)]));

Us = T.cell_ID(r);

N = max(T{:,augm_type});


for a = 1:N
    
    figure('Position',[1 41 1920 963],'Color','w')
    
    k = 1;
    for x = 1:4
        for y = 1:8
            if(k<=size(Xn,4))
                axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
                j = find(strcmp(T.cell_ID,Us{k})&T{:,augm_type}==a);
                imshow(Xn(:,:,:,j(1)));
                k = k+1;
            end
        end
    end
    
    annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String','random','FontSize',44,...
        'FontWeight','bold','EdgeColor','none','Color',[0 1 0])
    
end



end