function [tform,V,reg_info] = get_registration_transform(x1,y1,x2,y2,I,I2,W,D,V)

cutoff = 300; % Do registration only if average intensity in overlap > cutoff


tf = {};
orientation = {};
tform = affine2d(eye(3));


for i = 1:length(x1)
    
    tf{i} = tform;
    I1 = I(1+(x1(i)-1)*W:x1(i)*W,1+(y1(i)-1)*W:y1(i)*W);
    
    if(x2>x1(i))
        orientation{i} = 'south';
        O1 = I1(end-D+1:end,:);
        O2 = I2(1:D,:);
        mu1 = mean2(O1);
        if(mu1>cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
        mn1 = mean2(O1(end-20:end,:));
        mn2 = mean2(O2r(end-20:end,:));
        
        
    elseif(x2<x1(i))
        orientation{i} = 'north';
        O1 = I1(1:D,:);
        O2 = I2(end-D+1:end,:);
        mu1 = mean2(O1);
        if(mu1>cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
        mn1 = mean2(O1(1:20,:));
        mn2 = mean2(O2r(1:20,:));
        
        
    elseif(y2>y1(i))
        orientation{i} = 'east';
        O1 = I1(:,end-D+1:end);
        O2 = I2(:,1:D);
        mu1 = mean2(O1);
        if(mu1>cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
        mn1 = mean2(O1(:,end-20:end));
        mn2 = mean2(O2r(:,end-20:end));
        
        
    elseif(y2<y1(i))
        orientation{i} = 'west';
        O1 = I1(:,1:D);
        O2 = I2(:,end-D+1:end);
        mu1 = mean2(O1);
        if(mu1>cutoff)
            tf{i} = imregcorr(O2,O1,'translation');
        end
        O2r = imwarp(O2,tf{i},'OutputView',imref2d(size(O2)));
        mn1 = mean2(O1(:,1:20));
        mn2 = mean2(O2r(:,1:20));
        
        
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
reg_info.corr1 = corr2(O1,O2);
reg_info.corr2 = corr2(O1,O2r);
reg_info.meanO1 = mu1;
reg_info.meanO2 = mean2(O2);
reg_info.mn1 = mn1;
reg_info.mn2 = mn2;



end







