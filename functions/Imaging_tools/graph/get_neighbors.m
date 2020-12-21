function Neigh = get_neighbors(G)


if(isa(G,'graph'))
    %Neigh = cellfun(@(x) [x neighbors(G,x)'],num2cell((1:size(G.Nodes,1))'),'UniformOutput',false);
    Neigh = cellfun(@(x) neighbors(G,x)',num2cell((1:size(G.Nodes,1))'),'UniformOutput',false);
elseif(isa(G,'digraph'))
    %Neigh = cellfun(@(x) [x successors(G,x)'],num2cell((1:size(G.Nodes,1))'),'UniformOutput',false);
    Neigh = cellfun(@(x) successors(G,x)',num2cell((1:size(G.Nodes,1))'),'UniformOutput',false);
end



%         %% Display: neughborhood examples
%         Jc = randperm(max(L(:)),round(0.01*max(L(:))))';
%         Ln = {};
%         Ln{1} = Ic{1};
%         Ln{2} = 65535*uint16(ismember(L,Jc));
%         Ln{3} = 65535*uint16(ismember(L,[Neigh{Jc}]));
%         display_multiplex(Ln,[],{'DNA','cell','neighbors'}',E,T,G)
%         axis([250 700 50 500])




end