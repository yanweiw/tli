function [net] = learn_bc(seg)
% Learning BC policy using NN

data = seg.Data';
XTrain = data(:, 1:2);
YTrain = data(:, 3:4);

% Design Network
numObservations = 2;
numActions = 2;
hiddenLayerSize = 100;
umax = 50; 

layers = [
    featureInputLayer(numObservations,'Normalization','none','Name','observation')
    fullyConnectedLayer(hiddenLayerSize,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(hiddenLayerSize,'Name','fc2')
    reluLayer('Name','relu2')
    fullyConnectedLayer(numActions,'Name','fcLast')
    tanhLayer('Name','tanhLast')
    scalingLayer('Name','ActorScaling','Scale',umax)
    regressionLayer('Name','routput')];

% Training 
% intialize validation cell array
validationCellArray = {0,0};

options = trainingOptions('adam', ...
    'Verbose', false, ...
    'Plots', 'training-progress', ...
    'Shuffle', 'every-epoch', ...
    'MiniBatchSize', 512, ...
    'InitialLearnRate', 1e-3, ...
    'ExecutionEnvironment', 'cpu', ...
    'GradientThreshold', 10, ...
    'MaxEpochs', 4000 ...
    );

net = trainNetwork(XTrain,YTrain,layers,options);
end