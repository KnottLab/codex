function Tout = remove_cells_closeToBorders(I,T,nfr)

if(iscell(I))
   I = I{1};
end

% disp('removing cells close to borders ...')

Jc = (T.Y-(nfr-1)/2)>0;
Jc = Jc&(T.Y+(nfr-1)/2)<size(I,1);

Jc = Jc&(T.X-(nfr-1)/2)>0;
Jc = Jc&(T.X+(nfr-1)/2)<size(I,2);

Tout = T(Jc,:);


end