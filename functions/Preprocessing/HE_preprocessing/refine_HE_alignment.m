function I3sr2 = refine_HE_alignment(I3,Lsr,Iref,CODEXobj)

disp('H&E post processing ...')
%%
%      close all

MM = zeros(size(Iref));

I3sr2 = zeros(size(Iref,1),size(Iref,2),3,'uint8');
t = 1;
for x = 1:CODEXobj.HE.Nx
    for y = 1:CODEXobj.HE.Ny
        
        %t = (x-1)*CODEXobj.HE.Ny+y;
        
        %             [x y]
        %             imagescBBC(I3),axis tight
        %             imagescBBC(Iref),axis tight
        %             imagescBBC(Lsr),axis tight
        %             imagescBBC(I3sr),axis tight
        
        %             imagescBBC(Lsr==t),axis tight
        c = regionprops(Lsr==t,'Centroid','Area'); a = cat(1,c.Area); c = cat(1,c.Centroid);
        [~,ps] = sort(a,'descend');
        c = c(ps(1),:);
        
        dx = 1+(x-1)*CODEXobj.HE.Height:x*CODEXobj.HE.Height;
        dy = 1+(y-1)*CODEXobj.HE.Width:y*CODEXobj.HE.Width;
        It = I3(dx,dy,:);
        It = imresize(It,CODEXobj.HE.resolution/CODEXobj.resolution);
        %             imagescBBC(It),axis tight
        
        BR = rgb2blueratio(It);
        BR = medfilt2(BR,[7 7]);
        BR = imclose(BR,strel('disk',3));
        BR = imdilate(BR,strel('disk',2));
        BR = imadjust(BR);
        %             imagescBBC(BR),axis tight
        
        
        
        dx = ceil(max((c(2)-size(It,1)/2),0):min((c(2)+size(It,1)/2),size(Iref,1))); if(length(dx)>size(It,1)); dx = dx(1:end-1); end
        dy = ceil(max((c(1)-size(It,2)/2),0):min((c(1)+size(It,2)/2),size(Iref,2))); if(length(dy)>size(It,2)); dy = dy(1:end-1); end
        
        MM(dx,dy) = 1;
        %             imagescBBC(MM),axis tight
        
        Ir = Iref(dx,dy);
        Ir = imadjust(Ir);
        
        %             imagescBBC(Ir),axis tight
        
        tf = imregcorr(BR,Ir,'translation');
        
        %             BRr = imwarp(BR,tf,'OutputView',imref2d(size(Ir)));
        %             imagescBBC(BRr),axis tight
        
        Itr = imwarp(It,tf,'OutputView',imref2d(size(Ir)));
        %             imagescBBC(Itr),axis tight
        
        J = I3sr2(dx,dy,1)==0&I3sr2(dx,dy,2)==0&I3sr2(dx,dy,3)==0;
        I3sr2(dx,dy,:) = I3sr2(dx,dy,:) + Itr.*repmat(uint8(J),[1 1 3]);
        %             imagescBBC(I3sr2),axis tight
        
        %             pause
        %             close all
        t = t+1;
    end
end

%     imagescBBC(I3sr2),axis tight







end




