%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Temporal Logic Imitation: Learning Plan-Satisficing Motion Policies %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear all; clc

seed=0; 
base_wd = 'tli'; % base working directory to save data
experiment = 'scoop_seed_'; % experiment tag
experiment_dir = "experiments/" + experiment + num2str(seed, '%02.f');
do_erase_exp = 0; % 0 or 1: if erase past data
do_segment = 0; % 0 or 1: if learning on a whole demo or segments of the demo
num_of_ap = 3; % # of ap regions -> first # of objs
ap_alpha = 0.2; % transparency of ploting ap regions

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

% drawing in ;
[fig1, limits, objs] = plot_ap(.5);
[drawn_data, drawn_hp] = draw_mouse_data_on_DS(fig1, limits);

% save drawn data
seg.drawn_data = drawn_data;
[Data, Data_sh, att, x0_all, dt] = processDrawnData(drawn_data); % to get att
seg.Data=Data; seg.Data_sh=Data_sh; seg.att=att; seg.x0_all=x0_all; seg.dt=dt;
save(experiment_dir+'/traj.mat', "seg")

%% Segment Data
reset_wd(base_wd);
drawn_data = load(experiment_dir+'/traj.mat').seg.drawn_data;
segment_ap_entry(drawn_data, objs(1:num_of_ap), experiment_dir)
% gets states for specification inference
get_states(drawn_data, objs(1:num_of_ap), experiment_dir)

%% Run Learning
if do_erase_exp
    rng(0); 
    for do_segment=0:1
        %% Load Drawn Data
        load_seg = do_segment; % 0 or 1
        
        reset_wd(base_wd); % run this everytime about to save something
        [fig2, limits, objs] = plot_ap(ap_alpha);
        [segs, hds, h_atts] = load_traj(load_seg, experiment_dir, objs);
        
        %% Learn and Save DS
        constr_type = 2; % refer to learn_lpvds for details
        do_plots = 0; % 0 or 1 for visulizing plots
        vel_samples = 10; vel_size=0.5; % refer to learn_lpvds
        
        reset_wd(base_wd);
        for i=1:length(segs)
            segs{i}.constr_type = constr_type;
            segs{i}.do_plots = do_plots;
            segs{i}.vel_samples = vel_samples;
            segs{i}.vel_size = vel_size;
            [ds_gmm, ds_lpv, A_k, b_k, P_est, est_options] = learn_lpvds(segs{i});
            
            if ~load_seg
                DS_name = "ds"; % DS learned on whole traj
            else
                DS_name = "ds"+ num2str(i,'%02d');
            end
            save_lpvDS_to_Mat(DS_name, experiment_dir, ds_gmm, A_k, b_k, ...
                segs{i}.att, segs{i}.x0_all, segs{i}.dt, P_est, segs{i}.constr_type, est_options)
        end
    end
end
%% Load DS
for do_segment=0:1
    
    load_seg = do_segment; % 0 or 1
    visualize_gmm = 0; % 0 or 1
    reset_wd(base_wd); % run this everytime about to save something
    [fig2, limits, objs] = plot_ap(ap_alpha);
    [segs, hds, h_atts] = load_traj(load_seg, experiment_dir, objs);
    [models] = load_ds(load_seg, experiment_dir);
    
    % visualize
    for i=1:length(models)
        [fig, limits] = plot_ap(ap_alpha);
        [hs] = plot_ds_model(fig, models{i}.ds_lpv, models{i}.att, limits, 'medium');
        plot_traj(segs{i});
        if visualize_gmm
            [~, est_labels] =  my_gmm_cluster(segs{i}.Data(1:2,:), ...
                    models{i}.ds_gmm.Priors, models{i}.ds_gmm.Mu, ...
                    models{i}.ds_gmm.Sigma, 'hard', []);
            [~] = plotGMMParameters(segs{i}.Data(1:2,:), est_labels, ...
                    models{i}.ds_gmm.Mu, models{i}.ds_gmm.Sigma, fig);
        end
    end

end

%% Simulation
opt_sim = [];
opt_sim.dt    = 0.005; 
opt_sim.i_max = 10000;
opt_sim.tol   = 0.001;
opt_sim.plot  = 0;
opt_sim.start = segs{1}.x0_all(:, 1);
atts = {}; % one attractor for each DS
policies = {}; % one DS policy for each mode
for i = 1:length(segs)
    atts{i} = segs{i}.att;
    policies{i} = models{i}.ds_lpv;
end
policies{end+1} = policies{end}; % success mode
atts(:, end+1) = atts(:, end);
opt_sim.atts   = atts;
opt_sim.if_mod= 1; % if modulate 0 or 1
opt_sim.if_plot = 1; % boolean
opt_sim.add_noise = 0; % if add noise

transition = @(mode, x, objs, atts) automaton_scoop(mode, x, objs, atts);
start_simulation_ltl(policies, transition, opt_sim);

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