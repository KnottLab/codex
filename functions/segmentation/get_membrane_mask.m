function CODEXobj = get_membrane_mask(CODEXobj)


%% Get Nuclei + Membrane
Rout = 5;
M = CODEXobj.nuclei_mask;
for r = 1:Rout
    disp(['segmenting cell membrane: ',num2str(round(100*r/Rout)),'%'])
    Mt = imdilate(M,strel('disk',1,4));
    Mt(M~=0) = M(M~=0);
    M = Mt;
end
Mt = imdilate(M,strel('disk',1,4));
M((Mt-M)>0) = 0;
CODEXobj.membrane_mask = M;



%% Get Membrane Only
Rin = 5;
CODEXobj.membrane_mask(imerode(CODEXobj.nuclei_mask>0,strel('disk',Rin))) = 0;






end