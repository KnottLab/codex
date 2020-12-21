function G = graph_Delaunay(T)



P = [T.X T.Y];
disp('Calculating Delaunay Graph...')
DT = delaunayTriangulation(P(:,1),P(:,2));
if(size(DT.Points,1)~=size(P,1) || ~isempty(find((P(:,1:2)-DT.Points)~=0, 1)))
    error('Delaunay has deleted some nodes!!');
end

DG.Nodes   = DT.Points;
DG.Edges   = edges(DT);
DG.Faces   = DT.ConnectivityList;

%DG.IndexF        = (1:1:size(CL,1))';
%DG.CentroidF     = [mean([P(CL(:,1),1) P(CL(:,2),1) P(CL(:,3),1)],2) mean([P(CL(:,1),2) P(CL(:,2),2) P(CL(:,3),2)],2)];
%DG.IncenterF     = incenter(DT);
%DG.CircumcenterF = circumcenter(DT);


%% Neighborhoods
%display('Calculatng Delaunay Neighborhoods...')
%DG.NeighborsE = [DG.IndexF neighbors(DT)];
%DG.NeighborsV = vertexNeighbors(DG);


%% Weigths (Values)
%DG.ValueF = ones(size(DG.IndexF));
%DG.ValueE = ones(size(DG.IndexE));


%% Nodes Neighbors Table
%DG.Neigh = nodesNeighborsTable(DG.Nodes,DG.Edges);

EdgeTable = table(DG.Edges,'VariableNames',{'EndNodes'});
NodeTable = T(:,ismember(T.Properties.VariableNames,{'X','Y'}));
G = graph(EdgeTable,NodeTable);



end



