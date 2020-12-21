clc
close all force
clear all
addpath(genpath([pwd,'\functions']));
addpath(genpath('E:\Imaging_tools'));


D = get_CODEX_dataset_info();


for i = 31
    
    load(['./outputs/4_Cell_Clustering_Intensity/',D.sampleID{i},'/',D.sampleID{i},'_CODEXobj.mat'],'CODEXobj'); disp(CODEXobj)
    
    
    %% Load channels
    [I,CODEXobj] = load_CODEX_images(CODEXobj,'CODEX','1_processed');
    
    
    %% Display Nuclei Subtyping
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells,[])
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% Build Graph
    %CODEXobj.graph.G = graph_Delaunay(CODEXobj.cells); grphName = 'Delaunay';
    %CODEXobj.graph.G = graph_KNN(CODEXobj.cells,10);   grphName = 'KNN10';
    %CODEXobj.graph.G = graph_KNN(CODEXobj.cells,50);   grphName = 'KNN50';
    CODEXobj.graph.G = graph_KNN(CODEXobj.cells,100);  grphName = 'KNN100';
    %CODEXobj.graph.G = graph_KNN(CODEXobj.cells,500);  grphName = 'KNN500';
    
    
    %% Display Graph
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,CODEXobj.cells,CODEXobj.graph.G)
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    
    
    %% Get Neighbors
    CODEXobj.graph.Neigh = get_neighbors(CODEXobj.graph.G);
    
    mkdir(['./outputs/5_spatial_analysis/',D.sampleID{i}])
    save(['./outputs/5_spatial_analysis/',D.sampleID{i},'/',D.sampleID{i},'_CODEXobj.mat'],'CODEXobj','-v7.3'); disp(CODEXobj)
    
    
    %% Get neighbor subtype percentages
    for level = 2:6
        
        
        CODEXobj = get_neighbor_subtypes(CODEXobj,level);
        head(CODEXobj.neighbor_subtypes)
        
        
        %% Clustering based on neighbor percentages
        if(level<6); n_classes = 10; else n_classes = 20; end
        [idx,mu] = kmeans(CODEXobj.neighbor_subtypes{:,startsWith(CODEXobj.neighbor_subtypes.Properties.VariableNames,'neigh_')},n_classes,'Replicates',10);
        
        
        %%
        Ia = {};
        
        figure('Position',[1 400 1500 573],'Color','w','Visible','on')
        imagesc(100*mu),set(gca,'TickDir','out')
        clr = cbrewer('seq','PuBu',100,'linear');colormap(clr)
        ylabel('clusters'),yticks(1:size(mu,1))
        xlb = strrep(strrep(strrep(CODEXobj.neighbor_subtypes.Properties.VariableNames(startsWith(CODEXobj.neighbor_subtypes.Properties.VariableNames,'neigh_')),'neigh_',''),'_per',''),'_',' ');
        xlabel('neighbor cell'),xticks(1:size(mu,2)),xticklabels(xlb)
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        cb = colorbar; cb.Label.String = '% from neighbors';
        set(findall(cb,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        fr = getframe(gcf); Ia{1} = fr.cdata;
        
        
        %% Percentage of celltypes in each cluster
        [Uc,~,Zc] = unique(CODEXobj.cells{:,['cell_type_',num2str(level)]});
        N2 = NaN(size(mu,1),length(Uc));
        for c = 1:length(Uc)
            for cl = 1:size(mu,1)
                N2(cl,c) = sum(idx==cl&strcmp(CODEXobj.cells{:,['cell_type_',num2str(level)]},Uc{c}));
            end
        end
        N2 = N2./repmat(sum(N2,2),[1 size(N2,2)]);
        
        figure('Position',[800 400 700 573],'Color','w','Visible','on')
        clr = get_celltype_color(Uc);
        h = barh(N2,'stacked','FaceColor','flat');
        for c = 1:length(Uc)
            h(c).CData = clr(c,:);
        end
        ylabel('clusters'),yticks(1:size(mu,1))
        xlabel('% cell'),xticks([])
        clr = cbrewer('seq','Purples',100,'linear'); colormap(clr(1:80,:))
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        set(gca,'Ydir','reverse')
        axis tight
        legend(strrep(Uc,'_',' '),'Location','northeastoutside')
        fr = getframe(gcf); Ia{2} = fr.cdata;
        
        
        %% Number of cells in each cluster
        N = [];
        for cl = 1:size(mu,1)
            N = [N;sum(idx==cl)];
        end
        figure('Position',[1500 400 200 573],'Color','w','Visible','on')
        imagesc(N),title('k-means clustering','Color','w')
        ylabel('clusters'),yticks(1:size(mu,1))
        xlabel('Nbr. of cells'),xticks([])
        clr = cbrewer('seq','Purples',100,'linear'); colormap(clr(1:80,:))
        for j = 1:size(N,1)
            text(1,j,num2str(N(j)),'HorizontalAlignment','center')
        end
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        fr = getframe(gcf); Ia{3} = fr.cdata;
        
        P = round(100*N/sum(N));
        figure('Position',[1700 400 200 573],'Color','w','Visible','on')
        imagesc(P),title('k-means clustering','Color','w')
        ylabel('clusters'),yticks(1:size(mu,1))
        xlabel('% of cells'),xticks([])
        clr = cbrewer('seq','Blues',100,'linear'); colormap(clr(1:80,:))
        for j = 1:size(P,1)
            text(1,j,num2str(P(j)),'HorizontalAlignment','center')
        end
        set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')
        fr = getframe(gcf); Ia{4} = fr.cdata;
        
        
        %%
        close all
        Ia = [Ia{1} Ia{2} Ia{3} Ia{4}];
        figure,imshow(Ia)
        
        mkdir(['./figures/5_spatial_analysis/',D.sampleID{i}])
        imwrite(Ia,['./figures/5_spatial_analysis/',D.sampleID{i},'/',D.sampleID{i},'_',grphName,'_level',num2str(level),'.png'],'png')
        
        
    end
    
    
    %% Example: Display Spatial Clusters
    CODEXobj.neighbor_subtypes.spatial_cluster = cellstr(num2str(idx));
    Ta = CODEXobj.neighbor_subtypes;
    Ta = Ta(strcmp(Ta.cell_type_5,'Bcell'),:);
    display_multiplex(I,CODEXobj.antibody,[],[],CODEXobj.nuclei_boundary,CODEXobj.membrane_mask,Ta,CODEXobj.graph.G)
    axis([D.frames{i,2}([1 end]) D.frames{i,1}([1 end])])
    

    
end










