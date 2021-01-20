function CODEXobj = create_CODEX_object(D,i)


CODEXobj.sample_id = D.sampleID{i};
CODEXobj.data_path = D.data_path{i};
CODEXobj.fixation = D.fixation{i};
CODEXobj.organ = D.organ{i};
CODEXobj.species = D.species{i};
CODEXobj.lab = D.lab{i};
CODEXobj.processed = D.processed{i};
CODEXobj.processor = D.processor{i};
CODEXobj.region = D.region(i);

Tinfo = read_sample_metadata(CODEXobj.data_path,CODEXobj.sample_id,CODEXobj.region);
CODEXobj = concat_struct(CODEXobj,Tinfo);

CODEXobj.stitching_info = repmat({struct('tform',{})},CODEXobj.Ncl,1);
CODEXobj.cycle_alignment_info = repmat({struct('tform',{})},CODEXobj.Ncl,1);


end







function Tinfo = read_sample_metadata(data_path,sample_id,region_num)

files = strrep(cellstr(ls([data_path,'/',sample_id,'/*'])),' ','');

if(sum(strcmp(files,'experiment.json'))==1)
    Tinfo = read_sample_metadata_v1(data_path,sample_id);
else
    Tinfo = read_sample_metadata_v2(data_path,sample_id,region_num);
end


end











function Tinfo = read_sample_metadata_v1(data_path,sample_id)

if(strcmp(sample_id,'191129_BoneMarrow_Rowe_11000')); roi = 2; else; roi = 1; end

Json = jsondecode(fileread([data_path,'/',sample_id,'/experiment.json']));
Tinfo.Ncl = Json.numCycles;
Tinfo.Nch = Json.numChannels;
Tinfo.Nx = Json.regionHeight; if(strcmp(sample_id,'191129_BoneMarrow_Rowe_11000')); Tinfo.Nx = 6; end
Tinfo.Ny = Json.regionWidth;  if(strcmp(sample_id,'191129_BoneMarrow_Rowe_11000')); Tinfo.Ny = 3; end
Tinfo.Nz = Json.numZPlanes;
Tinfo.Ox = Json.tileOverlapX;
Tinfo.Oy = Json.tileOverlapY;
Tinfo.Width = Json.tileWidth;
Tinfo.width = floor((1-Json.tileOverlapX)*Json.tileWidth);
Tinfo.resolution = 0.001*Json.xyResolution;
Tinfo.wavelengths = Json.wavelengths;

Tinfo.roi = roi;
Tinfo.cycle_folders = [];

exposure_times = readtable([data_path,'/',sample_id,'/exposure_times.txt'],'ReadVariableNames',true,'Delimiter',',');
exposure_times = table2array(exposure_times(:,2:end));

nums1 = arrayfun(@(x) length(unique(exposure_times(:,x))),1:size(exposure_times,2));
if(unique(nums1)~=1)
    error('there are different exposure times per channel')
end
Tinfo.exposure_times = arrayfun(@(x) unique(exposure_times(:,x)),1:size(exposure_times,2));

marker_names = readtable([data_path,'/',sample_id,'/channelNames.txt'],'ReadVariableNames',false,'Delimiter','\t');
marker_names = marker_names.Var1;
marker_names = strrep(marker_names,'/','-');

