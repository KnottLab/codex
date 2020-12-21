function Y = tSNE_python(X)


save('tm_forTSNE_features.mat','X')

disp('running tSNE python')
tic
system('python functions\tSNE\run_tSNE.py')
toc

Y = readtable('tmp_tSNE_coords.txt','ReadVariableNames',false);
Y.Properties.VariableNames = {'tSNE1','tSNE2'};

delete('tm_forTSNE_features.mat')
delete('tmp_tSNE_coords.txt')




