function [J,M,mask,V,C3] = stitch_first_tile_v2(CODEXobj,r,I,SI,new_tf)


% Nx = CODEXobj.regions{r,'Nx'};
% Ny = CODEXobj.regions{r,'Ny'};
% W = CODEXobj.tileWidth_px;
% H = CODEXobj.tileHeight_px;
% w = ceil(CODEXobj.tileWidth_px*(1-CODEXobj.tileOverlap));
% h = ceil(CODEXobj.tileHeight_px*(1-CODEXobj.tileOverlap));
% Dw = W - w;
% Dh = H - h;

Nx = CODEXobj.RNy;
Ny = CODEXobj.RNx;
W = CODEXobj.Width;
H = W;
w = ceil(CODEXobj.Width*(1-CODEXobj.Ox));
h = ceil(CODEXobj.Width*(1-CODEXobj.Ox));
Dw = W - w;
Dh = H - h;


disp('Initializing stitching algorithm')



%%
if(new_tf)
    [x0,y0] = find_first_tile_v2(CODEXobj,SI,Nx,Ny);
else
    x0 = SI.tile1(1,1);
    y0 = SI.tile1(1,2);
end



%%
I0 = I(1+(x0-1)*H:x0*H,1+(y0-1)*W:y0*W);

J = zeros(Nx*h+Dh,Ny*w+Dw,'uint16');
M = zeros(Nx*h+Dh,Ny*w+Dw,'uint8');

J(1+(x0-1)*h:x0*h+Dh,1+(y0-1)*w:y0*w+Dw) = I0;
M(1+(x0-1)*h:x0*h+Dh,1+(y0-1)*w:y0*w+Dw) = ones(size(I0),'uint16');


%%
mask = zeros(Nx,Ny);
mask(x0,y0) = 1;


%%
V{x0,y0} = [0 0];


%% For overlap correlations QC
rs = 5;
C3 = zeros(rs*Nx+3*(Nx-1),rs*Ny+3*(Ny-1));


end















function [x0,y0] = find_first_tile_v2(CODEXobj,SI,Nx,Ny)

% the tile with the highest correlation

disp('Finding Starting Tile ...')


maxCorr = 0;
for x1 = 2:Nx-1
    for y1 = 2:Ny-1
        if(isempty(CODEXobj.real_tiles{x1,y1}))
            continue
        end
        avrgCorr = [];
        for n = 1:size(SI.neighbors{x1,y1},1)
            if(isempty(SI.reg_info{x1,y1,n}))
                continue
            end
            avrgCorr = [avrgCorr SI.reg_info{x1,y1,n}.corr2];         
        end
        avrgCorr = mean(avrgCorr);
        
        if(avrgCorr>maxCorr)
            maxCorr = avrgCorr;
            x0 = x1;
            y0 = y1;
        end
        
    end
end


disp(['Initial Tile: x = ',num2str(x0),' , y = ',num2str(y0)])


end












