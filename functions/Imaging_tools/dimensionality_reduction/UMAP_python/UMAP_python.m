function Y = UMAP_python(X)


%% Save data in file
disp('exporting data matrix to UMAP learn ...')
save('features_for_UMAP.mat','X')



%% Run Python
tic
disp('running UMAP learn in python ...')
system('conda activate UMAP & python E:\Imaging_tools\dimensionality_reduction\UMAP_python\run_UMAP_learn.py','-echo')
disp('UMAP learn done')
toc



%%
Y = readtable('tmp_UMAP_coordinates.txt','ReadVariableNames',false);
Y.Properties.VariableNames = {'UMAP1','UMAP2'};


%%
delete('features_for_UMAP.mat')
delete('tmp_UMAP_coordinates.txt')




