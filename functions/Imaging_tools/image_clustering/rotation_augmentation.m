function [Xn2,T2] = rotation_augmentation(Xn,T)


angles = [0 -90 90 180];


T2 = [];
Xn2 = [];

a = 1;
for r = 1:length(angles)
    for f = [0 1] % flip
        
        Tt = [T table(a*ones(size(T,1),1),'VariableNames',{'Replicate_by_Rotation'})];
        T2 = [T2;Tt];
        
        if(f==0)
            Xt = Xn;
        else
            Xt = flip(Xn,2);
        end
        
        Xt = imrotate(Xt,angles(r));
        Xn2 = cat(4,Xn2,Xt);
        
        a = a+1;
    end
end






end



