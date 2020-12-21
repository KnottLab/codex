function BR = rgb2blueratio(I)

I = double(I);
R = I(:,:,1);
G = I(:,:,2);
B = I(:,:,3);


%% Blue Ratio
BR = (255*B)./((1+R+G).*(1+R+G+B));
%figure,imshow(BR)
%BR(1,1) = 255;
%BR(BR>5) = 5;

if(sum(sum((R>253).*(G>253).*(B>253)))<0.75*numel(B))
   BR = uint8(255*imadjust(BR));
else
   BR = uint8(BR+30);
end
%figure,imshow(BR)


end