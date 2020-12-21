function display_visium_graph(G)

X = G.Nodes.X(unique(G.Edges.EndNodes,'row'))';
Y = G.Nodes.Y(unique(G.Edges.EndNodes,'row'))';
ax = axis;
Jc = sum(X>ax(1)&X<ax(2)&Y>ax(3)&Y<ax(4),1)>0;
X = X(:,Jc);
Y = Y(:,Jc);
hold on,plot(X,Y,'Color','g','LineWidth',1.5)

end

