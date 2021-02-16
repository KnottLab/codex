function reg_info = get_registration_transform_v2(x1,y1,x2,y2,I,H,W,Dh,Dw)


I1 = I(1+(x1-1)*H:x1*H,1+(y1-1)*W:y1*W);
I2 = I(1+(x2-1)*H:x2*H,1+(y2-1)*W:y2*W);



%% Get overlaps
if(x2>x1)
    O1 = I1(end-Dh+1:end,:);
    O2 = I2(1:Dh,:);

elseif(x2<x1)
    O1 = I1(1:Dh,:);
    O2 = I2(end-Dh+1:end,:);

elseif(y2>y1)
    O1 = I1(:,end-Dw+1:end);
    O2 = I2(:,1:Dw);

elseif(y2<y1)
    O1 = I1(:,1:Dw);
    O2 = I2(:,end-Dw+1:end);

end


% %% Sharpen overlaps
% radius = 2;
% amount = 1;
% imagescBBC(O1)
% imagescBBC(O2)
% O1 = imsharpen(O1,'Radius',radius,'Amount',amount);
% O2 = imsharpen(O2,'Radius',radius,'Amount',amount);
% imagescBBC(O1)
% imagescBBC(O2)
% return


%% Calculate registration transform
tf = imregcorr(O2,O1,'translation');
% tf = imregcorr(imadjust(O2),imadjust(O1),'translation');

% [optimizer, metric] = imregconfig('monomodal');
% % optimizer.InitialRadius = 0.009;
% % optimizer.Epsilon = 1.5e-4;
% % optimizer.GrowthFactor = 1.01;
% % optimizer.MaximumIterations = 300;
% tf = imregtform(O2,O1, 'translation', optimizer, metric);
% tf

O2r = imwarp(O2,tf,'OutputView',imref2d(size(O2)));

cr1 = corr2(O1,O2);

Jpx = O2r>0;
cr2 = corr(double(O1(Jpx)),double(O2r(Jpx)));

% cr1
% cr2

if(cr2<cr1)
    tf = affine2d(eye(3));
    cr2 = cr1;
end
    
    
reg_info.tf = tf;
reg_info.corr1 = cr1;
reg_info.corr2 = cr2;

% imagescBBC(O2r)
% 
% figure('Position',[1 41 1920 963],'Color','w'),
% subplot(1,2,1),imshowpair(O1,O2),title(num2str(reg_info.corr1))
% subplot(1,2,2),imshowpair(O1,O2r),title(num2str(reg_info.corr2))
% 
% 
% figure('Position',[1 41 1920 963],'Color','w'),
% imshowpair(O1,O2)
% 
% figure('Position',[1 41 1920 963],'Color','w'),
% imshowpair(O1,O2r)
% 
% pause

end







