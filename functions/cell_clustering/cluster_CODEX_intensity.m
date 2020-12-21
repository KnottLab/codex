function CODEXobj = cluster_CODEX_intensity(CODEXobj,dist_metric)

CODEXobj.norm_info.dist_metric = dist_metric;

CODEXobj.antibody_clustering = CODEXobj.antibody(~ismember(CODEXobj.antibody(:,1),{'DAPI'}),1);

F = CODEXobj.marker_intensity_normalized{:,CODEXobj.antibody_clustering};

CL = LeidenAlg_python(F);
Y = UMAP_python(F);

CODEXobj.cells = [CODEXobj.cells Y CL];


end





