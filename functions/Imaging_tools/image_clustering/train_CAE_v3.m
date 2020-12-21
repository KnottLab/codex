function [net,net_info] = train_CAE_v3(Xn,n_features)


nfr = size(Xn,1);
ncl = n_features;
nch = size(Xn,3);



%%
layers = [ ...
    imageInputLayer([nfr nfr nch])
    
    convolution2dLayer(5,32,'Stride',1,'Padding',0)
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Stride',1,'Padding',0)
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,128,'Stride',1,'Padding',0)
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(128)
    fullyConnectedLayer(ncl)
    fullyConnectedLayer(128)
        
    transposedConv2dLayer(3,128,'Stride',1,'Cropping',0)
    batchNormalizationLayer
    reluLayer
    
    maxUnpooling2dLayer
    
    transposedConv2dLayer(5,64,'Stride',1,'Cropping',1)
    batchNormalizationLayer
    reluLayer
    
    maxUnpooling2dLayer
    
    transposedConv2dLayer(5,32,'Stride',1,'Cropping','same')
    batchNormalizationLayer
    reluLayer
    
    maxUnpooling2dLayer
    
    transposedConv2dLayer(5,nch,'Stride',1,'Cropping','same')
    regressionLayer]

options = trainingOptions('adam', ...
    'MaxEpochs',200,...
    'MiniBatchSize',128,...
    'Shuffle','every-epoch',...
    'InitialLearnRate',1e-4, ...
    'Verbose',true, ...
    'Plots','training-progress');

analyzeNetwork(layers)

return

%% Train CAE
[net,net_info] = trainNetwork(Xn,Xn,layers,options);








