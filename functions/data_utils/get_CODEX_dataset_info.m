function D = get_CODEX_dataset_info()


D = readtable('./utilities/CODEX_dataset_metadata.csv','ReadVariableNames',true);
% head(D)

D.sampleNames = strrep(D.sampleID,'_',' ');


% Large frames
frames = {};
for i = 1:size(D,1)
   frames(i,1:2) = {3800:5700,5000:8000}; 
end
D.frames = frames;

num = cellstr(num2str((1:size(D,1))'));
D = [table(num) D];

end



