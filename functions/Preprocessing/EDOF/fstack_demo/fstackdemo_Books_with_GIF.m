clear, clc, close all

% Load image data:
load imdata.mat

% Show images:

mkdir('./figures')
for i = 1:length(imlist)
    im = imread(imlist{i});
    figure('Position',[1 41 1920 963],'Color','w')
    imshow(im)
    title(['Z = ',num2str(i)],'FontSize',18)
    fr = getframe(gcf);
    im = frame2im(fr);
    [imind,cm] = rgb2ind(im,256);
    
    if(i==1)
        imwrite(imind,cm,'./figures/books.gif','gif','Loopcount',inf,'DelayTime',0.1);
    else
        imwrite(imind,cm,'./figures/books.gif','gif','WriteMode','append','Loopcount',inf,'DelayTime',0.1);
    end
    
end

im = fstack(imlist);
figure('Position',[1 41 1920 963],'Color','w')
imshow(im)
title('All-in-Focus')
fr = getframe(gcf);
im = frame2im(fr);
imwrite(im,'./figures/books.png','png');




