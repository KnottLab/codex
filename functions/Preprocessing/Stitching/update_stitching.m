function [J,M,I2r] = update_stitching(J,M,I2,V,D,w,x2,y2,tform,reg_info)


%I2r = gradientSides(I2,D,w);
I2r = imwarp(I2,tform,'OutputView',imref2d(size(I2)+V{x2,y2}([2 1])));

dx = 1+(x2-1)*w:x2*w+D+V{x2,y2}(2);
dy = 1+(y2-1)*w:y2*w+D+V{x2,y2}(1);

if(max(dx)>size(J,1))
    J = [J;zeros(max(dx)-size(J,1),size(J,2))];
    M = [M;zeros(max(dx)-size(M,1),size(M,2))];
end

if(max(dy)>size(J,2))
    J = [J zeros(size(J,1),max(dy)-size(J,2))];
    M = [M zeros(size(M,1),max(dy)-size(M,2))];
end



if(reg_info.mn1<reg_info.mn2)
    Mt = zeros(size(M),'uint8');
    Mt(dx,dy) = 1;
    Mt(dx,dy) = Mt(dx,dy) + uint8(I2r>0);
    J(Mt==2) = 0;
end


J(dx,dy) = J(dx,dy) + uint16(I2r).*uint16(J(dx,dy)==0);  
M(dx,dy) = M(dx,dy) + uint8(I2r>0);




% J(dx,dy) = max(cat(3,J(dx,dy),uint16(I2r)),[],3);  
% M(dx,dy) = M(dx,dy) + uint8(I2r>0);




end
















