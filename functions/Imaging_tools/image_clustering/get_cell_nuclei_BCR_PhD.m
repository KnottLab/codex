function [Xn,T] = get_cell_nuclei_BCR_PhD(nfr,color_norm,dup_pos)


labels = {'epithelial','immune','stroma'};
files = strrep(strrep(cellstr(ls('E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_BCR_PhD/images/*.png')),' ',''),'.png','');


Xn = [];
T = [];
for i = 1:length(files)
    
    disp(['extract nuclei frames BCR PhD ',num2str(i),'/',num2str(length(files))])
    
    I = imread(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_BCR_PhD/images/',files{i},'.png']);
    L = imread(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_BCR_PhD/labels/',files{i},'.bmp']); L = double(L)/85;
    N = imread(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_BCR_PhD/nuclei/',files{i},'.bmp']);
    
    if(color_norm==1)
        I = color_norm_Reinhard_Bladder(I);
    end
    
    
    for l = 1:length(labels)
        
        Z = L==l&logical(N);
        
        if(sum(Z(:))>0)
            stats = regionprops(Z,'Area','Centroid');
            cell_area = cat(1,stats.Area);
            cell_centroid = round(cat(1,stats.Centroid));
            
            Tt = [table(cell_centroid(:,1),'VariableNames',{'X'}) ...
                table(cell_centroid(:,2),'VariableNames',{'Y'})];
            
            if(~isempty(Tt))
                
                Tt = [table(cellfun(@(x) strrep(['BRC_',files{i},'_',num2str(l),'_',x],' ',''),cellstr(num2str((1:size(Tt,1))')),'UniformOutput',false),'VariableNames',{'cell_ID'}) ...
                    table(cellstr(repmat('BRC',[size(Tt,1) 1])),'VariableNames',{'dataset'}) ...
                    table(cellstr(repmat(files{i},[size(Tt,1) 1])),'VariableNames',{'file'}) ...
                    Tt];
                
                if(dup_pos==1)
                    Tt = duplicate_cell_centroids(Tt,10,6);
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
                    table(cellstr(repmat(labels{l},[size(Tt,1) 1])),'VariableNames',{'cell_type'}) ...
                    table(cellstr(repmat('Breast',[size(Tt,1) 1])),'VariableNames',{'tissue'})]];
                end
                
            end
            
            
        end
        
    end
    
    
end

Jc = randperm(size(T,1),size(T,1));

T = T(Jc,:);
Xn = Xn(:,:,:,Jc);







end



