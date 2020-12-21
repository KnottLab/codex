function [Xn,T] = get_cell_nuclei_LATTICeA(nfr,color_norm,dup_pos)


labels = {'t','l','o','f'};
labels2 = {'epithelial','immune','stroma','stroma'};

files = strrep(strrep(cellstr(ls('E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_LATTICeA/imgs/*.jpg')),' ',''),'.jpg','');


Xn = [];
T = [];
for i = 1:length(files)
    
    disp(['extract nuclei frames LATTICeA ',num2str(i),'/',num2str(length(files))])
    
    I = imread(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_LATTICeA/imgs/',files{i},'.jpg']);
    
    if(color_norm==1)
        I = color_norm_Reinhard_Bladder(I);
    end
    
    
    for l = 1:length(labels)
        
        Tt = readtable(['E:/Imaging_data/HE/HE_cell_classification_datasets/cell_classification_LATTICeA/gt_celllabels/',files{i},'.csv']);
        Tt = Tt(strcmp(Tt.class,labels{l}),2:3);
        Tt.Properties.VariableNames = {'X','Y'};
        
        if(~isempty(Tt))
            
            Tt = [table(cellfun(@(x) strrep(['LUAD_',files{i},'_',num2str(l),'_',x],' ',''),cellstr(num2str((1:size(Tt,1))')),'UniformOutput',false),'VariableNames',{'cell_ID'}) ...
                table(cellstr(repmat('LUAD',[size(Tt,1) 1])),'VariableNames',{'dataset'}) ...
                table(cellstr(repmat(files{i},[size(Tt,1) 1])),'VariableNames',{'file'}) ...
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
                    table(cellstr(repmat('Lung',[size(Tt,1) 1])),'VariableNames',{'tissue'})]];
            end
            
        end
        
        
    end
    
end


Jc = randperm(size(T,1),size(T,1));

T = T(Jc,:);
Xn = Xn(:,:,:,Jc);


end



