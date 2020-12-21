function G = filter_edge_length(G)


dm = sqrt(sum((G.Nodes{G.Edges.EndNodes(:,1),:}-G.Nodes{G.Edges.EndNodes(:,2),:}).^2,2));
% figure,histogram(dm)

Je = dm<300;

%G.Edges = G.Edges(Je,:);
G = rmedge(G,G.Edges.EndNodes(~Je,1),G.Edges.EndNodes(~Je,2));


end