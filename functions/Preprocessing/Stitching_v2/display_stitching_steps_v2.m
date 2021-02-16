function fr = display_stitching_steps_v2(Expr_Info,J,M,I1,I2,I2r,SI,k,reg_info,r,C3,mask)


Nx = Expr_Info.regions{r,'Nx'};
Ny = Expr_Info.regions{r,'Ny'};
W = Expr_Info.tileWidth_px;
H = Expr_Info.tileHeight_px;
w = ceil(Expr_Info.tileWidth_px*(1-Expr_Info.tileOverlap));
h = ceil(Expr_Info.tileHeight_px*(1-Expr_Info.tileOverlap));
Dw = W - w;
Dh = H - h;


x1 = SI.tile1(k,1);
y1 = SI.tile1(k,2);

x2 = SI.tile2(k,1);
y2 = SI.tile2(k,2);

dx1 = round((x1-1)*h:x1*h+Dh);
dy1 = round((y1-1)*w:y1*w+Dw);

dx2 = round((x2-1)*h:x2*h+Dh);
dy2 = round((y2-1)*w:y2*w+Dw);

I1 = imadjust(I1);
I2 = imadjust(I2);
I2r = imadjust(I2r);




%% Current stitched image
hf = figure('Position',[1 41 1920 963],'Color','w','Visible','off');
subplot(1,2,1),imagesc(J),axis tight equal;set(gca,'Position',[0.01 0.2 0.475 0.6])
for x = 1:Nx; hold on,plot([1 size(J,2)],[x*h x*h]+Dh,'Color',[.5 .5 .5],'LineWidth',2); end
for x = 1:Nx; hold on,plot([1 size(J,2)],[x*h x*h],'k--','LineWidth',2); end
for y = 1:Ny; hold on,plot([y*w y*w]+Dw,[1 size(J,1)],'Color',[.5 .5 .5],'LineWidth',2); end
for y = 1:Ny; hold on,plot([y*w y*w],[1 size(J,1)],'k--','LineWidth',2); end
hold on,rectangle('Position',[dy1(1) dx1(1) length(dy1) length(dx1)],'EdgeColor','r','LineWidth',2)
hold on,rectangle('Position',[dy2(1) dx2(1) length(dy2) length(dx2)],'EdgeColor','c','LineWidth',2,'LineStyle','--')




%% overlay before registration
subplot(2,4,3),imshowpair(I1,I2,'ColorChannels','red-cyan'),axis tight equal;
set(gca,'Position',[0.5 0.5 0.24 0.45]),
title(['before registration | corr = ',num2str(reg_info.corr1)],'FontSize',14)




%% overlay after registration
subplot(2,4,4),imshowpair(I1,I2r,'ColorChannels','red-cyan'),axis tight equal;
set(gca,'Position',[0.75 0.5 0.24 0.45]),
title(['after registration (',num2str(round(SI.V{x2,y2}(1))),',',num2str(round(SI.V{x2,y2}(2))),') | corr = ',num2str(reg_info.corr2)],'FontSize',14)




%% Order of tile stitching
order = zeros(Nx,Ny);
order(SI.tile1(1,1),SI.tile1(1,2)) = 1;
for k = 1:size(SI.tile2,1)
    order(SI.tile2(k,1),SI.tile2(k,2)) = k+1;
end

hp1 = subplot(2,4,8);imagesc(M),axis tight equal; axis off; ax = axis;
colormap(hp1,flipud(parula(4)))
for x = 1:size(order,1)
    for y = 1:size(order,2)
        if(order(x,y)>0)
            xt = x*h-H/2+Dh;
            yt = y*w-W/2+Dw;
            text(yt,xt,num2str(order(x,y)),'FontSize',14,'FontWeight','bold','HorizontalAlignment','center')
            
            dx = 10000*SI.V{x,y}(1)/H;
            dy = 10000*SI.V{x,y}(2)/W;
        
            hold on,quiver(yt+0.03*size(M,2),xt,dy,dx,'Color','k','LineWidth',3,'MaxHeadSize',20)
        
        end
    end
end
set(gca,'Position',[0.75 0.03 0.24 0.45])
axis(ax)
title('stitching order','FontSize',14)




%% Overlap Correlations
rs = 5;
CR = zeros(Nx,Ny);
for x1 = 1:Nx
    for y1 = 1:Ny
        
        if(mask(x1,y1)>0)
            cr = [];
            for n = 1:size(SI.neighbors{x1,y1},1)
                
                x2 = SI.neighbors{x1,y1}(n,1);
                y2 = SI.neighbors{x1,y1}(n,2);
                
                m = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));
                m(1+(x1-1)*(rs+3):rs+(x1-1)*(rs+3),1+(y1-1)*(rs+3):rs+(y1-1)*(rs+3)) = 1;
                m(1+(x2-1)*(rs+3):rs+(x2-1)*(rs+3),1+(y2-1)*(rs+3):rs+(y2-1)*(rs+3)) = 1;
                m = (imclose(m,strel('disk',3))-m-imdilate(m,strel('disk',1)))>0;
                
                cr = [cr;unique(C3(m))];
                
            end
            CR(x1,y1) = mean(cr);
        end
    end
end

hp2 = subplot(2,4,7);
imagesc(imresize(CR,round(size(M)/100),'nearest')),axis tight equal;
colormap(hp2,cbrewer('seq','Reds',100,'linear'))
for x = 1:size(CR,1)
    for y = 1:size(CR,2)
        if(CR(x,y)>0)
            xt = x*h-H/2+Dh;
            yt = y*w-W/2+Dw;
            text(yt/100,xt/100,num2str(round(100*CR(x,y))/100),'FontSize',14,'FontWeight','bold','HorizontalAlignment','center')
        end
    end
end
title('overlap correlations','FontSize',14)
set(gca,'Position',[0.5 0.03 0.24 0.45])
axis off


set(findall(hf,'-property','TickDir'),'TickDir','out')




%%
fr = getframe(hf);
fr = fr.cdata;


close(hf)



end





