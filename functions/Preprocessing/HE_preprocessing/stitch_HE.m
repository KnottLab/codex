function [I3s,Ls] = stitch_HE(I3,CODEXobj)

Lt = get_tile_mask(I3,CODEXobj);


% Initialization
W = CODEXobj.HE.Width;
w = CODEXobj.HE.width;
Dy = W - w;

H = CODEXobj.HE.Height;
h = CODEXobj.HE.height;
Dx = H - h;

[mask,x0,y0] = findStartingTile_HandE(I3,W,CODEXobj.HE.Nx,CODEXobj.HE.Ny);

L = zeros(CODEXobj.HE.Nx*h+Dx,CODEXobj.HE.Ny*w+Dy,'uint8');
J = zeros(CODEXobj.HE.Nx*h+Dx,CODEXobj.HE.Ny*w+Dy,3,'uint8');
M = zeros(CODEXobj.HE.Nx*h+Dx,CODEXobj.HE.Ny*w+Dy,'uint8');

I0 = I3(1+(x0-1)*H:x0*H,1+(y0-1)*W:y0*W,:);

L(1+(x0-1)*h:x0*h+Dx,1+(y0-1)*w:y0*w+Dy,:) = Lt(1+(x0-1)*H:x0*H,1+(y0-1)*W:y0*W,:);
J(1+(x0-1)*h:x0*h+Dx,1+(y0-1)*w:y0*w+Dy,:) = I0+1;
M(1+(x0-1)*h:x0*h+Dx,1+(y0-1)*w:y0*w+Dy) = ones(size(I0,1),size(I0,2),'uint16');
V{x0,y0} = [0 0];


% Stitching
verbose = 0;

k = 1;
while(sum(mask(:)==0)>0)
    
    disp(['stitching: H&E : ',num2str(round(100*(numel(mask)-sum(mask(:)==0))/numel(mask))),'%'])
    
    [x1,y1] = get_processed_tile_HandE(mask,x0,y0);
    [x2,y2,mask] = get_unprocessed_tile_HandE(mask,x1,y1,x0,y0);
    
    I32 = I3(1+(x2-1)*H:x2*H,1+(y2-1)*W:y2*W,:)+1;
    L2 = Lt(1+(x2-1)*H:x2*H,1+(y2-1)*W:y2*W,:);
    
    [tform,V,reg_info] = get_registration_transform_HandE(x1,y1,x2,y2,I3,I32,W,H,Dx,Dy,V);
    
    [L,~,~] = update_stitching_HandE(L,M,L2,V,Dx,Dy,w,h,x2,y2,tform,reg_info);
    [J,M,I32r] = update_stitching_HandE(J,M,I32,V,Dx,Dy,w,h,x2,y2,tform,reg_info);
    
    if(verbose==1)
        display_stitched_HandE(J,CODEXobj.HE.Nx,CODEXobj.HE.Ny,I3(1+(x1(1)-1)*H:x1(1)*H,1+(y1(1)-1)*W:y1(1)*W,:),I32,I32r,reg_info,tform,H,h,W,w,Dx,Dy)
    end
    
    k = k+1;
    
end

J(repmat(M==0,[1 1 3])) = 255;

I3s = J;
Ls = L;


end















function [mask,x0,y0] = findStartingTile_HandE(I3,Width,Nx,Ny)

% close all

% Get the tile in the center of the tissue
I3 = rgb2gray(I3);

I3 = imresize(I3,0.25);
I3 = imfilter(I3,fspecial('average',20));

bw = ~imbinarize(I3);
bw = imclose(bw,strel('disk',30));
bw = imopen(bw,strel('disk',30));

bw = bwlabel(bw);
stats = regionprops(bw,'area','centroid'); %#ok<MRPBW>
[~,ps] = sort(cat(1,stats.Area),'descend');

P = cat(1,stats.Centroid);
P = P(ps(1),:)*4;
P = ceil(P/Width);

x0 = P(2);
y0 = P(1);



% initialize mask
mask = zeros(Nx,Ny);
mask(x0,y0) = 1;


disp(['Tissue Center Tile: x = ',num2str(x0),' , y = ',num2str(y0)])

end











function [x1,y1] = get_processed_tile_HandE(mask,x0,y0)


% Get a tile on the boundry of the processed area
[x1,y1] = find(imdilate(mask==0,strel('disk',1))&mask==1);


% Make sure the processed tile is the closest to the initial point of the processing
[~,r] = min(pdist2([x1 y1],[x0 y0]));
x1 = x1(r);
y1 = y1(r);


end














function [x2,y2,mask] = get_unprocessed_tile_HandE(mask,x1,y1,x0,y0)


% Get unprocessed tile neighbor of (x1,y1)
M = zeros(size(mask));
M(mask==1) = -1;
M(x1,y1) = 1;
M = imdilate(M,strel('disk',1))+M;
[x2,y2] = find(M==1);


% Make sure the unprocessed tile is the closest to the initial point of the processing
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
















