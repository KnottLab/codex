function Ta = avrg_Neigh(T,mrk,Neigh)

Ta = T;
for k = 2:size(mrk,1)
    disp(['Average neighborhood intensity ',mrk{k,1},' ...'])
    V = T{:,['meanIntensity_',mrk{k,1}]};
    Ta{:,['meanIntensity_',mrk{k,1}]} = cellfun(@(x) mean(V(x)),Neigh,'UniformOutput',true);
end

end