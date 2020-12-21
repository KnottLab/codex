function G = graph_EBall(T,radius)

EdgeTable = [];
for c = 1:size(T,1)
    if(mod(c,500)==0)
        clc
        disp(['calculating disk graph: ',num2str(round(100*c/size(T,1))),'%'])
    end
    
    D = pdist2([T.X(c) T.Y(c)],[T.X T.Y]);
    ln = find(D<radius&D~=0);
    e = [c*ones(length(ln),1) ln' D(ln)'];
    EdgeTable = [EdgeTable;e];
    
end
EdgeTable = [table(EdgeTable(:,1:2),'VariableNames',{'EndNodes'}) ...
    table(EdgeTable(:,3),'VariableNames',{'Length'})];
NodeTable = T(:,2:3);
G = digraph(EdgeTable,NodeTable);


end


