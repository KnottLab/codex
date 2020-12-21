function T = parse_celltypes(cell_type)



%% Level 6
cell_type_6 = cell_type;
cell_type_6 = strrep(cell_type_6,'Dendritic_cell'           ,'DC');

cell_type_6 = strrep(cell_type_6,'Activated_Bcell'          ,'Bcell_Activated');
cell_type_6 = strrep(cell_type_6,'Plasma_Bcell'             ,'Bcell_Plasma');

cell_type_6 = strrep(cell_type_6,'Activated_CD4T'           ,'CD4T_Activated');
cell_type_6 = strrep(cell_type_6,'Memory_CD4T'              ,'CD4T_Memory');
cell_type_6 = strrep(cell_type_6,'Tfh_CD4T'                 ,'CD4T_Tfh');
cell_type_6(contains(cell_type_6,'Treg'))                   ={'CD4T_Treg'};
cell_type_6 = strrep(cell_type_6,'Naïve_CD4T'               ,'CD4T_Naive');

cell_type_6 = strrep(cell_type_6,'Early_Activation_CD8T'    ,'CD8T_Early_Activation');
cell_type_6 = strrep(cell_type_6,'Late_Activation_CD8T'     ,'CD8T_Late_Activation');
cell_type_6 = strrep(cell_type_6,'Exhausted_CD8T'           ,'CD8T_Exhausted');
cell_type_6 = strrep(cell_type_6,'Trm_CD8T'                 ,'CD8T_Trm');
cell_type_6 = strrep(cell_type_6,'Naïve_CD8T'               ,'CD8T_Naive');

cell_type_6 = strrep(cell_type_6,'FCGR1_Mac'                ,'Mac_FCGR1');
cell_type_6 = strrep(cell_type_6,'FCAR_Mac'                 ,'Mac_FCAR');
cell_type_6 = strrep(cell_type_6,'APC_Macrophage'           ,'Mac_APC');
cell_type_6 = strrep(cell_type_6,'Inflam_Macrophage'        ,'Mac_Inflam');

cell_type_6 = strrep(cell_type_6,'CDH12_CDH18_Epithelial'   ,'Epithelial_CDH12_CDH18');
cell_type_6 = strrep(cell_type_6,'DSG3_Epithelial'          ,'Epithelial_DSG3');
cell_type_6 = strrep(cell_type_6,'Intermediate_Epithelial'  ,'Epithelial_Intermediate');
cell_type_6 = strrep(cell_type_6,'KRT_Epithelial'           ,'Epithelial_KRT');
cell_type_6 = strrep(cell_type_6,'Proliferating_Epithelial' ,'Epithelial_Proliferating');

cell_type_6 = strrep(cell_type_6,'PDGFRB_Fibroblast'        ,'Fibroblast_PDGFRB');
cell_type_6 = strrep(cell_type_6,'PDPN_Fibroblast'          ,'Fibroblast_PDPN');
cell_type_6 = strrep(cell_type_6,'FAP_Fibroblast'           ,'Fibroblast_FAP');
cell_type_6 = strrep(cell_type_6,'ACTA2_Fibroblast'         ,'Fibroblast_ACTA2');



%% Level 5
cell_type_5 = cell_type_6;
cell_type_5(contains(cell_type_5,'CD4T')) = {'CD4T'};
cell_type_5(contains(cell_type_5,'CD8T')) = {'CD8T'};
cell_type_5(contains(cell_type_5,'Bcell')) = {'Bcell'};
cell_type_5(contains(cell_type_5,'Mac')) = {'Mac'};
cell_type_5(contains(cell_type_5,'Epithelial')) = {'Epithelial'};
cell_type_5(contains(cell_type_5,'Fibroblast')) = {'Fibroblast'};



%% Level 4
cell_type_4 = cell_type_5;
cell_type_4(contains(cell_type_4,'CD4T')) = {'Tcell'};
cell_type_4(contains(cell_type_4,'CD8T')) = {'Tcell'};



%% Level 3
cell_type_3 = cell_type_4;
cell_type_3(contains(cell_type_3,'Tcell')) = {'Lymphocyte'};
cell_type_3(contains(cell_type_3,'Bcell')) = {'Lymphocyte'};
cell_type_3(contains(cell_type_3,'Mac')) = {'Monocyte'};
cell_type_3(contains(cell_type_3,'DC')) = {'Monocyte'};



%% Level 2
cell_type_2 = cell_type_3;
cell_type_2(contains(cell_type_2,'Lymphocyte')) = {'Immune'};
cell_type_2(contains(cell_type_2,'Monocyte')) = {'Immune'};
cell_type_2(contains(cell_type_2,'Endothelial')) = {'Stroma'};
cell_type_2(contains(cell_type_2,'Fibroblast')) = {'Stroma'};



%% 
T = [table(cell_type_2) table(cell_type_3) table(cell_type_4) table(cell_type_5) table(cell_type_6)];



end

















