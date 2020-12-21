function I = read_image_at_Z(CODEXobj,cl,ch,z)


if(isempty(CODEXobj.cycle_folders))
    I = readImageAtZ_v1(CODEXobj,cl,ch,z);
else
    I = readImageAtZ_v2(CODEXobj,cl,ch,z);
end


end












function I = readImageAtZ_v1(CODEXobj,cl,ch,z)

I = [];
for x = 1:CODEXobj.Nx
    It = [];
    if(mod(x,2)==0); Jy = CODEXobj.Ny:-1:1; else; Jy = 1:CODEXobj.Ny; end
    for y = Jy
        
        disp(['reading CL=',num2str(cl),' CH=',num2str(ch),' X=',num2str(x),' Y=',num2str(y),' Z=',num2str(z),'  | ',CODEXobj.markers2{cl,ch}])
        
        im = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/cyc',num2str2(cl),'_reg00',num2str(CODEXobj.roi),'/',num2str(CODEXobj.roi),'_00',num2str2((x-1)*CODEXobj.Ny+y),'_Z',num2str2(z),'_CH',num2str(ch),'.tif']);        
        It = [It im];
        
    end
    I = [I;It];
end


end






function I = readImageAtZ_v2(CODEXobj,cl,ch,z)

I = [];
for x = 1:CODEXobj.Nx
    It = [];
    if(mod(x,2)==0); Jy = CODEXobj.Ny:-1:1; else; Jy = 1:CODEXobj.Ny; end
    for y = Jy
        
        disp(['reading CL=',num2str(cl),' CH=',num2str(ch),' X=',num2str(x),' Y=',num2str(y),' Z=',num2str(z),'  | ',CODEXobj.markers2{cl,ch}])
        
        im = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/',CODEXobj.cycle_folders{cl},'/TileScan 1--Stage',num2str2_v2((x-1)*CODEXobj.Ny+y-1),'--Z',num2str2_v2(z-1),'--C',num2str2_v2(ch-1),'.tif']);        
        It = [It im];
        
    end
    I = [I;It];
end


end



