function T = get_unique_values(CL)


[Ucl,~,Zcl] = unique(CL,'stable');



%% Number of cells
Number = [];
for cl = 1:length(Ucl)
    Number = [Number sum(Zcl==cl)];
end
Number = Number';


%% Percentage of cells
Percentage = 100*Number./sum(Number);



%%
T = [table(Ucl) table(Number) table(Percentage)]; 





end








