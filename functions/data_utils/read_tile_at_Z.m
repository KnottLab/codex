function It = read_tile_at_Z(CODEXobj,cl,ch,x,y,z)



if(isempty(CODEXobj.cycle_folders))
    fname = [CODEXobj.data_path,'/',CODEXobj.sample_id,'/cyc',num2str2(cl),'_reg00',num2str(CODEXobj.roi),'/',num2str(CODEXobj.roi),'_00',num2str2((x-1)*CODEXobj.Ny+y),'_Z',num2str2(z),'_CH',num2str(ch),'.tif'];
    
elseif(CODEXobj.region==0)
    fname = [CODEXobj.data_path,'/',CODEXobj.sample_id,'/',CODEXobj.cycle_folders{cl},'/TileScan 1--Stage',CODEXobj.real_tiles{y,x},'--Z',num2str2_v2(z-1),'--C',num2str2_v2(ch-1),'.tif'];

else
    fname = [CODEXobj.data_path,'/',CODEXobj.sample_id,'/',CODEXobj.cycle_folders{cl},'/TileScan 1/Region ',num2str(CODEXobj.region),'--Stage',CODEXobj.real_tiles{y,x},'--Z',num2str2_v2(z-1),'--C',num2str2_v2(ch-1),'.tif'];

end

disp(fname)
It = imread(fname);

end