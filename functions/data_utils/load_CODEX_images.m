function [I,CODEXobj] = load_CODEX_images(CODEXobj,marker_list,load_folder)

CODEXobj.antibody = {};


if(~iscell(marker_list))
    
    
    if(strcmp(marker_list,'All'))
        
        k = 1;
        for cl = 1:CODEXobj.Ncl
            for ch = 1:CODEXobj.Nch
                
                disp(['loading ',CODEXobj.markers2{cl,ch},' ...'])
                
                I{k} = read_CODEX_image(CODEXobj,load_folder,cl,ch);
                CODEXobj = get_image_antibody(CODEXobj,cl,ch,k);
                k = k+1;
                
            end
        end

        
    elseif(strcmp(marker_list,'CODEX'))
        
        % load first DAPI
        I{1} = read_CODEX_image(CODEXobj,load_folder,1,1);
        CODEXobj.antibody{1,1} = 'DAPI';
        CODEXobj.antibody{1,2} = 1;
        
        % load markers
        k = 2;
        for cl = 2:CODEXobj.Ncl-1
            for ch = 2:CODEXobj.Nch
                
                if(~contains(CODEXobj.markers2{cl,ch},'Blank')&&...
                        ~contains(CODEXobj.markers2{cl,ch},'Empty')&&...
                        ~(startsWith(CODEXobj.markers2{cl,ch},'Ch')&&contains(CODEXobj.markers2{cl,ch},'Cy'))&&...
                        ~strcmp(CODEXobj.markers2{cl,ch},'LaminB1'))
                    
                    disp(['loading ',CODEXobj.markers2{cl,ch},' ...'])
                    
                    I{k} = read_CODEX_image(CODEXobj,load_folder,cl,ch);
                    CODEXobj = get_image_antibody(CODEXobj,cl,ch,k);
                    k = k+1;
                    
                end
            end
        end
        
        % sort markers
        [~,ps] = sort(CODEXobj.antibody(:,1));
        CODEXobj.antibody = CODEXobj.antibody(ps,:);
        I = I(ps);
        
        % put DAPI or DNA on top
        J = strcmp(CODEXobj.antibody(:,1),'DAPI')|strcmp(CODEXobj.antibody(:,1),'DNA1')|strcmp(CODEXobj.antibody(:,1),'DNA2');
        J1 = find(J);
        J2 = find(~J);
        J = [J1;J2];
        
        CODEXobj.antibody = CODEXobj.antibody(J,:);
        I = I(J);
        
        
    end
    
    
    
    
    
    
    
    
    
else % list of markers
    
    % load first DAPI
    I{1} = read_CODEX_image(CODEXobj,load_folder,1,1);
    CODEXobj.antibody{1,1} = 'DAPI';
    CODEXobj.antibody{1,2} = 1;
    
    % load markers
    k = 2;
    for cl = 1:CODEXobj.Ncl-1
        for ch = 1:CODEXobj.Nch
            
            mrk0 = strrep(strrep(CODEXobj.markers2{cl,ch},' ','_'),'.','_');
            mrk0 = mrk0(1:strfind(mrk0,'_')-1);
            
            if(sum(ismember(marker_list,mrk0))>0&&~contains(mrk0,'DAPI'))
                
                disp(['loading ',CODEXobj.markers2{cl,ch},' ...'])
                
                I{k} = read_CODEX_image(CODEXobj,load_folder,cl,ch);
                CODEXobj = get_image_antibody(CODEXobj,cl,ch,k);
                k = k+1;
                
            end
        end
    end
    
    % sort markers
    [~,ps] = sort(CODEXobj.antibody(:,1));
    CODEXobj.antibody = CODEXobj.antibody(ps,:);
    I = I(ps);
    
    % put DAPI or DNA on top
    J = strcmp(CODEXobj.antibody(:,1),'DAPI')|strcmp(CODEXobj.antibody(:,1),'DNA1')|strcmp(CODEXobj.antibody(:,1),'DNA2');
    J1 = find(J);
    J2 = find(~J);
    J = [J1;J2];
    
    CODEXobj.antibody = CODEXobj.antibody(J,:);
    I = I(J);
    
    
end


end



















function It = read_CODEX_image(CODEXobj,load_folder,cl,ch)

if(strcmp(CODEXobj.processor,'Matlab_CODEX'))
    
    It = imread(['./data/',load_folder,'/',CODEXobj.sample_id,'/images/',CODEXobj.sample_id,'_',num2str((cl-1)*CODEXobj.Nch+ch),'_',CODEXobj.markers2{cl,ch},'.tif'],'tif');
    
elseif(strcmp(CODEXobj.processor,'Akoya_Proc'))
    image_folder = strrep(cellstr(ls([CODEXobj.data_path,'/',CODEXobj.sample_id,'/*'])),' ','');
    image_folder = image_folder{startsWith(image_folder,'processed')};
        
    It = imread([CODEXobj.data_path,'/',CODEXobj.sample_id,'/',image_folder,'/',...
                '/stitched/reg',num2str2(CODEXobj.roi),'/reg',num2str2(CODEXobj.roi),'_cyc',num2str2(cl),'_ch',num2str2(ch),'_',CODEXobj.markers2{cl,ch},'.tif']);
            
end

end




function CODEXobj = get_image_antibody(CODEXobj,cl,ch,k)

CODEXobj.antibody{k,1} = CODEXobj.markers2{cl,ch};

Js = strfind(CODEXobj.antibody{k,1},'_');
if(~isempty(Js))
    CODEXobj.antibody{k,1} = CODEXobj.antibody{k,1}(1:Js(1)-1);
end

CODEXobj.antibody{k,1} = strrep(strrep(strrep(CODEXobj.antibody{k,1},'-','_'),' ','_'),'.','_');
CODEXobj.antibody{k,2} = k;

end













