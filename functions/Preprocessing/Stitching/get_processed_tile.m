function [x1,y1] = get_processed_tile(mask,x0,y0)


% Get a tile on the boundry of the processed area
[x1,y1] = find(imdilate(mask==0,strel('disk',1))&mask==1);


% Make sure the processed tile is the closest to the initial point of the processing
[~,r] = min(pdist2([x1 y1],[x0 y0]));
x1 = x1(r);
y1 = y1(r);


end