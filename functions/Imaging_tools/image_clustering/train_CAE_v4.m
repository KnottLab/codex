function [net,net_info] = train_CAE_v4(Xn,n_features)


nfr = size(Xn,1);
ncl = n_features;
nch = size(Xn,3);



%%
layers = [ ...
    imageInputLayer([nfr nfr nch])
    convolution2dLayer(5,32,'Stride',2,'Padding','same')
    %batchNormalizationLayer
    reluLayer
    convolution2dLayer(5,64,'Stride',2,'Padding','same')
    %batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,128,'Stride',2,'Padding',0)
    %batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(3*3*128)
    fullyConnectedLayer(ncl)
    fullyConnectedLayer(3*3*128)
    transposedConv2dLayer(3,128,'Stride',2,'Cropping',0)
    %batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(5,64,'Stride',2,'Cropping',1)
    %batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(5,32,'Stride',2,'Cropping','same')
    %batchNormalizationLayer
    reluLayer
    transposedConv2dLayer(5,nch,'Stride',2,'Cropping','same')
    regressionLayer]

options = trainingOptions('adam', ...
    'MaxEpochs',200,...
    'MiniBatchSize',128,...
    'Shuffle','every-epoch',...
    'InitialLearnRate',1e-4, ...
    'Verbose',true, ...
    'Plots','training-progress');

analyzeNetwork(layers)



%% Train CAE
% [net,net_info] = trainNetwork(Xn,Xn,layers,options);




%% Train CAE v4
[Xn2,~] = rotation_augmentation(Xn,table((1:size(Xn,4))'));
Xn = repmat(Xn,[1 1 1 8]);
[net,net_info] = trainNetwork(Xn2,Xn,layers,options);










end









