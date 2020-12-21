function [net,net_info] = train_CAE_v7(Xn,n_features)


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
% [net,net_info] = trainNetwork(Xn,Xn,layers,options);


%% Train CAE v6
[Xn2,~] = rotation_augmentation(Xn,table((1:size(Xn,4))'));
Xn = repmat(Xn,[1 1 1 8]);

[Xn2,~] = color_augmentation(Xn2,table((1:size(Xn,4))'),4);
Xn = repmat(Xn,[1 1 1 4]);

[net,net_info] = trainNetwork(Xn2,Xn,layers,options);








end










