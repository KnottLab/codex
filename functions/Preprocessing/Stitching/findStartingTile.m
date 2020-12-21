function [mask,x0,y0] = findStartingTile(CODEXobj,I)

% close all

% Get the tile in the center of the tissue

I = imresize(I,0.25);
I = imfilter(I,fspecial('average',20));

bw = imbinarize(I);
bw = imclose(bw,strel('disk',30));
bw = imopen(bw,strel('disk',30));

bw = bwlabel(bw);
stats = regionprops(bw,'area','centroid'); %#ok<MRPBW>
[~,ps] = sort(cat(1,stats.Area),'descend');

P = cat(1,stats.Centroid);
P = P(ps(1),:)*4;
P = ceil(P/CODEXobj.Width);

x0 = P(2);
y0 = P(1);



% initialize mask
mask = zeros(CODEXobj.Nx,CODEXobj.Ny);
mask(x0,y0) = 1;




disp(['Tissue Center Tile: x = ',num2str(x0),' , y = ',num2str(y0)])

end






