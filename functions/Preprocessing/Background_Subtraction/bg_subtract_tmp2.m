function I = bg_subtract_tmp2(CODEXobj,I,BG1,BG2,cl,ch,proc_unit)



%% Get Blank images for the same channel
I = int16(I);
BG1 = int16(BG1);
BG2 = int16(BG2);


%% Align Bachground images with current image
tform = CODEXobj.cycle_alignment_info{cl}.tform;
tform.T(3,1:2) = -tform.T(3,1:2);
BGt = imwarp(BG1,tform,'OutputView',imref2d(size(BG1)));
BGt(BGt==0) = BG1(BGt==0); % fix border effects
BG1 = BGt;

tform = CODEXobj.cycle_alignment_info{cl}.tform;
tform2 = CODEXobj.cycle_alignment_info{CODEXobj.Ncl}.tform;
tform.T(3,1:2) = tform2.T(3,1:2)-tform.T(3,1:2);
BGt = imwarp(BG2,tform,'OutputView',imref2d(size(BG2)));
BGt(BGt==0) = BG2(BGt==0); % fix border effects
BG2 = BGt;



%% gpuArray if requested
if(strcmp(proc_unit,'GPU'))
    I = gpuArray(I);
    BG1 = gpuArray(BG1);
    BG2 = gpuArray(BG2);
end



%% Apply median filter
I = medfilt2(I,[5 5]);
BG1 = medfilt2(BG1,[5 5]);
BG2 = medfilt2(BG2,[5 5]);



%%

for x = 1:CODEXobj.Nx
    for y = 1:CODEXobj.Ny
        
        dx = 1+(x-1)*CODEXobj.Height:x*CODEXobj.Height;
        dy = 1+(y-1)*CODEXobj.Width:y*CODEXobj.Width;
        
        disp('round 1 ...')
        Va = 0:0.1:2;
        Vb = 0:0.1:2;
        [M,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
        
        %%
        disp('round 2 ...')
        Va = max([(a-0.05) 0]):0.01:(a+0.05);
        Vb = max([(b-0.05) 0]):0.01:(b+0.05);
        [~,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
        
        I(dx,dy) = uint16(I(dx,dy) - a*BG1(dx,dy) - b*BG2(dx,dy));
        
                
    end
end


%%
I = gather(I);



end















function [M,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit)

M = zeros(length(Va),length(Vb));

if(strcmp(proc_unit,'GPU'))
    Va = gpuArray(Va);
    Vb = gpuArray(Vb);
    M = gpuArray(M);
end

for a = 1:length(Va)
    for b = 1:length(Vb)
        J = I - Va(a)*BG1 - Vb(b)*BG2;
        M(a,b) = sum(abs(J(:)));
    end
end

[a,b] = find(M==min(M(:)));

a = Va(a);
b = Vb(b);

end














