%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Single Mode Disturbance Analysis %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear all; clc

seed = 0;
train_seed = 0;
sample_seed = 0;
rng(seed);
base_wd = 'tli'; % base working directory to save data
experiment = 'single_mode_seed_'; % experiment tag
experiment_dir = "experiments/" + experiment + num2str(seed, '%02.f');
do_erase_exp = 0; % if erase past data
ap_alpha = 0;

%% Draw 2D Dataset with GUI
% make folders to store drawing
reset_wd(base_wd); % run this everytime about to save something
if exist(experiment_dir, 'dir')==7 % folder exists
    if do_erase_exp
        delete(experiment_dir+"/*");
    else
        error('Experiment exists, try different name to avoid erasing past data')
    end
else
    mkdir(experiment_dir)
end

% plotting 
[fig1, limits, objs] = plot_ap(ap_alpha);

    % sample convex shape
    num_vert = 10;
    xmin=limits(1); xmax=limits(2);  ymin=limits(3); ymax=limits(4);
    sample_range = [xmax-xmin ymax-ymin] * 0.75;
    sample_mean = sample_range / 2;
    V = rand(num_vert, 2) .* sample_range - sample_mean;
    [V_k,av] = convhull(V);

    % sample attractor
    sorted_V = sortrows(V(V_k,:), 1);
    v1 = sorted_V(length(V_k)-1,:);
    v2 = sorted_V(length(V_k),:);
    v3 = sorted_V(1,:);
    v4 = sorted_V(2,:);
    ratio = rand();
    att = 0.9*(v1 * ratio + v2*(1-ratio))'+0.05*v3' + 0.05*v4';
    
    % sample start
    start = sorted_V(1,:)';

plot_convex_mode(V(V_k,:), att, start);

% draw demo;
[drawn_data, drawn_hp] = draw_mouse_data_on_DS(fig1, limits);

% save drawn data
segs{1}.drawn_data = drawn_data;
segs{1}.V = V;
segs{1}.V_k = V_k;
segs{1}.att = att;
segs{1}.start = start;
[Data, Data_sh, att, x0_all, dt] = processDrawnData(drawn_data); % to get att
segs{1}.Data=Data; segs{1}.Data_sh=Data_sh; segs{1}.att=att; segs{1}.x0_all=x0_all; segs{1}.dt=dt;
save(experiment_dir+'/traj.mat', "segs")

%% Load Drawn Data, Learn and Save DS
reset_wd(base_wd); % run this everytime about to save something
[segs, fig2, limits] = load_data(base_wd, experiment_dir);
plot_traj(segs{1});

rng(train_seed); % setting the seed for DS learning
visualize_gmm = 0; % 0 or 1

segs{1}.constr_type = 2; % refer to learn_lpvds for details
segs{1}.do_plots = 0; % 0 or 1 for visulizing plots
segs{1}.vel_samples = 10; segs{1}.vel_size=0.5; % refer to learn_lpvds
[ds_gmm, ds_lpv, A_k, b_k, P_est, est_options] = learn_lpvds(segs{1});
plot_policy(ds_lpv, limits); % ds_lpv is the learned result, lpv_ds is a script

if visualize_gmm
    [~, est_labels] =  my_gmm_cluster(segs{1}.Data(1:2,:), ...
            models{1}.ds_gmm.Priors, models{1}.ds_gmm.Mu, ...
            models{1}.ds_gmm.Sigma, 'hard', []);
    [~] = plotGMMParameters(segs{1}.Data(1:2,:), est_labels, ...
            models{1}.ds_gmm.Mu, models{1}.ds_gmm.Sigma, fig);
end

% save DS
DS_name = "ds"; % DS learned on whole traj
save_lpvDS_to_Mat(DS_name, experiment_dir, ds_gmm, A_k, b_k, ...
    segs{1}.att, segs{1}.x0_all, segs{1}.dt, P_est, segs{1}.constr_type, est_options)

%% Load Drawn Data, Learn and Save BC
[segs, fig3, limits] = load_data(base_wd, experiment_dir);
plot_traj(segs{1});

