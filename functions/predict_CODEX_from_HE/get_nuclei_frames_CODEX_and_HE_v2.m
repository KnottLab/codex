function [Xn,X3n,Tn] = get_nuclei_frames_CODEX_and_HE_v2(I,I3,T,nfr)


sz = [1000 1000];
ep = 50;


%% crop to the overlap
M = I3(:,:,1)==255&I3(:,:,2)==255&I3(:,:,3)==255;
[Jx,Jy] = find(~M);

I3 = I3(min(Jx):max(Jx),min(Jy):max(Jy),:);
I2 = [];
for k = 1:length(I)
    %I2 = cat(3,I2,I{k}(min(Jx):max(Jx),min(Jy):max(Jy),:));
    I2 = cat(3,I2,imadjust(I{k}(min(Jx):max(Jx),min(Jy):max(Jy),:)));
end

Jc = T.X>min(Jy)&T.Y>min(Jx)&T.X<max(Jy)&T.Y<max(Jx);
T = T(Jc,:);
T.X2 = T.X-min(Jy);
T.Y2 = T.Y-min(Jx);


%% Align block and Extract cells by block

nx = floor(size(I3,1)/sz(1));
ny = floor(size(I3,2)/sz(2));

X3n = [];
Xn = [];
Tn = [];
for x = 1:nx
    for y = 1:ny
        
        Dx = 1+(x-1)*sz(1):x*sz(1);
        Dy = 1+(y-1)*sz(2):y*sz(2);
        
        I3t = I3(Dx,Dy,:);
        I2t = I2(Dx,Dy,:);
        Jc = T.X2>min(Dy)&T.Y2>min(Dx)&T.X2<max(Dy)&T.Y2<max(Dx);
        Tt = T(Jc,:);
        Tt.X2 = Tt.X2-min(Dy);
        Tt.Y2 = Tt.Y2-min(Dx);

        %imagescBBC(I3t),hold on,plot(Tt.X,Tt.Y,'*')
        %imagescBBC(I2t),hold on,plot(Tt.X,Tt.Y,'*')
        
        [I3t,BR,cr1,cr2] = align_block(I3t,I2t(:,:,1));
        %imagescBBC(I3t),hold on,plot(Tt.X,Tt.Y,'*')
        
        
        for c = 1:size(Tt,1)
            
            disp(['extracting nuclei frames: (',num2str(x),'/',num2str(nx),',',num2str(y),'/',num2str(ny),') : ',num2str(round(100*c/size(Tt,1))),'%'])
            
            dx = Tt.X2(c)-(nfr-1)/2:Tt.X2(c)+(nfr-1)/2;
            dy = Tt.Y2(c)-(nfr-1)/2:Tt.Y2(c)+(nfr-1)/2;
            
            if(min(dx)-ep>0&&min(dy)-ep>0&&max(dx)+ep<size(I2t,2)&&max(dy)+ep<size(I2t,1))
                
                Xn = cat(4,Xn,I2t(dy,dx,:));
                X3n = cat(4,X3n,I3t(dy,dx,:));
                Tn = [Tn;[Tt(c,:) table(cr1) table(cr2)]];
                
            end
        
        end

        
    end
end





end

















function [I3t,BR,cr1,cr2] = align_block(I3t,I2t)

    BR = rgb2blueratio(I3t);
    BR = medfilt2(BR,[7 7]);
    BR = imclose(BR,strel('disk',3));
    BR = imdilate(BR,strel('disk',2));
    cr1 = corr2(BR,I2t);
    
    tf = imregcorr(BR,I2t,'translation');
    
    I3t = imwarp(I3t,tf,'OutputView',imref2d(size(I2t)));
    BR = imwarp(BR,tf,'OutputView',imref2d(size(I2t)));
    cr2 = corr2(BR,I2t);

end


