function [x2,y2,mask] = get_unprocessed_tile(mask,x1,y1,x0,y0)


% Get unproessed tile neighbor of (x1,y1)
M = zeros(size(mask));
M(mask==1) = -1;
M(x1,y1) = 1;
M = imdilate(M,strel('disk',1))+M;
[x2,y2] = find(M==1);


% Make sure the unproessed tile is the closest to the initial point of the processing
[~,r] = min(pdist2([x2 y2],[x0 y0]));
% r = randperm(length(x2),1);
x2 = x2(r);
y2 = y2(r);

% For Visualization
% figure,imagesc(M),axis equal tight
% M(x2,y2) = 3;
% figure,imagesc(M),axis equal tight


% if(x2>x1)
%     orientation = 'south';
% elseif(x2<x1)
%     orientation = 'north';
% elseif(y2>y1)
%     orientation = 'east';
% elseif(y2<y1)
%     orientation = 'west';
% end
    

mask(x2,y2) = 1;

end