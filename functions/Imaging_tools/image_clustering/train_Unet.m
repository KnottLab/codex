function [net,net_info] = train_Unet(Xn)


%%
Xn = imresize(Xn,[40 40]);

%% Unet
% https://blogs.mathworks.com/deep-learning/2019/02/21/image-to-image-regression/

nfr = size(Xn,1);
nch1 = size(Xn,3);
nch2 = size(Xn,3);
lgraph = unetLayers([nfr nfr nch1] , nch2,'encoderDepth',3);

lgraph = lgraph.removeLayers('Softmax-Layer');
lgraph = lgraph.removeLayers('Segmentation-Layer');
lgraph = lgraph.addLayers(regressionLayer('name','regressionLayer'));
lgraph = lgraph.connectLayers('Final-ConvolutionLayer','regressionLayer');

%     miniBatchSize = 64;
%     maxEpochs = 100;
%     epochIntervals = 1;
%     initLearningRate = 0.1;
%     learningRateFactor = 0.1;
%     l2reg = 0.0001;
%     options = trainingOptions('sgdm', ...
%         'Momentum',0.9, ...
%         'InitialLearnRate',initLearningRate, ...
%         'LearnRateSchedule','piecewise', ...
%         'LearnRateDropPeriod',10, ...
%         'LearnRateDropFactor',learningRateFactor, ...
%         'L2Regularization',l2reg, ...
%         'MaxEpochs',maxEpochs ,...
%         'MiniBatchSize',miniBatchSize, ...
%         'GradientThresholdMethod','l2norm', ...
%         'Plots','training-progress', ...
%         'GradientThreshold',0.01);

options = trainingOptions('adam','InitialLearnRate',1e-4,'MiniBatchSize',64,...
    'Shuffle','every-epoch','MaxEpochs',50,...
    'Plots','training-progress');

% options = trainingOptions('adam', ...
%     'MaxEpochs',200,...
%     'MiniBatchSize',256,...
%     'Shuffle','every-epoch',...
%     'InitialLearnRate',1e-3, ...
%     'Verbose',true, ...
%     'Plots','training-progress');

disp(lgraph)
analyzeNetwork(lgraph)



%%
[net,net_info] = trainNetwork(Xn,Xn,lgraph,options);




end








