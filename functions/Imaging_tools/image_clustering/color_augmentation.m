function [Xn2,T2] = color_augmentation(Xn,T,N)


% N : number of duplicates

a = -0.1; 
b = 0.1;

T2 = [T table(ones(size(T,1),1),'VariableNames',{'Replicate_by_Color'})];
Xn2 = Xn;
for r = 2:N
    
    Tt = [T table(r*ones(size(T,1),1),'VariableNames',{'Replicate_by_Color'})];
    T2 = [T2;Tt];
    
    M = 255*( a + (b-a).*rand(size(Xn,3),size(Xn,4)) );
    M = repmat(M,[1 1 size(Xn,1) size(Xn,2)]);
    M = permute(M,[3 4 1 2]);
    
    Xn2 = cat(4,Xn2,uint8(double(Xn)+M));
    
end






end