function [tform,V,reg_info] = get_registration_transform_HandE(x1,y1,x2,y2,I3,I32,W,H,Dx,Dy,V)

cutoff = 700; % Do registration only if average intensity in overlap < cutoff


tf = {};
orientation = {};
tform = affine2d(eye(3));


for i = 1:length(x1)
    
    tf{i} = tform;
    I31 = I3(1+(x1(i)-1)*H:x1(i)*H,1+(y1(i)-1)*W:y1(i)*W,:);
    
    if(x2>x1(i))
        orientation{i} = 'south';
        O1 = I31(end-Dx+1:end,:,:);
        O2 = I32(1:Dx,:,:);
        mu1 = mean2(O1);
        if(mu1<cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
%         mn1 = mean2(O1(end-20:end,:));
%         mn2 = mean2(O2r(end-20:end,:));
        
        
    elseif(x2<x1(i))
        orientation{i} = 'north';
        O1 = I31(1:Dx,:,:);
        O2 = I32(end-Dx+1:end,:,:);
        mu1 = mean2(O1);
        if(mu1<cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
%         mn1 = mean2(O1(1:20,:));
%         mn2 = mean2(O2r(1:20,:));
        
        
    elseif(y2>y1(i))
        orientation{i} = 'east';
        O1 = I31(:,end-Dy+1:end,:);
        O2 = I32(:,1:Dy,:);
        mu1 = mean2(O1);
        if(mu1<cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
%         mn1 = mean2(O1(:,end-20:end));
%         mn2 = mean2(O2r(:,end-20:end));
        
        
    elseif(y2<y1(i))
        orientation{i} = 'west';
        O1 = I31(:,1:Dy,:);
        O2 = I32(:,end-Dy+1:end,:);
        mu1 = mean2(O1);
        if(mu1<cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
%         mn1 = mean2(O1(:,1:20));
%         mn2 = mean2(O2r(:,1:20));
        
        
    end
    
end


if(length(x1)==1)
    tform = tf{1};
elseif(length(x1)==2)
    tform.T = (tf{1}.T+tf{2}.T)/2;
end
tform.T = round(tform.T);

tform.T(3,1:2) = tform.T(3,1:2) + V{x1,y1};
V{x2,y2} = tform.T(3,1:2);


reg_info.tf = tf;
reg_info.orientation = orientation;
reg_info.O1 = O1;
reg_info.O2 = O2;
reg_info.O2r = O2r;
reg_info.corr1 = corr2(rgb2gray(O1),rgb2gray(O2));
reg_info.corr2 = corr2(rgb2gray(O1),rgb2gray(O2r));
reg_info.meanO1 = mu1;
reg_info.meanO2 = mean2(O2);
% reg_info.mn1 = mn1;
% reg_info.mn2 = mn2;



end
















function [J,M,I2r] = update_stitching_HandE(J,M,I32,V,Dx,Dy,w,h,x2,y2,tform,reg_info)


%I2r = gradientSides(I2,D,w);
I2r = imwarp(I32,tform,'OutputView',imref2d([size(I32,1) size(I32,2)]+V{x2,y2}([2 1])));

dx = 1+(x2-1)*h:x2*h+Dx+V{x2,y2}(2);
dy = 1+(y2-1)*w:y2*w+Dy+V{x2,y2}(1);

if(max(dx)>size(J,1))
    J = [J;zeros(max(dx)-size(J,1),size(J,2),size(J,3))];
    M = [M;zeros(max(dx)-size(M,1),size(M,2))];
end

if(max(dy)>size(J,2))
    J = [J zeros(size(J,1),max(dy)-size(J,2),size(J,3))];
    M = [M zeros(size(M,1),max(dy)-size(M,2))];
end


% if(reg_info.mn1<reg_info.mn2)
%     Mt = zeros(size(M),'uint8');
%     Mt(dx,dy) = 1;
%     Mt(dx,dy) = Mt(dx,dy) + uint8(I2r>0);
%     J(Mt==2) = 0;
% end


J(dx,dy,:) = J(dx,dy,:) + uint8(I2r).*uint8(J(dx,dy)==0);  
% J(dx,dy) = max(cat(3,J(dx,dy),uint16(I2r)),[],3);


if(size(I2r,3)==3)
    M(dx,dy) = M(dx,dy) + uint8(rgb2gray(I2r)>0);
elseif(size(I2r,3)==1)
    M(dx,dy) = M(dx,dy) + uint8(I2r>0);
end


end















function L = get_tile_mask(I3,CODEXobj)

L = zeros(size(I3,1),size(I3,2),1,'uint16');
t = 1;
for x = 1:CODEXobj.HE.Nx
    for y = 1:CODEXobj.HE.Ny
        dx = 1+(x-1)*CODEXobj.HE.Height:x*CODEXobj.HE.Height;
        dy = 1+(y-1)*CODEXobj.HE.Width:y*CODEXobj.HE.Width;
        L(dx,dy) = t;
        t = t+1;
    end
end
% imagescBBC(L),axis tight

end


















