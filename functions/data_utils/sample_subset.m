function [I,L,E,Tcell] = sample_subset(I,L,E,frame)


for k = 1:length(I)
    I{k} = I{k}(frame{1},frame{2});
end

L = bwlabel(L(frame{1},frame{2})>0,4);

E = E(frame{1},frame{2});

stats = regionprops(L,'Area','Centroid');
cell_area = cat(1,stats.Area);
cell_centroid = cat(1,stats.Centroid);
cell_ID = cellfun(@(x) ['cell_',x],strrep(cellstr(num2str((1:max(L(:)))')),' ',''),'UniformOutput',false);

Tcell = [table(cell_ID) ...
    table(cell_centroid(:,1),'VariableNames',{'X'}) ...
    table(cell_centroid(:,2),'VariableNames',{'Y'}) ...
    table(cell_area(:,1),'VariableNames',{'Size'})];



end