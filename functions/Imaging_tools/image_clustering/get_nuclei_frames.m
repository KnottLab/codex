function Xn = get_nuclei_frames(I,T,mrk,markerUse,nfr)



Xn = [];
for c = 1:size(T,1)
    
    disp(['extracting nuclei frames: ',num2str(round(100*c/size(T,1))),'%'])
    
    dx = T.X(c)-(nfr-1)/2:T.X(c)+(nfr-1)/2;
    dy = T.Y(c)-(nfr-1)/2:T.Y(c)+(nfr-1)/2;
    
    if(iscell(I)) % Multiplex
        
        [~,~,ib] = intersect(markerUse,mrk(:,1),'stable');
        
        Ic = [];
        for k = ib'
            Ic = cat(3,Ic,I{k}(dy,dx));
        end
        
        %Xn = cat(4,Xn,uint16(Ic));
        %Xn = cat(4,Xn,uint8(255*2*double(Ic)/65535)); % IMC
        Xn = cat(4,Xn,uint8(255*double(Ic)/65535)); % CODEX
        
    else % H&E
        
        Ic = I(dy,dx,:);
        Xn = cat(4,Xn,Ic);
        
    end
    
end




end


