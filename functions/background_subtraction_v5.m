function [CODEXobj,I] = background_subtraction_v5(CODEXobj,I,BG1,BG2,r,cl,ch,proc_unit)

disp('Background Subtraction ...')
tic


Nx = CODEXobj.RNy;
Ny = CODEXobj.RNx;
W = CODEXobj.Width;
H = CODEXobj.Height;

I = int16(I);
BG1 = int16(BG1{ch});
BG2 = int16(BG2{ch});

Jp = I>0&BG1>0&BG2>0;

if(strcmp(proc_unit,'GPU'))
    I = gpuArray(I);
    BG1 = gpuArray(BG1);
    BG2 = gpuArray(BG2);
end



%% Apply median filter
% I = medfilt2(I,[5 5]);
% BG1 = medfilt2(BG1,[5 5]);
% BG2 = medfilt2(BG2,[5 5]);



%% Background Subtraction



k = 1;
for x = 1:Nx
    for y = 1:Ny
        if(isempty(CODEXobj.real_tiles{x,y}))
            continue
        end
        disp(['Background Subtraction:  ',CODEXobj.markerNames{cl,ch},'  : CL=',num2str(cl),' CH=',num2str(ch),' X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(Nx*Ny))),'%'])
        
        dx = 1+(x-1)*H:x*H;
        dy = 1+(y-1)*W:y*W;
        
        Va = 0:0.1:2;
        Vb = 0:0.1:2;
        [~,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
        
        Va = max([(a-0.05) 0]):0.01:(a+0.05);
        Vb = max([(b-0.05) 0]):0.01:(b+0.05);
        [~,a,b] = find_optimal_ab(I(dx,dy),BG1(dx,dy),BG2(dx,dy),Va,Vb,proc_unit);
        a = a*1.05;
        b = b*1.05;
        
        I(dx,dy) = I(dx,dy) - a*BG1(dx,dy) - b*BG2(dx,dy);
        
        k = k+1;
    end
end

if(strcmp(proc_unit,'GPU'))
    I = gather(I);
end


I(I<0) = 0;
I = I+1;
I(~Jp) = 0;

I = uint16(I);



CODEXobj.Proc{r,1}.background_subtraction.time{cl,ch} = toc;



disp(['Background Subtraction time: ',num2str(CODEXobj.Proc{r,1}.background_subtraction.time{cl,ch}),' seconds'])



end











function [M,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit)

M = zeros(length(Va),length(Vb));

if(strcmp(proc_unit,'GPU'))
    Va = gpuArray(Va);
    Vb = gpuArray(Vb);
    M = gpuArray(M);
end

Jpx = I>0&BG1>0&BG2>0;

I = I(Jpx);
BG1 = BG1(Jpx);
BG2 = BG2(Jpx);

for a = 1:length(Va)
    for b = 1:length(Vb)
        J = I - Va(a)*BG1 - Vb(b)*BG2;
        M(a,b) = sum(abs(J(:)));
    end
end

[a,b] = find(M==min(M(:)));
a = a(1);
b = b(1);

a = Va(a);
b = Vb(b);


end














