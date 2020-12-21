function [I3sr,Lsr,Iref] = align_HE_to_CODEX_WSI(I3s,Ls,CODEXobj)


% Read Reference DAPI
Iref = load_CODEX_images(CODEXobj,{'DAPI'},'1_processed');
Iref = im2uint8(Iref{1});
Iref = imadjust(Iref);


% Align HE slide to DAPI slide
I3sr = imresize(I3s,CODEXobj.HE.resolution/CODEXobj.resolution);

BR = rgb2blueratio(I3sr);
BR = medfilt2(BR,[7 7]);
BR = imclose(BR,strel('disk',3));
BR = imdilate(BR,strel('disk',2));
BR = imadjust(BR);

tf = imregcorr(BR,Iref,'translation');
I3sr = imwarp(I3sr,tf,'OutputView',imref2d(size(Iref)));


% Mask for Original Tile locations
% L2 = zeros(size(I3s,1),size(I3s,2),1,'uint16');
% Dx = round(size(I3s,1)/CODEXobj.HE.Nx);
% Dy = round(size(I3s,2)/CODEXobj.HE.Ny);
% t = 1;
% for x = 1:CODEXobj.HE.Nx
%     for y = 1:CODEXobj.HE.Ny
%         
%         dx = 1+(x-1)*Dx:min(x*Dx,size(L2,1));
%         dy = 1+(y-1)*Dy:min(y*Dy,size(L2,2));
%         
%         L2(dx,dy) = t;
%         t = t+1;
%     end
% end
% L2r = imresize(L2,CODEXobj.HE.resolution/CODEXobj.resolution,'nearest');
% Lsr = imwarp(L2r,tf,'OutputView',imref2d(size(Iref)));

Ls = imresize(Ls,CODEXobj.HE.resolution/CODEXobj.resolution,'nearest');
Lsr = imwarp(Ls,tf,'OutputView',imref2d(size(Iref)));


end

















