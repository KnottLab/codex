function Xn = add_vignette(Xn)

M = false(size(Xn,1),size(Xn,2));

M(ceil(size(Xn,1)/2),ceil(size(Xn,1)/2)) = true;

M = imdilate(M,strel('disk',floor(size(Xn,1)/2),8));

% figure,imagesc(M),axis tight equal

M = repmat(M,[1 1 size(Xn,3) size(Xn,4)]);
% size(M)

Xn(~M) = 0;

end






