function [CL,FT,mu] = get_DCEC_output(T,dir_path)


CL = readtable([dir_path,'/clusters.txt'],'ReadVariableNames',false); 
CL.Properties.VariableNames = {'cluster'}; CL.cluster = CL.cluster+1; head(CL)
FT = readtable([dir_path,'/features.txt'],'ReadVariableNames',false); head(FT)
L1 = readtable([dir_path,'/pretrain_log.csv'],'ReadVariableNames',true); head(L1)
L2 = readtable([dir_path,'/deep_clustering_log.txt'],'ReadVariableNames',true,'Delimiter',' '); head(L2)

CL = CL(1:size(T,1),:);
FT = FT(1:size(T,1),:);

figure('Position',[1 41 1920 963],'Color','w')
subplot(2,2,1)
hold on,plot(L2.iter,L2.loss,'LineWidth',2)
hold on,plot(L2.iter,L2.clustering_loss,'LineWidth',2)
hold on,plot(L2.iter,L2.deconv1_loss,'LineWidth',2),box on, grid on
xlabel('iteration'),ylabel(''),title('DCEC deep clustering'),set(gca,'TickDir','out')

hold on,plot(L2.iter,L2.nbr_clusters/100,'LineWidth',2,'LineStyle',':'),box on, grid on
legend({'loss','clustering loss','deconv1 loss','nbr clusters'},'Location','northeastoutside')
set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')

subplot(2,2,2)
plot(L2.iter,L2.delta_label,'LineWidth',2),box on, grid on
xlabel('iteration'),ylabel('delta label'),title('DCEC deep clustering'),set(gca,'TickDir','out')

subplot(2,3,4)
plot(L1.epoch,L1.loss,'LineWidth',2),box on, grid on
xlabel('epoch'),ylabel('loss (mse)'),title('CAE Pretraining'),set(gca,'TickDir','out')

subplot(2,3,5)
[Ucl,~,Zcl] = unique(CL.cluster);
mu = [];
for cl = 1:length(Ucl)
    mu = [mu;mean(table2array(FT(Zcl==cl,:)),1)];
end
imagesc(zscore(mu,[],1))
yticks(1:size(mu,1)),yticklabels(cellstr(num2str(Ucl)))
xlabel('feature'),ylabel('cluster')
cb = colorbar; cb.Label.String = 'average value'; axis tight equal

subplot(2,3,6)
M = zeros(length(Ucl),1);
for cl = 1:length(Ucl)
    M(cl,1) = sum(Zcl==cl);
end
bar(M)
set(gca,'TickDir','out')
xticks(1:size(M,1)),xticklabels(cellstr(num2str(Ucl)))
xlabel('cluster')
ylabel('number of cells')

set(findall(gcf,'-property','FontSize'),'FontSize',16,'FontWeight','bold')







% figure
% plot(L2.iter,L2.nbr_clusters,'LineWidth',2),box on, grid on
% xlabel('iteration'),ylabel('nbr_clusters'),title('DCEC deep clustering'),set(gca,'TickDir','out')
% 
% figure
% plot(L2.iter,L2.loss,'LineWidth',2),box on, grid on
% xlabel('iteration'),ylabel('loss'),title('DCEC deep clustering'),set(gca,'TickDir','out')
% 
% figure
% plot(L2.iter,L2.loss,'LineWidth',2),box on, grid on
% xlabel('iteration'),ylabel('loss'),title('DCEC deep clustering'),set(gca,'TickDir','out')
% 
% figure
% plot(L2.iter,L2.loss,'LineWidth',2),box on, grid on
% xlabel('iteration'),ylabel('loss'),title('DCEC deep clustering'),set(gca,'TickDir','out')
% 
% figure
% plot(L2.iter,L2.loss,'LineWidth',2),box on, grid on
% xlabel('iteration'),ylabel('loss'),title('DCEC deep clustering'),set(gca,'TickDir','out')
% 


end

