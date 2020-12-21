function T2 = duplicate_cell_centroids(T,N,max_dist)

% N : number of duplicates
% max_dist : maximum distance from original centroid

T2 = [T table(ones(size(T,1),1),'VariableNames',{'Replicate_by_Position'})];

for r = 2:N
    
    Tt = [T table(r*ones(size(T,1),1),'VariableNames',{'Replicate_by_Position'})];
    Tt.X = Tt.X + randi(max_dist,size(Tt,1),1);
    Tt.Y = Tt.Y + randi(max_dist,size(Tt,1),1);
    T2 = [T2;Tt];
    
end



end



