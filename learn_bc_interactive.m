%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Learning BC policy using NN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear all; clc

base_wd = 'tli'; % base working directory to save data
experiment = 'scoop_seed_00';
experiment_dir = "experiments/" + experiment;
ap_alpha = 0;

%% Load and Plot Data
drawn_data = load(experiment_dir+'/traj.mat').seg;
[~, limits, ~] = plot_ap(ap_alpha);
plot_traj(drawn_data);
data = drawn_data.Data';
XTrain = data(:, 1:2);
YTrain = data(:, 3:4);

%% Design Network
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

%% Training 
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
    'MaxEpochs', 5000 ...
    );

net = trainNetwork(XTrain,YTrain,layers,options);

%% Eval
nx=200;
ny=200;
axlim = limits;
ax_x=linspace(axlim(1),axlim(2),nx); % computing the mesh points along each axis
ax_y=linspace(axlim(3),axlim(4),ny); % computing the mesh points along each axis
[x_tmp, y_tmp]=meshgrid(ax_x,ax_y);  % meshing the input domain
x=[x_tmp(:), y_tmp(:)]';
xd = predict(net, x')';
[fig1, limits, objs] = plot_ap(ap_alpha);
plot_traj(drawn_data);
h = streamslice(x_tmp,y_tmp,reshape(xd(1,:),ny,nx),reshape(xd(2,:),ny,nx),4,'method','cubic');
set(h,'LineWidth', 0.75)
set(h,'color',[0.0667  0.0667 0.0667]);

%% Save
save(experiment_dir+'/bc.mat', "net")