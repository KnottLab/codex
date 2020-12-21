function s = concat_struct(s1,s2)



% Convert structures to tables
s1 = struct2table( s1 );
s2 = struct2table( s2 ,'AsArray',true);

% Concatonate tables
s = [ s1 ,s2 ];

% Convert table to structure
s = table2struct( s );

end



