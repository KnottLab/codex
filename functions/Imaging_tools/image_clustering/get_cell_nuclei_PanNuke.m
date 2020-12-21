function [Xn,T] = get_cell_nuclei_PanNuke(nfr,color_norm,dup_pos)



labels = {'Neoplastic cells','Inflammatory','Connective/Soft tissue cells','Dead Cells','Epithelial'};
labels2 = {'epithelial','immune','stroma','stroma','epithelial'};


Xn = [];
T = [];
for fold = 1:3
    
    
    disp(['Reading PanNuke Folder ',num2str(fold),'/',num2str(3)])
    
    %Read images
    Z = readNPY(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_PanNuke/Fold ',num2str(fold),'/images/fold',num2str(fold),'/images.npy']);
    Z = uint8(permute(Z,[2 3 4 1]));
    
    %Read masks
    M = readNPY(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_PanNuke/Fold ',num2str(fold),'/masks/fold',num2str(fold),'/masks.npy']);
    M = permute(M,[2 3 4 1]);
    
    %Read organ
    Tissue = readNPY_cellstr(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_PanNuke/Fold ',num2str(fold),'/images/fold',num2str(fold),'/types.npy']);
    
    
    
    for i = 1:size(Z,4)
        
        I = Z(:,:,:,i);
        
        disp(['extract nuclei frames PanNuke ',num2str(i),'/',num2str(size(Z,4))])
        
        if(color_norm==1)
            I = color_norm_Reinhard_Bladder(I);
        end
        
        
        for l = 1:length(labels)
            
            stats = regionprops(M(:,:,l,i),'Centroid');
            if(~isempty(stats))
                
                cell_centroid = round(cat(1,stats.Centroid)); cell_centroid = cell_centroid(~isnan(cell_centroid(:,1)),:);
                
                Tt = [table(cell_centroid(:,1),'VariableNames',{'X'}) ...
                    table(cell_centroid(:,2),'VariableNames',{'Y'})];
                
                if(~isempty(Tt))
                    
                    Tt = [table(cellfun(@(x) strrep(['PanNuke_fold',num2str(fold),'_img',num2str(i),'_',num2str(l),'_',x],' ',''),cellstr(num2str((1:size(Tt,1))')),'UniformOutput',false),'VariableNames',{'cell_ID'}) ...
                        table(cellstr(repmat('PanNuke',[size(Tt,1) 1])),'VariableNames',{'dataset'}) ...
                        table(cellstr(repmat(['fold',num2str(fold),'_img',num2str(i)],[size(Tt,1) 1])),'VariableNames',{'file'}) ...
                        Tt];
                    
                    if(dup_pos==1)
                        Tt = duplicate_cell_centroids(Tt,10,5);
                    end
                    
                    Tt = remove_cells_closeToBorders(I,Tt,nfr);
                    
                    if(~isempty(Tt))
                        for c = 1:size(Tt,1)
                            dx = Tt.X(c)-(nfr-1)/2:Tt.X(c)+(nfr-1)/2;
                            dy = Tt.Y(c)-(nfr-1)/2:Tt.Y(c)+(nfr-1)/2;
                            Ic = I(dy,dx,:);
                            Xn = cat(4,Xn,Ic);
                        end
                        
                        T = [T;[Tt table(cellstr(repmat(labels{l},[size(Tt,1) 1])),'VariableNames',{'label'}) ...
                            table(cellstr(repmat(labels2{l},[size(Tt,1) 1])),'VariableNames',{'cell_type'}) ...
                            table(cellstr(repmat(Tissue{i},[size(Tt,1) 1])),'VariableNames',{'tissue'})]];
                    end
                    
                end
            end
            
            
        end
        
    end
    
end


Jc = randperm(size(T,1),size(T,1));

T = T(Jc,:);
Xn = Xn(:,:,:,Jc);










end