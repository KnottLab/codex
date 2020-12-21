function Idx = LeidenAlg_python(X)


%% Save data in file
save('features_for_LeidenAlg.mat','X')


%% Run Python
disp('running LeidenAlg in python')
tic
system('conda activate LeidenAlg & python E:\Imaging_tools\unsupervised_learning\LeidenAlg\run_LeidenAlg.py','-echo')
toc


%%
Idx = readtable('tmp_clusters.txt','ReadVariableNames',false);
Idx.Properties.VariableNames{1} = 'cluster';
Idx.cluster = cellstr(num2str(Idx.cluster));


%%
delete('features_for_LeidenAlg.mat')
delete('tmp_clusters.txt')



end
