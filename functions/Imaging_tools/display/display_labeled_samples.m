function display_labeled_samples(Xn,CL)

[Ucl,~,Zcl] = unique(CL);

for cl = 1:length(Ucl)
    
    Jcl = find(Zcl==cl);
    Jcl = Jcl(randperm(length(Jcl),min([32 length(Jcl)])));
    
    figure('Position',[1 41 1920 963],'Color','w')
    k = 1;
    for x = 1:4
        for y = 1:8
            if(k<=length(Jcl))
                axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
                imshow(Xn(:,:,1:3,Jcl(k)));
            end
            k = k+1;
        end
    end
    
    annotation('textbox','Position',[0.01 0.97 0.3 0.04],'String',Ucl{cl},'FontSize',44,...
        'FontWeight','bold','EdgeColor','none','Color',[0 1 0])
    
    
end


end


