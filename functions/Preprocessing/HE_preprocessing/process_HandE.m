function [I3,CODEXobj] = process_HandE(CODEXobj)



CODEXobj = get_HandE_info(CODEXobj);

[I3,CODEXobj] = read_raw_HandE(CODEXobj);
% imagescBBC(I3),axis tight


[I3s,Ls] = stitch_HE(I3,CODEXobj); 
% imagescBBC(I3s),axis tight
% imagescBBC(Ls),axis tight


[I3sr,Lsr,Iref] = align_HE_to_CODEX_WSI(I3s,Ls,CODEXobj); 
% imagescBBC(I3sr),axis tight
% imagescBBC(Iref),axis tight
% imagescBBC(Lsr),axis tight


I3sr2 = refine_HE_alignment(I3,Lsr,Iref,CODEXobj);
% imagescBBC(I3sr2),axis tight



% I3 = I3sr;
I3 = I3sr2;


end



















function CODEXobj = get_HandE_info(CODEXobj)

xml_file3 = fileread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/HandE/Metadata/TileScan 2.xlif']);

p1 = strfind(xml_file3,'<Attachment ')';
p2 = strfind(xml_file3,'</Attachment>')';
C = xml_file3(p1(1):p2(1));
tx = strfind(C,'FieldX="');
ty = strfind(C,'FieldY="');
tp = strfind(C,'PosX="');
Nx = {}; Ny = {};
for j = 1:length(tx)
    Nx = [Nx;C((tx(j)+8):(ty(j)-3))];
    Ny = [Ny;C((ty(j)+8):(tp(j)-3))];
end
CODEXobj.HE.Ny = max(str2double(Nx))+1;
CODEXobj.HE.Nx = max(str2double(Ny))+1;

C = xml_file3(strfind(xml_file3,'DimID="2" NumberOfElements="')+length('DimID="1" NumberOfElements="'):end);
CODEXobj.HE.Width = str2double(C(1:strfind(C,'"')-1));

C = xml_file3(strfind(xml_file3,'DimID="1" NumberOfElements="')+length('DimID="3" NumberOfElements="'):end);
CODEXobj.HE.Height = str2double(C(1:strfind(C,'"')-1));

C = xml_file3(strfind(xml_file3,'OverlapPercentageX="')+length('OverlapPercentageX="'):end);
CODEXobj.HE.Ox = str2double(C(1:strfind(C,'"')-1));

C = xml_file3(strfind(xml_file3,'OverlapPercentageY="')+length('OverlapPercentageY="'):end);
CODEXobj.HE.Oy = str2double(C(1:strfind(C,'"')-1));

CODEXobj.HE.width = floor((1-CODEXobj.HE.Oy)*CODEXobj.HE.Width);
CODEXobj.HE.height = floor((1-CODEXobj.HE.Oy)*CODEXobj.HE.Height);

C = xml_file3(strfind(xml_file3,'Length="')+length('Length="'):end);
Length = str2double(C(1:strfind(C,'"')-1));
CODEXobj.HE.resolution = (10^6)*Length/CODEXobj.HE.Height; % micrometer per pixel

end











function [I3,CODEXobj] = read_raw_HandE(CODEXobj)

I3 = [];
for x = 1:CODEXobj.HE.Nx
    It = [];
    if(mod(x,2)==0); Jy = CODEXobj.HE.Ny:-1:1; else; Jy = 1:CODEXobj.HE.Ny; end
    for y = Jy
        
        disp(['reading H&E X=',num2str(x),' Y=',num2str(y)])
        
        im = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/HandE/TileScan 2--Stage',num2str2_v2((x-1)*CODEXobj.HE.Ny+y-1),'.tif']);
        %im = imrotate(im,90);
        It = [It im];
        
    end
    I3 = [I3;It];
end

I3 = imrotate(I3,90);
tmp = CODEXobj.HE.Nx;
CODEXobj.HE.Nx = CODEXobj.HE.Ny;
CODEXobj.HE.Ny = tmp;


end











































