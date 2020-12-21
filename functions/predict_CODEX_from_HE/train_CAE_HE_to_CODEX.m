function [net,net_info] = train_CAE_HE_to_CODEX(Xn,X3n,n_features)


nfr = size(Xn,1);
ncl = n_features;
nch1 = size(Xn,3);
nch2 = size(X3n,3);


%%
layers = [ ...
    imageInputLayer([nfr nfr nch2])
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
    transposedConv2dLayer(3,nch1,'Stride',2,'Cropping',1)
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
[net,net_info] = trainNetwork(X3n,Xn,layers,options);






end










