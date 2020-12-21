function [Xn,X3n,Tn] = get_nuclei_frames_CODEX_and_HE(I,I3,T,nfr)



Xn = [];
Jn = [];
for c = 1:size(T,1)
    
    disp(['extracting nuclei frames: ',num2str(round(100*c/size(T,1))),'%'])
    
    dx = T.X(c)-(nfr-1)/2:T.X(c)+(nfr-1)/2;
    dy = T.Y(c)-(nfr-1)/2:T.Y(c)+(nfr-1)/2;
    
    if(min(dx)>0&&min(dy)>0&&max(dx)<size(I{1},2)&&max(dy)<size(I{1},1))
        
        Ic = [];
        for k = 1:length(I)
            Ic = cat(3,Ic,I{k}(dy,dx));
        end
        
        Xn = cat(4,Xn,Ic);
        Jn = [Jn;c];
        
    end
end



Tn = T(Jn,:);


X3n = 0;

end