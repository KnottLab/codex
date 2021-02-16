function [Expr_Info,I] = flatfield_correction(Expr_Info,I,r,cl,ch)

disp('Flatfield Correction ... ')
tic

Nx = Expr_Info.regions{r,'Nx'};
Ny = Expr_Info.regions{r,'Ny'};
W = Expr_Info.tileWidth_px;
H = Expr_Info.tileHeight_px;




%% Flatfield Correction
Jp = I==0;
for x = 1:Nx
    for y = 1:Ny
        dx = 1+(x-1)*H:x*H;
        dy = 1+(y-1)*W:y*W;
        I(dx,dy) = imflatfield(I(dx,dy),100);
        I(dx,dy) = imcomplement(imflatfield(imcomplement(I(dx,dy)),100));
    end
end
I(Jp) = 0;


toc;


end






