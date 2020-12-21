function R = get_WSI_all(file_name)

info = imfinfo(file_name);

R = [1 info(1).Height 1 info(1).Width];
R = array2table(R,'VariableNames',{'x_start','x_end','y_start','y_end'});


I = imread(file_name,'Index',2);
% disp(['Image Size: ',num2str(size(I,1)),' x ',num2str(size(I,2))])
% figure,imagesc(I),axis tight equal
figure('Position',[14 570 560 420]),imagesc(I),axis tight equal
title(strrep(file_name,'_',' '))


end








