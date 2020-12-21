function Td = max_Neigh(T,mrk,Neigh)

Td = T;
for k = 2:size(mrk,1)
    disp(['Average neighborhood intensity ',mrk{k,1},' ...'])
    V = T{:,['meanIntensity_',mrk{k,1}]};
    Td{:,['meanIntensity_',mrk{k,1}]} = cellfun(@(x) max(V(x)),Neigh,'UniformOutput',true);
end

end