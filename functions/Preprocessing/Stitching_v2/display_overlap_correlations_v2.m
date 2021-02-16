function Ic = display_overlap_correlations_v2(Expr_Info,SI,r)


Nx = Expr_Info.regions{r,'Nx'};
Ny = Expr_Info.regions{r,'Ny'};



rs = 5;
C1 = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));
C2 = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));
for x1 = 1:Nx
    for y1 = 1:Ny

        for n = 1:size(SI.neighbors{x1,y1},1)
            
            x2 = SI.neighbors{x1,y1}(n,1);
            y2 = SI.neighbors{x1,y1}(n,2);
            
            m = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));
            m(1+(x1-1)*(rs+3):rs+(x1-1)*(rs+3),1+(y1-1)*(rs+3):rs+(y1-1)*(rs+3)) = 1;
            m(1+(x2-1)*(rs+3):rs+(x2-1)*(rs+3),1+(y2-1)*(rs+3):rs+(y2-1)*(rs+3)) = 1;
            m = (imclose(m,strel('disk',3))-m-imdilate(m,strel('disk',1)))>0;
            
            C1(m) = SI.reg_info{x1,y1,n}.corr1;
            C2(m) = SI.reg_info{x1,y1,n}.corr2;
            
        end
        
    end
end
C1(C1<0) = 0.001;
C2(C2<0) = 0.001;



hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');imagesc(C1),axis tight equal,axis off
title('before registration','FontSize',36)
clr = flipud(colorGradient([1 0 0],[0 0 1],1000));clr(1,:) = [1 1 1];colormap(clr)
cb = colorbar('FontSize',14,'FontWeight','bold'); cb.Label.String = 'correlation';caxis([0 1])
for x1 = 1:Nx
    for y1 = 1:Ny
        a = [1+(x1-1)*(rs+3)-0.5 rs+(x1-1)*(rs+3)+0.5 rs+(x1-1)*(rs+3)+0.5 1+(x1-1)*(rs+3)-0.5];
        b = [1+(y1-1)*(rs+3)-0.5 1+(y1-1)*(rs+3)-0.5 rs+(y1-1)*(rs+3)+0.5 rs+(y1-1)*(rs+3)+0.5];
        hold on,patch(b,a,[.9 .9 .9])
        text((b(1)+b(3))/2,(a(1)+a(2))/2,['(',num2str(x1),',',num2str(y1),')'],'HorizontalAlignment','center','FontWeight','bold')
    end
end
Ic{1} = getframe(hf); Ic{1} = Ic{1}.cdata;
close(hf)

hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');imagesc(C2),axis tight equal,axis off
title('pair-wise registration','FontSize',36)
clr = flipud(colorGradient([1 0 0],[0 0 1],1000));clr(1,:) = [1 1 1];colormap(clr)
cb = colorbar('FontSize',14,'FontWeight','bold'); cb.Label.String = 'correlation';caxis([0 1])
for x1 = 1:Nx
    for y1 = 1:Ny
        a = [1+(x1-1)*(rs+3)-0.5 rs+(x1-1)*(rs+3)+0.5 rs+(x1-1)*(rs+3)+0.5 1+(x1-1)*(rs+3)-0.5];
        b = [1+(y1-1)*(rs+3)-0.5 1+(y1-1)*(rs+3)-0.5 rs+(y1-1)*(rs+3)+0.5 rs+(y1-1)*(rs+3)+0.5];
        hold on,patch(b,a,[.9 .9 .9])
        text((b(1)+b(3))/2,(a(1)+a(2))/2,['(',num2str(x1),',',num2str(y1),')'],'HorizontalAlignment','center','FontWeight','bold')
    end
end
Ic{2} = getframe(hf); Ic{2} = Ic{2}.cdata;
close(hf)




end









