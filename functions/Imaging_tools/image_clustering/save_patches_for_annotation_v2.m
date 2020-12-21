function save_patches_for_annotation_v2(I,Xn,T,CL,FT,prefix,save_dir)

mkdir([save_dir,'/1_tables'])
mkdir([save_dir,'/2_images'])

Tt = [T CL];
Tt = get_cells_closest_to_centroid(Tt,FT,CL,32);

[Ucl,~,Zcl] = unique(Tt.cluster);
for cl = 1:length(Ucl)
    
    [~,Jcl] = intersect(T.cell_ID,Tt.cell_ID(Zcl==cl),'stable');
    
    figure('Position',[1 41 1920 963],'Color','w','Visible','off')
    k = 1;
    for x = 1:4
        for y = 8:-1:1
            if(k<=length(Jcl))
                axes('Position',[0.005+(y-1)*0.124 0.76-(x-1)*0.25 0.12 0.24])
                imshow(imrotate(Xn(:,:,:,Jcl(k)),-90));
            end
            k = k+1;
        end
    end
    fr = getframe(gcf); fr = fr.cdata; fr = imrotate(fr,90);
    %close all
    
    figure('Position',[1 41 1920 963],'Color','w')
    imagesc(I),axis equal tight
    set(gca,'Position',[0.01 0.024 0.52 0.96])
    %axis off
    %set(gca,'TickDir','out')
    hold on,plot(Tt.X(Zcl==cl),Tt.Y(Zcl==cl),'sg','MarkerSize',25,'LineWidth',1.5)
    %hold on,plot(Tt.X(Zcl==cl),Tt.Y(Zcl==cl),'og','MarkerSize',20,'LineWidth',1.5)
    %hold on,plot(Tt.X(Zcl==cl),Tt.Y(Zcl==cl),'.g','MarkerSize',6)
    
    axes('Position',[0.55 0.024 0.35 0.96])
    imagesc(fr),axis equal tight
    axis off
    
    writetable(Tt(Zcl==cl,:),[save_dir,'/1_tables/',prefix,'_class_',num2str(cl),'.txt'],'Delimiter','\t')
    saveas(gcf,[save_dir,'/2_images/',prefix,'_class_',num2str(cl),'.jpg'],'jpg')
    
end





