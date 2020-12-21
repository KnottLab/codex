function G = graph_KNN(T,knn)

disp('calculating k-nearest neighbor graph...')

[Idx,D] = knnsearch([T.X T.Y],[T.X T.Y],'K',knn+1);

Q = [sort(repmat((1:size(Idx,1))',[knn 1])) repmat((2:knn+1)',[size(Idx,1) 1])];

% Idx = Idx';
EdgeTable = [Q(:,1) Idx(sub2ind(size(Idx),Q(:,1),Q(:,2)))];

% D = D';
EdgeTable = [EdgeTable D(sub2ind(size(Idx),Q(:,1),Q(:,2)))];

EdgeTable = [table(EdgeTable(:,1:2),'VariableNames',{'EndNodes'}) ...
    table(EdgeTable(:,3),'VariableNames',{'Length'})];

NodeTable = T(:,2:3);

G = digraph(EdgeTable,NodeTable);


end


