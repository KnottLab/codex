function [J,M,V,x0,y0,mask] = stitching_initialization(I,CODEXobj,stitching_info)

W = CODEXobj.Width;
w = CODEXobj.width;
D = W - w;


disp('Initializing stitching algorithm')

if(isempty(stitching_info))
    [mask,x0,y0] = findStartingTile(CODEXobj,I);
else
    x0 = stitching_info.tile1(1,1);
    y0 = stitching_info.tile1(1,2);
	mask = zeros(CODEXobj.Nx,CODEXobj.Ny);
    mask(x0,y0) = 1;
end

J = zeros(CODEXobj.Nx*w+D,CODEXobj.Ny*w+D,'uint16');
M = zeros(CODEXobj.Nx*w+D,CODEXobj.Ny*w+D,'uint8');


I0 = I(1+(x0-1)*W:x0*W,1+(y0-1)*W:y0*W);

J(1+(x0-1)*w:x0*w+D,1+(y0-1)*w:y0*w+D) = I0+1;
M(1+(x0-1)*w:x0*w+D,1+(y0-1)*w:y0*w+D) = ones(size(I0),'uint16');
V{x0,y0} = [0 0];



end