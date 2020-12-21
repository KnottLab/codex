function T2 = get_cells_closest_to_centroid(T,FT,CL,nbr_per_class)

[Ucl,~,Zcl] = unique(CL.cluster);
mu = [];
for cl = 1:length(Ucl)
    mu = [mu;mean(table2array(FT(Zcl==cl,:)),1)];
end

T2 = [];
for cl = 1:length(Ucl)
    
    Jcl = find(Zcl==cl);
    DM = pdist2(table2array(FT(Jcl,:)),mu(cl,:));
    [~,ps] = sort(DM,'ascend');
    Jcl = Jcl(ps(1:min([nbr_per_class length(ps)])));
    
    T2 = [T2;T(Jcl,:)];
    
end


end


