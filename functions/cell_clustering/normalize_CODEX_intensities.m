function CODEXobj = normalize_CODEX_intensities(CODEXobj,log_norm,intensity_norm)

% log_norm: 'none' or 'logFeatures' or 'logCells'
% intensity_norm: 'none' or 'zscore' or 'norm' or 'scale' or 'range' or 'center' or 'quantilenormFeatures' or 'quantilenormCells'

    
    

%%
disp('Normalizing Marker Intensities ...')


CODEXobj.norm_info.log_norm = log_norm;
CODEXobj.norm_info.intensity_norm = intensity_norm;


F = CODEXobj.marker_intensity{:,CODEXobj.antibody(:,1)};


%% Log Normalization
if(strcmp(log_norm,'logFeatures'))
    
    F = log10(10000*F./repmat(sum(F,1),[size(F,1) 1])+1);
    
elseif(strcmp(log_norm,'logCells'))
    
    F = log10(10000*F./repmat(sum(F,2),[1 size(F,2)])+1);
    
end



%% Second Normalization
if(sum(ismember({'zscore','norm','scale','range','center'},intensity_norm))>0)
    
    F = normalize(F,intensity_norm);
    
elseif(strcmp(intensity_norm,'quantilenormFeatures'))
    
    F = quantilenorm(F);
    
elseif(strcmp(intensity_norm,'quantilenormCells'))
    
    F = quantilenorm(F')';
    
end




%%
CODEXobj.marker_intensity_normalized = CODEXobj.marker_intensity;
CODEXobj.marker_intensity_normalized{:,CODEXobj.antibody(:,1)} = F;






end











