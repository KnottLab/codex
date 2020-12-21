function [net,net_info] = train_CAE_v2(Xn,n_features)


nfr = size(Xn,1);
ncl = n_features;
nch = size(Xn,3);



%%
layers = [ ...
    imageInputLayer([nfr nfr nch])
    convolution2dLayer(3,32,'Stride',2,'Padding','same')
%     batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,32,'Stride',2,'Padding','same')
%     batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,64,'Stride',2,'Padding','same')
%     batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,64,'Stride',2,'Padding','same')
%     batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(128)
    fullyConnectedLayer(ncl)
    fullyConnectedLayer(128)
    transposedConv2dLayer(3,64,'Stride',2,'Cropping',0)
%     batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(3,64,'Stride',2,'Cropping','same')
%     batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(3,32,'Stride',2,'Cropping','same')
%     batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(3,32,'Stride',2,'Cropping',1)
%     batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(3,nch,'Stride',2,'Cropping',1)
    regressionLayer]

options = trainingOptions('adam', ...
    'MaxEpochs',200,...
    'MiniBatchSize',256,...
    'Shuffle','every-epoch',...
    'InitialLearnRate',1e-3, ...
    'Verbose',true, ...
    'Plots','training-progress');

analyzeNetwork(layers)



%% Train CAE
[net,net_info] = trainNetwork(Xn,Xn,layers,options);


%% Train CAE v2
% angles = [0 -90 90 180];
% Xn2 = [];
% for n = 1:size(Xn,4)
%    Xn2 = cat(4,Xn2,imrotate(Xn(:,:,:,n),angles(randi(4,1)))); 
% end
% [net,net_info] = trainNetwork(Xn,Xn2,layers,options);







end










