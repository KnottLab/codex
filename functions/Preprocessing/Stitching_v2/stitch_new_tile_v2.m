function [J,M,I1,I2,I2r,mask] = stitch_new_tile_v2(CODEXobj,r,I,J,M,SI,k,mask)


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

x2 = SI.tile2(k,1);
y2 = SI.tile2(k,2);


%%
I2 = I(1+(x2-1)*H:x2*H,1+(y2-1)*W:y2*W);

tform = affine2d(eye(3));
tform.T(3,1:2) = SI.V{x2,y2};

I2r = imwarp(I2,tform,'OutputView',imref2d(size(I2)+SI.V{x2,y2}([2 1])));


%%
dx = 1+(x2-1)*h:x2*h+Dh + SI.V{x2,y2}(2);
dy = 1+(y2-1)*w:y2*w+Dw + SI.V{x2,y2}(1);

if(max(dx)>size(J,1))
    J = [J;zeros(max(dx)-size(J,1),size(J,2))];
    M = [M;zeros(max(dx)-size(M,1),size(M,2))];
end

if(max(dy)>size(J,2))
    J = [J zeros(size(J,1),max(dy)-size(J,2))];
    M = [M zeros(size(M,1),max(dy)-size(M,2))];
end

I1 = J(dx,dy);


% if(mean2(reg_info.overlaps.O1)<mean2(reg_info.overlaps.O2))
%     Mt = zeros(size(M),'uint8');
%     Mt(dx,dy) = 1;
%     Mt(dx,dy) = Mt(dx,dy) + uint8(I2r>0);
%     J(Mt==2) = 0;
% end


%%
J(dx,dy) = J(dx,dy) + uint16(I2r).*uint16(J(dx,dy)==0);  
M(dx,dy) = M(dx,dy) + uint8(I2r>0);

mask(x2,y2) = 1;



end
