rng(train_seed); % setting the seed for BC learning
net = learn_bc(segs{1});
bc_policy = @(x) double(predict(net, x'))';
plot_policy(bc_policy, limits);

% Save
BC_name = "bc";
matfile = strcat(experiment_dir, '/', BC_name,'.mat');
save(matfile, "net");

%% Load DS
[segs, fig4, limits] = load_data(base_wd, experiment_dir);
[models] = load_ds(0, experiment_dir);
ds_policy = models{1}.ds_lpv;
plot_policy(ds_policy, limits);
plot_traj(segs{1});

%% Load BC
[segs, fig5, limits] = load_data(base_wd, experiment_dir);
net = load(experiment_dir+'/bc.mat').net;
bc_policy = @(x) double(predict(net, x'))';
plot_policy(bc_policy, limits);
plot_traj(segs{1});

%% Simulate
opt_sim = [];
opt_sim.dt    = 0.005; %0.002;   
opt_sim.i_max = 10000;
opt_sim.tol   = 0.001;
opt_sim.plot  = 0;
opt_sim.att   = segs{1}.att;
opt_sim.V     = segs{1}.V(segs{1}.V_k,:);
opt_sim.Data  = segs{1}.Data;
opt_sim.start = segs{1}.start;
opt_sim.pert_tag = 'vel'; % or 'pos'
opt_sim.if_mod= 0; % if modulate 0 or 1
opt_sim.if_plot = 1; % boolean

%% Interactive Simulation
opt_sim.if_mod=1;
start_simulation(bc_policy, opt_sim);
% start_simulation(ds_policy, opt_sim);

%% Batch Simulate
run_5_seeds = 0; % 1 or 0
opt_sim.if_mod=0;
opt_sim.if_plot = ~run_5_seeds;

if run_5_seeds
    seed_plan = [0 1 2 3 4];
else
    seed_plan = [0];
end

bc_succ = [];
bc_rch = [];
bc_inv = [];
ds_succ = [];
ds_rch = [];
ds_inv = [];
for sample_seed=seed_plan

    bc_stats_succ = [];
    bc_stats_rch = [];
    bc_stats_inv = [];
    ds_stats_succ = [];
    ds_stats_rch = [];
    ds_stats_inv = [];
    fprintf('\nSample seed: %d\n', sample_seed);
    for i=[0 1 5] % noise_level: guassian noise std, 
        rng(sample_seed);
        starts = sample_starts(100, i, opt_sim); 
        [reached, inmode, succ, ~, ~] = batch_simulate(bc_policy, starts, opt_sim);
        bc_stats_succ = [bc_stats_succ succ];   
        bc_stats_rch = [bc_stats_rch reached];
        bc_stats_inv = [bc_stats_inv inmode];
        fprintf('\nBC policy with noise: %d, success rate: %2f, reached: %2f, inmode: %2f\n', i, succ, reached, inmode);
    
        [reached, inmode, succ, ~, ~] = batch_simulate(ds_policy, starts, opt_sim);
        ds_stats_succ = [ds_stats_succ succ];
        ds_stats_rch = [ds_stats_rch reached];
        ds_stats_inv = [ds_stats_inv inmode];
        fprintf('DS policy with noise: %d, success rate: %2f, reached: %2f, inmode: %2f\n', i, succ, reached, inmode);
    end
    bc_succ = [bc_succ; bc_stats_succ];
    bc_rch = [bc_rch; bc_stats_rch];
    bc_inv = [bc_inv; bc_stats_inv];
    ds_succ = [ds_succ; ds_stats_succ];    
    ds_rch = [ds_rch; ds_stats_rch];
    ds_inv = [ds_inv; ds_stats_inv];
end
if run_5_seeds
    reset_wd(base_wd); % run this everytime about to save something
    writematrix(bc_succ, strcat(experiment_dir, '/', 'bc_succ.txt'))
    writematrix(bc_rch, strcat(experiment_dir, '/', 'bc_rch.txt'))
    writematrix(bc_inv, strcat(experiment_dir, '/', 'bc_inv.txt'))
    writematrix(ds_succ, strcat(experiment_dir, '/', 'ds_succ.txt'))
    writematrix(ds_rch, strcat(experiment_dir, '/', 'ds_rch.txt'))
    writematrix(ds_inv, strcat(experiment_dir, '/', 'ds_inv.txt'))    
end

%% Batch Simulate with Modulation
% close all;
% clc;
    
sample_seed = 0;
rng(sample_seed);
opt_sim.if_plot = 1;
opt_sim.orig_policy = ds_policy; % ds or bc policy
opt_sim.if_mod= 1; % if modulate 0 or 1

noise_level = 5;
starts = sample_starts(100, noise_level, opt_sim);
succ = 0;
cut_succ = zeros(1, 5);
failure_set = [];
visited_set = [];
failure = [];
visited = [];

for cut_num =0:4
    if succ<1
        if ~isempty(failure)
            failure_set = [failure_set, failure(:, 1)];
            visited_set = [visited_set, visited(:, 1)];
        end
        cut_normals = [];
        
        for j=1:size(failure_set, 2)
            init_guess = failure_set(:, j) - (opt_sim.att+opt_sim.start)/2;
            cut_normal = get_cut(opt_sim.start, opt_sim.att, visited_set(:,j), visited_set, init_guess);
            cut_normals(:, j) = cut_normal;
        end
        mod_policy = @(x) modulate_by_cut(x, opt_sim.orig_policy, opt_sim.att, visited_set, cut_normals);
        [~, ~, succ, failure, visited] = batch_simulate(mod_policy, starts, opt_sim);
        fprintf('\n\nCut number: %d, success rate: %2f\n\n', cut_num, succ);
        cut_succ(cut_num+1) = succ;
        for j=1:size(failure_set, 2)
            plot_cut(visited_set(:, j), cut_normals(:, j));
            plot_events(visited_set(:, j), failure_set(:, j));
        end
    else
        cut_succ(cut_num+1) = 1;
    end
end
reset_wd(base_wd);
writematrix(cut_succ, strcat(experiment_dir, '/', 'ds_mod_succ_', num2str(noise_level), '.txt'))



%% Helper

function reset_wd(folder_name)
% function to reset working directory to 'ds-opt'
curr_wd = pwd;
if ~contains(curr_wd, folder_name)
    error('ds-opt not on path')
end
while ~contains(curr_wd(end-5:end), folder_name)
    disp(curr_wd);
    cd ..;
    curr_wd = pwd;
end
end

function [segs, fig, limits] = load_data(base_wd, experiment_dir)
    reset_wd(base_wd); % run this everytime about to save something
    [fig, limits, objs] = plot_ap(0);
    segs = load(experiment_dir+'/traj.mat').segs;
    plot_convex_mode(segs{1}.V(segs{1}.V_k,:), segs{1}.att, segs{1}.start);
end