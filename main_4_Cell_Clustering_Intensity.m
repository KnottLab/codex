clc
close all force
clear all
addpath(genpath([pwd,'\functions']));
addpath(genpath('E:\Imaging_tools'));


D = get_CODEX_dataset_info();


for i = 31
    
    load(['./outputs/3_Segmentation/',D.sampleID{i},'/',D.sampleID{i},'_CODEXobj.mat'],'CODEXobj'); disp(CODEXobj)
    
    
    %% Load channels
    [I,CODEXobj] = load_CODEX_images(CODEXobj,'CODEX','1_processed');
    
    
    %% Display Nuclei Segmentation
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells,[])
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% Get cell intensities
    CODEXobj = get_CODEX_marker_intensity(I,CODEXobj,'none'); disp(CODEXobj)
    head(CODEXobj.marker_intensity)

    
    %% Normalize marker intensities
    CODEXobj = normalize_CODEX_intensities(CODEXobj,'logFeatures','none'); disp(CODEXobj)
    

    %% Violin plot: intensities
    display_violinPlot_mrk_intensity(CODEXobj)
    
    mkdir(['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i}])
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_1_VP_mrk_intst.png'],'png')
    
    
    %% Clustering + UMAP
    CODEXobj = cluster_CODEX_intensity(CODEXobj,'Euclidean'); disp(CODEXobj)
    head(CODEXobj.cells)
    
    
    %% save clustering results
    mkdir(['./outputs/4_Cell_Clustering_Intensity/',D.sampleID{i}])
    save(['./outputs/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_CODEXobj.mat'],'CODEXobj','-v7.3'); disp(CODEXobj)
    
    
    %% Display clusters
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells,[])
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% UMAP: Clusters
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cluster)
    
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_2_UMAP_clusters.png'],'png')
    
    
    %% UMAP: Mean Intensity
    Ia = display_mean_intensities_UMAP([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.antibody_clustering);
    
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_3_UMAP_mrkIntst.png'],'png');
    
    
    %% Spatial: Clusters
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cluster)
    
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_4_slide_clusters.png'],'png')
    
    
    %% Spatial: Mean Intensity
    Ia = display_mean_intensities_spatial([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.nuclei_mask,CODEXobj.antibody_clustering);
    
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_5_slide_mrkIntst.png'],'png')
    
    
    %% Clustergram Antibody Expression with clusters
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering);
    
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_6_clustergram.png'],'png')
    
    
    return
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
                                     % * Annotation * %
    
    %%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %% add cluster annotations
    CODEXobj = get_celltype_from_annotation(CODEXobj); disp(CODEXobj)
    head(CODEXobj.cells)
    
    save(['./outputs/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_CODEXobj.mat'],'CODEXobj','-v7.3'); disp(CODEXobj)

    
    %% Display Nuclei Subtyping
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells,[])
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% Clustergram Antibody Expression with annotation
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering,CODEXobj.cells.cell_type_2);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_7_2_clustergram_annotated.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering,CODEXobj.cells.cell_type_3);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_7_3_clustergram_annotated.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering,CODEXobj.cells.cell_type_4);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_7_4_clustergram_annotated.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering,CODEXobj.cells.cell_type_5);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_7_5_clustergram_annotated.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cluster,CODEXobj.antibody_clustering,CODEXobj.cells.cell_type_6);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_7_6_clustergram_annotated.png'],'png')
    
    
    %% Clustergram Antibody Expression by celltype
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cell_type_2,CODEXobj.antibody_clustering);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_8_2_clustergram_by_celltype.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cell_type_3,CODEXobj.antibody_clustering);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_8_3_clustergram_by_celltype.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cell_type_4,CODEXobj.antibody_clustering);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_8_4_clustergram_by_celltype.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cell_type_5,CODEXobj.antibody_clustering);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_8_5_clustergram_by_celltype.png'],'png')
    
    Ia = display_clustergram_clusters([CODEXobj.cells CODEXobj.marker_intensity_normalized],CODEXobj.cells.cell_type_6,CODEXobj.antibody_clustering);
    imwrite(Ia,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_8_6_clustergram_by_celltype.png'],'png')
    

    %% Spatial: celltype
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cell_type_2)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_9_2_slide_cell_type.png'],'png')
    
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cell_type_3)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_9_3_slide_cell_type.png'],'png')
    
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cell_type_4)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_9_4_slide_cell_type.png'],'png')
    
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cell_type_5)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_9_5_slide_cell_type.png'],'png')
    
    display_clusters_spatial(CODEXobj.cells,CODEXobj.nuclei_mask,CODEXobj.cells.cell_type_6)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_9_6_slide_cell_type.png'],'png')
    
                    
    %% UMAP: celltype
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cell_type_2)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_10_2_UMAP_cell_type.png'],'png')
    
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cell_type_3)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_10_3_UMAP_cell_type.png'],'png')
    
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cell_type_4)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_10_4_UMAP_cell_type.png'],'png')
    
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cell_type_5)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_10_5_UMAP_cell_type.png'],'png')
    
    display_clusters_UMAP(CODEXobj.cells,CODEXobj.cells.cell_type_6)
    saveas(gcf,['./figures/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_10_6_UMAP_cell_type.png'],'png')
    

    
end




























