function [CODEXobj,I] = cycle_alignment_v3(CODEXobj,I,Iref,r,cl,ch)

disp('Cycle Alignment ... ')
tic;


% Nx = CODEXobj.regions{r,'Nx'};
% Ny = CODEXobj.regions{r,'Ny'};
% W = CODEXobj.tileWidth_px;
% H = CODEXobj.tileHeight_px;

Nx = CODEXobj.RNy;
Ny = CODEXobj.RNx;
W = CODEXobj.Width;
H = W;

if(cl>1&&ch==1)
    
    k = 1;
    tform = {};
    for x = 1:Nx
        for y = 1:Ny
            if(isempty(CODEXobj.real_tiles{x,y}))
                continue
            end
            disp(['Cycle Alignment:  reg',num2strn(r,3),'  :  ',CODEXobj.markerNames{cl,ch},'  :  CL=',num2str(cl),' CH=',num2str(ch),'  :  X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(Nx*Ny))),'%'])
            
            dx = 1+(x-1)*H:x*H;
            dy = 1+(y-1)*W:y*W;
            
            tform{x,y} = imregcorr(I(dx,dy),Iref(dx,dy),'translation');
            
            cr1(x,y) = corr2(Iref(dx,dy),I(dx,dy));
            It = imwarp(I(dx,dy),tform{x,y},'nearest','OutputView',imref2d(size(Iref(dx,dy))));
            cr2(x,y) = corr2(Iref(dx,dy),It);
            
            
            if(cr2(x,y)>cr1(x,y))
                I(dx,dy) = It;
            else
                tform{x,y} = affine2d(eye(3));
                cr2(x,y) = cr1(x,y);
            end
            
            %             [optimizer, metric] = imregconfig('multimodal');
            %             optimizer.InitialRadius = 0.009;
            %             optimizer.Epsilon = 1.5e-4;
            %             optimizer.GrowthFactor = 1.01;
            %             optimizer.MaximumIterations = 300;
            %             tform{x,y} = imregtform(I(dx,dy),Iref(dx,dy), 'translation', optimizer, metric);
            
            
            k = k+1;
            
        end
    end
    
    CODEXobj.Proc{r,1}.cycle_alignment.tform{cl,ch} = tform;
    CODEXobj.Proc{r,1}.cycle_alignment.corr1{cl,ch} = cr1;
    CODEXobj.Proc{r,1}.cycle_alignment.corr2{cl,ch} = cr2;
    CODEXobj.Proc{r,1}.cycle_alignment.time{cl,ch} = toc;
    CODEXobj.Proc{r,1}.cycle_alignment.proc_unit{cl,1} = 'CPU';
    
    
    
    
elseif(cl>1&&ch>1)
    
    tform = CODEXobj.Proc{r,1}.cycle_alignment.tform{cl,1};
    
    k = 1;
    for x = 1:Nx
        for y = 1:Ny
            if(isempty(CODEXobj.real_tiles{x,y}))
                continue
            end
            disp(['Cycle Alignment:  reg',num2strn(r,3),'  :  ',CODEXobj.markerNames{cl,ch},'  :  CL=',num2str(cl),' CH=',num2str(ch),'  :  X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(Nx*Ny))),'%'])
            
            dx = 1+(x-1)*H:x*H;
            dy = 1+(y-1)*W:y*W;
            
            I(dx,dy) = imwarp(I(dx,dy),tform{x,y},'nearest','OutputView',imref2d([H W]));
            
            k = k+1;
            
        end
    end
    
    CODEXobj.Proc{r,1}.cycle_alignment.tform{cl,ch} = tform;
    CODEXobj.Proc{r,1}.cycle_alignment.time{cl,ch} = toc;
    CODEXobj.Proc{r,1}.cycle_alignment.proc_unit{cl,ch} = 'CPU';
    
end




disp(['Cycle Alignment time: ',num2str(toc),' seconds'])




end














