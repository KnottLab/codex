function I = correct_Leica_corners(CODEXobj,I,r,cl,ch)

a = 0.02;

% Nx = CODEXobj.regions{r,'Nx'};
% Ny = CODEXobj.regions{r,'Ny'};
% W = CODEXobj.tileWidth_px;
% H = CODEXobj.tileHeight_px;

Nx = CODEXobj.RNy;
Ny = CODEXobj.RNx;
W = CODEXobj.Width;
H = W;

[xi,yi] = meshgrid(1:W,1:H);
xi = xi-W/2;
yi = yi-H/2;
[theta,rho] = cart2pol(xi,yi);

rmax = max(rho(:));
s1 = rho + rho.^3*(a/rmax.^2);

[ui,vi] = pol2cart(theta,s1);
ui = ui+W/2;
vi = vi+H/2;

ifcn = @(c) [ui(:) vi(:)];
tform = geometricTransform2d(ifcn);


k = 1;
for x = 1:Nx
    for y = 1:Ny
        if(isempty(CODEXobj.real_tiles{x,y}))
            continue
        end
        disp(['Leica corners correction:  reg',num2strn(r,3),'  :  ',CODEXobj.markerNames{cl,ch},'  : CL=',num2str(cl),' CH=',num2str(ch),'  :  X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(Nx*Ny))),'%'])

        It = I(1+(x-1)*H:x*H,1+(y-1)*W:y*W);
        I(1+(x-1)*H:x*H,1+(y-1)*W:y*W) = imwarp(It,tform,'OutputView',imref2d(size(It)));
        
        k = k+1;
        
    end
end



end

















