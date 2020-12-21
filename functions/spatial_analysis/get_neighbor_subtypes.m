function CODEXobj = get_neighbor_subtypes(CODEXobj,level)


%% Number of neigobrs
N = cellfun(@length,CODEXobj.graph.Neigh);
N = table(N,'VariableNames',{'Nbr_of_Neighbors'});


%% Percentage from each celltype
[Uc,~,Zc] = unique(CODEXobj.cells{:,['cell_type_',num2str(level)]});
P = [];
for c = 1:length(Uc)
    disp(['calculating neighbor subtype percentages : ',num2str(c),'/',num2str(length(Uc)),' ...'])
    P = [P cellfun(@(x) sum(strcmp(CODEXobj.cells{x,['cell_type_',num2str(level)]},Uc{c}))/length(x),CODEXobj.graph.Neigh,'UniformOutput',true)];
end
P = array2table(P,'VariableNames',cellfun(@(x) ['neigh_',x,'_per'],Uc,'UniformOutput',false));


CODEXobj.neighbor_subtypes = [CODEXobj.cells N P];


end



