function CODEXobj = get_CODEX_marker_intensity(I,CODEXobj,image_norm)

% image_norm: 'none' or 'saturation_imadjust' or 'saturation_quantile'



%% Image Normalization
CODEXobj.norm_info.image_norm = image_norm;
    

if(startsWith(image_norm,'saturation_imadjust'))
    
    disp(['Calculating Cell Intensity: Image Normalization : ',image_norm,'...'])
    for k = 1:length(I)
        I{k} = imadjust(I{k},stretchlim(I{k}));
    end
    
elseif(startsWith(image_norm,'saturation_quantile'))
    
    disp(['Calculating Cell Intensity: Image Normalization : ',image_norm,'...'])
    for k = 1:length(I)
        cls = class(I{k});
        if(isa(I{k},'uint8')); cm = 255; elseif(isa(I{k},'uint16')); cm = 65535;end
        I{k} = double(I{k});
        cmax = quantile(I{k}(:),0.99);
        I{k} = cast(cm*I{k}/cmax,cls);
    end
    
end





%% Calculate Average Intensity per cell
CODEXobj.marker_intensity = [];
CODEXobj.norm_info.marker_surface = [table(CODEXobj.antibody,'VariableNames',{'marker'}) table(CODEXobj.antibody,'VariableNames',{'surface'})];

for k = 1:length(I)
    
    disp(['Calculating Cell Intensity: ',num2str(k),'/',num2str(length(I))])
    
    if(strcmpi(CODEXobj.antibody{k,1},'FOXP3')||strcmpi(CODEXobj.antibody{k,1},'Ki_67'))
        
        stats = regionprops(CODEXobj.nuclei_mask,I{k},'MeanIntensity');
        CODEXobj.norm_info.marker_surface.surface{k} = 'nucleus';
        
    else
        
        stats = regionprops(CODEXobj.membrane_mask,I{k},'MeanIntensity');
        CODEXobj.norm_info.marker_surface.surface{k} = 'membrane';
        
    end

    CODEXobj.marker_intensity = [CODEXobj.marker_intensity table(cat(1,stats.MeanIntensity),'VariableNames',CODEXobj.antibody(k,1))];
    
end






end











