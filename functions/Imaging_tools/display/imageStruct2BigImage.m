function I1 = imageStruct2BigImage(I)

x = I(find(~cellfun(@isempty,I),1));
sxy = size(x{1});
    
dx = ceil(sqrt(numel(I)));
dy = ceil(sqrt(numel(I)));
I1 = [];
l = 1;
for i = 1:dx
    It = [];
    for j = 1:dy
        if(l>numel(I))
            I{l} = 255*ones(sxy); 
        elseif(isempty(I{l}))
            I{l} = 255*ones(sxy); 
        end
        It = [It I{l}];
        l = l+1;
    end
    I1 = [I1;It];
end


end