markers = marker_names;
% Jb = find(strcmp(marker_names,'Blank'));
% markers(Jb) = cellfun(@(x,y) [x,y],marker_names(Jb),strrep(cellstr(num2str((1:length(Jb))')),' ',''),'UniformOutput',false);
% Jd = find(strcmp(marker_names,'DAPi'));
% markers(Jd) = cellfun(@(x,y) [x,y],marker_names(Jd),strrep(cellstr(num2str((1:length(Jd))')),' ',''),'UniformOutput',false);
% markers = cellfun(@(x,y) [x,'_',y],markers,strrep(cellstr(num2str((1:length(markers))')),' ',''),'UniformOutput',false);


% channels(1:4) = cellfun(@(x,y) [x,y],channelNames(1:4),strrep(cellstr(num2str((1:4)')),' ',''),'UniformOutput',false);
% channels(end-3:end) = cellfun(@(x,y) [x,y],channels(end-3:end),strrep(cellstr(num2str((5:8)')),' ',''),'UniformOutput',false);
% channels(5:4:(Ncl-1)*Nch) = cellfun(@(x,y) [x,y],channels(5:4:(Ncl-1)*Nch),strrep(cellstr(num2str((1:Ncl-2)')),' ',''),'UniformOutput',false);

Tinfo.markers = markers;
Tinfo.marker_names = marker_names;

Tinfo.markers2 = reshape(Tinfo.markers,[Tinfo.Nch Tinfo.Ncl])';
Tinfo.marker_names2 = reshape(Tinfo.marker_names,[Tinfo.Nch Tinfo.Ncl])';


end











function Tinfo = read_sample_metadata_v2(data_path,sample_id,region_num)

files = strrep(cellstr(ls([data_path,'/',sample_id,'/*'])),' ','');

cycle_folders = files(~contains(files,'.xml')&~ismember(files,{'.','..'})&~ismember(files,{'HandE'}),:);
cycle_folders = cycle_folders(2:end);
cycle_folders = cycle_folders(~strcmp(cycle_folders,'2020_02_19_04_08_32--200218010_toDelete'));

xml_file1 = fileread([data_path,'/',sample_id,'/',files{contains(files,'.xml')}]);

if(region_num==0)
    xml_file2 = fileread([data_path,'/',sample_id,'/',cycle_folders{1},'/Metadata/TileScan 1.xlif']);
else
    xml_file2 = fileread([data_path,'/',sample_id,'/',cycle_folders{1},'/TileScan 1/Metadata/Region ',num2str(region_num),'.xlif']);
end

nbr_cycles = get_number_of_cycles(xml_file1);
% disp(['number of cycles: ',num2str(nbr_cycles)])
if(nbr_cycles~=length(cycle_folders))
    error('number of cycles in metadata NOT equal number of folders in data')
end

Tinfo.roi = 1;
Tinfo.cycle_folders = cycle_folders;
Tinfo.Ncl = nbr_cycles;
Tinfo.Nch = get_nbr_of_channels(xml_file1);
[Tinfo.Ny,Tinfo.Nx,Tinfo.Py,Tinfo.Px,Tinfo.RNx,Tinfo.RNy,Tinfo.real_tiles] = get_number_of_XYtiles_v2(xml_file2);
Tinfo.Nz = get_number_of_zstacks(xml_file1);
[Tinfo.Width,Tinfo.Height,Tinfo.width,Tinfo.height,Tinfo.Ox,Tinfo.Oy] = get_tile_width(xml_file2);
Tinfo.exposure_times = get_exposure_times(xml_file1);
Tinfo.channels = get_channels(xml_file1);
Tinfo.wavelengths = get_wavelengths(xml_file1);
Tinfo.resolution = get_resolutionh(xml_file2);
[Tinfo.marker_names,Tinfo.markers,Tinfo.markers2,Tinfo.marker_names2] = get_marker_names(xml_file1,nbr_cycles,Tinfo.Nch);



end











function nbr_cycles = get_number_of_cycles(xml_file1)

p1 = strfind(xml_file1,'<ExposureItem>')';
p2 = strfind(xml_file1,'</ExposureItem>')';
nbr_cycles = 0;
for c = 1:length(p1)
    C = xml_file1(p1(c):p2(c));
    t1 = strfind(C,'<Active>')';
    t2 = strfind(C,'</Active>')';
    if(contains(C(t1(1):t2(1)),'true'))
        nbr_cycles = nbr_cycles + 1;
    end
end

end




function numZPlanes = get_number_of_zstacks(xml_file1)

p1 = strfind(xml_file1,'<ZstackDepth>')';
p2 = strfind(xml_file1,'</ZstackDepth>')';
numZPlanes = str2double(xml_file1(p1(1)+length('<ZstackDepth>'):p2(1)-1));

end



% function [Nx,Ny] = get_number_of_XYtiles(xml_file2)
% 
% p1 = strfind(xml_file2,'<Attachment ')';
% p2 = strfind(xml_file2,'</Attachment>')';
% C = xml_file2(p1(1):p2(1));
% tx = strfind(C,'FieldX="');
% ty = strfind(C,'FieldY="');
% tp = strfind(C,'PosX="');
% Nx = {}; Ny = {};
% for j = 1:length(tx)
%     Nx = [Nx;C((tx(j)+8):(ty(j)-3))];
%     Ny = [Ny;C((ty(j)+8):(tp(j)-3))];
% end
% 
% Nx = max(str2double(Nx))+1;
% Ny = max(str2double(Ny))+1;
% 
% end


function [Nx,Ny,Px,Py,RNx,RNy,real_tiles] = get_number_of_XYtiles_v2(xml_file2)
% Find all values of X and Y coordinates using the PosX and PosY fields
p1 = strfind(xml_file2,'<Attachment ')';
p2 = strfind(xml_file2,'</Attachment>')';
C = xml_file2(p1(1):p2(1));
tx = strfind(C,'FieldX="');
ty = strfind(C,'FieldY="');

% Tile positions
tpx = strfind(C,'PosX="'); % ~start
tpxe = strfind(C, '" PosY'); % ~end
tpy = strfind(C, 'PosY="');
tpye = strfind(C, '" /');

Nxv = {}; Nyv = {};
Px = []; Py = [];
for j = 1:length(tx)
    % we still need this to convert XY into stage number
    Nxv = [Nxv;C((tx(j)+8):(ty(j)-3))];
    Nyv = [Nyv;C((ty(j)+8):(tpx(j)-3))];
    Px = [Px;str2double(C(tpx(j)+6:tpxe(j)-1))];
    Py = [Py;str2double(C(tpy(j)+6:tpye(j)-1))];
end

Nx = max(str2double(Nxv))+1;
Ny = max(str2double(Nyv))+1;

% Size of the whole rectangular region
UPx = unique(Px);
UPy = unique(Py);
RNx = length(UPx);
RNy = length(UPy);

% Mark real tiles vs ones we need to fill with 0
% There's some transposing that happens here...
% real_tiles = zeros(RNy, RNx, 'logical');
% x ~ horizontal
% y ~ vertical
real_tiles = cell(RNy, RNx);
i = 0;
for y = 1:RNy
    Vy = UPy(y);
    % apply the zig-zag logic here 
    if(mod(y,2)==0); Jx = RNx:-1:1; else; Jx = 1:RNx; end
    for x = Jx
        Vx = UPx(x);
        if(sum((Px==Vx) .* (Py==Vy))==1)
            real_tiles{y,x} = num2str2_v2(i);
            i = i+1;
        end
    end
end

end


function [Width,Height,width,height,Ox,Oy] = get_tile_width(xml_file2)

C = xml_file2(strfind(xml_file2,'NumberOfElements="')+length('NumberOfElements="'):end);
Width = str2double(C(1:strfind(C,'"')-1));

C = xml_file2(strfind(xml_file2,'NumberOfElements="')+length('NumberOfElements="'):end);
C = C(strfind(C,'NumberOfElements="')+length('NumberOfElements="'):end);
Height = str2double(C(1:strfind(C,'"')-1));


C = xml_file2(strfind(xml_file2,'OverlapPercentageX="')+length('OverlapPercentageX="'):end);
Ox = str2double(C(1:strfind(C,'"')-1));

C = xml_file2(strfind(xml_file2,'OverlapPercentageY="')+length('OverlapPercentageY="'):end);
Oy = str2double(C(1:strfind(C,'"')-1));


width = floor((1-Ox)*Width);
height = floor((1-Oy)*Height);

end




function [marker_names,markers,markers2,marker_names2] = get_marker_names(xml_file1,Ncl,Nch)

marker_names = {};
p1 = strfind(xml_file1,'<AntiBody>');
p2 = strfind(xml_file1,'</AntiBody>');
for c = 1:Ncl
    C = xml_file1(p1(c):p2(c));
    t1 = strfind(C,'<string>');
    t2 = strfind(C,'</string>');
    for k = 1:length(t1)
        A = C(t1(k)+length('<string>'):t2(k)-1);
        marker_names{length(marker_names)+1,1} = A;
    end
end
marker_names = strrep(marker_names,'/','-');

markers = marker_names;
Jb = find(strcmp(marker_names,'Blank'));
markers(Jb) = cellfun(@(x,y) [x,y],marker_names(Jb),strrep(cellstr(num2str((1:length(Jb))')),' ',''),'UniformOutput',false);
Jd = find(contains(upper(marker_names),'DAPI'));
markers(Jd) = cellfun(@(x,y) [x,y],marker_names(Jd),strrep(cellstr(num2str((1:length(Jd))')),' ',''),'UniformOutput',false);
markers = cellfun(@(x,y) [x,'_',y],markers,strrep(cellstr(num2str((1:length(markers))')),' ',''),'UniformOutput',false);

markers2 = reshape(markers,[Nch Ncl])';
marker_names2 = reshape(marker_names,[Nch Ncl])';



end




function exposure_times = get_exposure_times(xml_file1)

p1 = strfind(xml_file1,'<ExposuresTime>')';
p2 = strfind(xml_file1,'</ExposuresTime>')';
C = xml_file1(p1(1):p2(1));
tx = strfind(C,'<decimal>');
ty = strfind(C,'</decimal>');
exposure_times = [];
for j = 1:length(tx)
    exposure_times = [exposure_times str2double(C(tx(j)+9:ty(j)-1))];
end

end



function wavelengths = get_wavelengths(xml_file1)

p1 = strfind(xml_file1,'<WaveLength>')';
p2 = strfind(xml_file1,'</WaveLength>')';
C = xml_file1(p1(1):p2(1));
tx = strfind(C,'<decimal>');
ty = strfind(C,'</decimal>');
wavelengths = [];
for j = 1:length(tx)
    wavelengths = [wavelengths str2double(C(tx(j)+9:ty(j)-1))];
end

end



function channels = get_channels(xml_file1)

p1 = strfind(xml_file1,'<Channels>')';
p2 = strfind(xml_file1,'</Channels>')';
C = xml_file1(p1(1):p2(1));
tx = strfind(C,'<string>');
ty = strfind(C,'</string>');
channels = [];
for j = 1:length(tx)
    channels{j} = C(tx(j)+9:ty(j)-1);
end

end




function Nch= get_nbr_of_channels(xml_file1)

p1 = strfind(xml_file1,'<Channels>')';
p2 = strfind(xml_file1,'</Channels>')';
C = xml_file1(p1(1):p2(1));
tx = strfind(C,'<string>');
Nch = length(tx);

end





function resolution = get_resolutionh(xml_file2)

C = xml_file2(strfind(xml_file2,'NumberOfElements="')+length('NumberOfElements="'):end);
Width = str2double(C(1:strfind(C,'"')-1));

C = xml_file2(strfind(xml_file2,'Length="')+length('Length="'):end);
Length = str2double(C(1:strfind(C,'"')-1));

resolution = (10^6)*Length/Width; % micrometer per pixel

end





