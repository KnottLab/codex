clear, clc, close all

data_path = 'E:/CODEX/CODEX_v3/data/0_Raw/191202_Tumor_1100/cyc001_reg001/1_00005_Z*_CH1.tif';

imlist = dir(data_path);
imlist = cellfun(@(x) ['E:/CODEX/CODEX_v3/data/0_Raw/191202_Tumor_1100/cyc001_reg001/',x],{imlist.name},'UniformOutput',false);

mkdir('./figures')
for i = 1:length(imlist)
    im = imread(imlist{i});
    figure('Position',[1 41 1920 963],'Color','w')
    imagesc(im), axis tight equal
    title(['Z = ',num2str(i)],'FontSize',18)
    
    fr = getframe(gcf);
    im = frame2im(fr);
    [imind,cm] = rgb2ind(im,256);
    
    if(i==1)
        imwrite(imind,cm,'./figures/dapi.gif','gif','Loopcount',inf,'DelayTime',0.1);
    else
        imwrite(imind,cm,'./figures/dapi.gif','gif','WriteMode','append','Loopcount',inf,'DelayTime',0.3);
    end
    
end

im = fstack(imlist);
figure('Position',[1 41 1920 963],'Color','w')
imagesc(im), axis tight equal
title('All-in-Focus')
fr = getframe(gcf);
im = frame2im(fr);
imwrite(im,'./figures/dapi.png','png');




