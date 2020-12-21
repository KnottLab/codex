function [net,net_info] = autoencoder_clustering(F,n_features_out)


n_features_in = size(F,2);

F = reshape(F,[1 1 size(F,2) size(F,1)]);



%%
layers = [ ...
    imageInputLayer([1 1 n_features_in])
    fullyConnectedLayer(6*1*1)
    batchNormalizationLayer
    fullyConnectedLayer(5)
    batchNormalizationLayer
    fullyConnectedLayer(4)
    batchNormalizationLayer
    fullyConnectedLayer(3)
    fullyConnectedLayer(n_features_out)
    fullyConnectedLayer(3)
    batchNormalizationLayer
    fullyConnectedLayer(4)
    batchNormalizationLayer
    fullyConnectedLayer(5)
    batchNormalizationLayer
    fullyConnectedLayer(6)
    batchNormalizationLayer
    regressionLayer]

options = trainingOptions('adam', ...
    'MaxEpochs',200,...
    'MiniBatchSize',128,...
    'Shuffle','every-epoch',...
    'InitialLearnRate',1e-4, ...
    'Verbose',true, ...
    'Plots','training-progress');

analyzeNetwork(layers)



%% train autoencoder
[net,net_info] = trainNetwork(F,F,layers,options);


%%
AE_features = activations(net,F,'fc_5');



%%
AE_features = reshape(AE_features,[size(AE_features,4) size(AE_features,3)]);

figure,plot(AE_features(:,1),AE_features(:,2),'.')



end







