function Idx = PhenoGraph_python(X)


%% Save data in file
save('features_for_PhenoGraph.mat','X')


%% Run Python
disp('running PhenoGraph in python')
tic
system('conda activate PhenoGraph & python E:\Imaging_tools\unsupervised_learning\PhenoGraph\run_PhenoGraph.py','-echo')
toc


%%
Idx = readtable('tmp_clusters.txt','ReadVariableNames',false);
Idx.Properties.VariableNames{1} = 'cluster';


%%
delete('features_for_PhenoGraph.mat')
delete('tmp_clusters.txt')




