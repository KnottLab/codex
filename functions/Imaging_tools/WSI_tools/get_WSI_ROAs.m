function R = get_WSI_ROAs(file_name)


XMLfile = fileread([file_name(1:end-3),'xml']);
J1 = strfind(XMLfile,'<Vertices>');
J2 = strfind(XMLfile,'</Vertices>');

R = [];
for r = 1:length(J1)
    txt = XMLfile(J1(r):J2(r));
    Jx = strfind(txt,'X="');
    Jy = strfind(txt,'Y="');
    Jz = strfind(txt,'Z="');
    M = zeros(4,2);
    for p = 1:4
        M(p,1) = round(str2double(txt(Jy(p)+3:Jz(p)-3)));
        M(p,2) = round(str2double(txt(Jx(p)+3:Jy(p)-3)));
    end
    R = [R; [min(M(:,1)) max(M(:,1)) min(M(:,2)) max(M(:,2))]];
end
R = array2table(R,'VariableNames',{'x_start','x_end','y_start','y_end'});






I = imread(file_name,'Index',2);
% disp(['Image Size: ',num2str(size(I,1)),' x ',num2str(size(I,2))])
% figure,imagesc(I),axis tight equal

info = imfinfo(file_name);
cx = info(1).Height/info(2).Height;
cy = info(1).Width/info(2).Width;

figure('Position',[14 570 560 420]),imagesc(I),axis tight equal
for r = 1:size(R,1)

    x1 = R.x_start(r)/cx;
    x2 = R.x_end(r)/cx;
    
    y1 = R.y_start(r)/cy;
    y2 = R.y_end(r)/cy;
    
    hold on,rectangle('Position',[y1 x1 y2-y1 x2-x1],'EdgeColor',[1 0 0])
    
end
title(strrep(file_name,'_',' '))



%% make sure coordinates are in images
R.x_start(R.x_start<=0) = 1;
R.y_start(R.y_start<=0) = 1;
R.x_start(R.x_start>info(1).Height) = info(1).Height;
R.y_start(R.y_start>info(1).Width) = info(1).Width;


end







