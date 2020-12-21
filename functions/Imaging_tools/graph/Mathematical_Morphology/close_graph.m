function val_c = close_graph(G,val,Neigh)

if(nargin<3)
    Neigh = get_neighbors(G);
end


% node neighbors include itself 
Neigh = cellfun(@(x,y) [y x],Neigh,num2cell((1:size(Neigh,1))'),'UniformOutput',false);



val_c = cellfun(@(x) max(val(x)),Neigh,'UniformOutput',true);
val_c = cellfun(@(x) min(val_c(x)),Neigh,'UniformOutput',true);


end