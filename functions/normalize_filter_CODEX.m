function I = normalize_filter_CODEX(I)


%% Image Normalization
for k = 1:length(I)
    disp(['image normalization: ',num2str(round(100*k/length(I))),'%'])
    I{k} = imadjust(I{k},stretchlim(I{k},[0.01 0.999]));
    I{k} = uint8(255*double(I{k})/double(max(I{k}(:))));
end


%% Image Normalization
% for k = 1:length(I)
%     disp(['image normalization: ',round(num2str(100*k/length(I)))])
%     %imax = floor(0.01*65535);
%     imax = double(quantile(I{k}(:),0.999));
%     I{k}(I{k}>imax) = imax;
%     I{k} = uint8(255*double(I{k})/imax);
% end


%% Display: Normalized images
%display_multiplex(I,[],mrk,[],[])
%axis([frames{i,2}([1 end]) frames{i,1}([1 end])])


%% Image Filtering
for k = 1:length(I)
    I{k} = medfilt2(I{k},[3 3]);
    %I{k} = imfilter(I{k},fspecial('average',[3 3]));
    %I{k} = imfilter(I{k},fspecial('disk',3));
end


%% Display: Filtered images
%display_multiplex(I,[],mrk,[],[])
%axis([frames{i,2}([1 end]) frames{i,1}([1 end])])




end