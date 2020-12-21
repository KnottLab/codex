function val_d = open_graph(G,val,Neigh)

if(nargin<3)
    Neigh = get_neighbors(G);
end


% node neighbors include itself 
Neigh = cellfun(@(x,y) [y x],Neigh,num2cell((1:size(Neigh,1))'),'UniformOutput',false);



val_d = cellfun(@(x) min(val(x)),Neigh,'UniformOutput',true);
val_d = cellfun(@(x) max(val_d(x)),Neigh,'UniformOutput',true);


end