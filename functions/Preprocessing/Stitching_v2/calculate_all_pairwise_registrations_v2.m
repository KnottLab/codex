function SI = calculate_all_pairwise_registrations_v2(CODEXobj,I,r)

disp('Calculating All Pair-wise Registrations ...')

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

k = 1;
for x1 = 1:Nx
    for y1 = 1:Ny
        if(isempty(CODEXobj.real_tiles{x1,y1}))
            continue
        end
        M = zeros(Nx,Ny);
        M(x1,y1) = 1;
        M = imdilate(M,strel('disk',1))-M;
        [x2,y2] = find(M==1);
        SI.neighbors{x1,y1} = [x2 y2];
        
        for n = 1:size(SI.neighbors{x1,y1},1)
            if(isempty(CODEXobj.real_tiles{x2(n),y2(n)}))
                continue
            end
            disp(['Overlap Registration:  X=',num2str(x1),' Y=',num2str(y1),' | X=',num2str(x2(n)),' Y=',num2str(y2(n)),' | ',num2str(round(100*k/(Nx*Ny))),'%'])
            SI.reg_info{x1,y1,n} = get_registration_transform_v2(x1,y1,x2(n),y2(n),I,H,W,Dh,Dw);
        end
        
        k = k+1;
        
    end
end





end












