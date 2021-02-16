function [C3,Ic] = get_new_overlap_correlations(Expr_Info,r,SI,I1,I2r,x2,y2,C3,Ic)

Nx = Expr_Info.regions{r,'Nx'};
Ny = Expr_Info.regions{r,'Ny'};
W = Expr_Info.tileWidth_px;
H = Expr_Info.tileHeight_px;
w = ceil(Expr_Info.tileWidth_px*(1-Expr_Info.tileOverlap));
h = ceil(Expr_Info.tileHeight_px*(1-Expr_Info.tileOverlap));
Dw = W - w;
Dh = H - h;

rs = 5;
for n = 1:size(SI.neighbors{x2,y2},1)
    
    x3 = SI.neighbors{x2,y2}(n,1);
    y3 = SI.neighbors{x2,y2}(n,2);
    
    m = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));
    m(1+(x2-1)*(rs+3):rs+(x2-1)*(rs+3),1+(y2-1)*(rs+3):rs+(y2-1)*(rs+3)) = 1;
    m(1+(x3-1)*(rs+3):rs+(x3-1)*(rs+3),1+(y3-1)*(rs+3):rs+(y3-1)*(rs+3)) = 1;
    m = (imclose(m,strel('disk',3))-m-imdilate(m,strel('disk',1)))>0;
    
    if(x3<x2)
        O1 = I1(1:Dh,:);
        O2r = I2r(1:Dh,:);
        
    elseif(x3>x2)
        O1 = I1(end-Dh+1:end,:);
        O2r = I2r(end-Dh+1:end,:);
        
    elseif(y3<y2)
        O1 = I1(:,1:Dw);
        O2r = I2r(:,1:Dw);
        
    elseif(y3>y2)
        O1 = I1(:,end-Dw+1:end);
        O2r = I2r(:,end-Dw+1:end);
        
    end
    
    Jp = O1~=0&O2r~=0;
    C3(m) = corr2(O1(Jp),O2r(Jp));
    C3(isnan(C3)) = 0;
    
end





if(size(SI.tile1,1)==numel(SI.neighbors)-1) % last tile
    
    rs = 5;
    C3(C3<0) = 0.001;
    
    hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');imagesc(C3),axis tight equal,axis off
    title('stitching','FontSize',36)
    clr = flipud(colorGradient([1 0 0],[0 0 1],1000));clr(1,:) = [1 1 1];colormap(clr)
    cb = colorbar('FontSize',14,'FontWeight','bold'); cb.Label.String = 'correlation';caxis([0 1])
    for x2 = 1:Nx
        for y2 = 1:Ny
            a = [1+(x2-1)*(rs+3)-0.5 rs+(x2-1)*(rs+3)+0.5 rs+(x2-1)*(rs+3)+0.5 1+(x2-1)*(rs+3)-0.5];
            b = [1+(y2-1)*(rs+3)-0.5 1+(y2-1)*(rs+3)-0.5 rs+(y2-1)*(rs+3)+0.5 rs+(y2-1)*(rs+3)+0.5];
            hold on,patch(b,a,[.9 .9 .9])
            text((b(1)+b(3))/2,(a(1)+a(2))/2,['(',num2str(x2),',',num2str(y2),')'],'HorizontalAlignment','center','FontWeight','bold')
        end
    end
    Ic{3} = getframe(hf); Ic{3} = Ic{3}.cdata;
    close(hf)
    
end




end











