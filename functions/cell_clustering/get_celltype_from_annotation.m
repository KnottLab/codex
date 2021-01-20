function CODEXobj = get_celltype_from_annotation(CODEXobj)



Ann = readtable(['./outputs/4_Cell_Clustering_Intensity/',CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'/',...
    CODEXobj.sample_id,'_reg',num2str(CODEXobj.region),'_annotations.csv'],...
    'ReadVariableNames',true);


cell_type = CODEXobj.cells.cluster;
[Ucl,~,Zcl] = unique(CODEXobj.cells.cluster,'stable');
for cl = 1:length(Ucl)
    cell_type(Zcl==cl) = Ann{Ann{:,'clusterID'}==str2double(Ucl(cl)),'cell_type'};
end


CODEXobj.cells = [CODEXobj.cells(:,~contains(CODEXobj.cells.Properties.VariableNames,'cell_type')) parse_celltypes(cell_type)];




end










