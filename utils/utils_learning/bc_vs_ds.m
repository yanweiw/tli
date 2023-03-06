function bc_vs_ds(varargin)
policy_tag = 'ds';
experiment = 'ds_vs_bc_scoop'; % experiment tag
if nargin > 0
    policy_tag = varargin{1};
end
if nargin > 1
    experiment = varargin{2};        
end
%% Load model %%%%%%%%
experiment_dir = "experiments/" + experiment;
net = load(experiment_dir+'/bc.mat').net;
bc_policy = @(x) predict(net, x')';
disp(experiment_dir);
data = load(experiment_dir+'/ds.mat');

ds_lpv = @(x) lpv_ds(x, data.ds_gmm, data.A_k, data.b_k);

%% Load and Plot Data
ap_alpha = 0.2;
if policy_tag == 'ds'
    policy = ds_lpv;
else
    policy = bc_policy;
end
drawn_data = load(experiment_dir+'/traj.mat').seg;
[~, limits, ~] = plot_ap(ap_alpha);
plot_traj(drawn_data);
nx=200;
ny=200;
axlim = limits;
ax_x=linspace(axlim(1),axlim(2),nx); % computing the mesh points along each axis
ax_y=linspace(axlim(3),axlim(4),ny); % computing the mesh points along each axis
[x_tmp, y_tmp]=meshgrid(ax_x,ax_y);  % meshing the input domain
x=[x_tmp(:), y_tmp(:)]';
xd = policy(x);
h = streamslice(x_tmp,y_tmp,reshape(xd(1,:),ny,nx),reshape(xd(2,:),ny,nx),4,'method','cubic');
set(h,'LineWidth', 0.75)
set(h,'color',[0.0667  0.0667 0.0667 0.3]);

%% Simulate sampled replayed trajectories

opt_sim = [];
opt_sim.dt    = 0.005; %0.002;   
opt_sim.i_max = 10000;
opt_sim.tol   = 0.001;
opt_sim.plot  = 0;

x_start = [-4 4]';
opt_sim.pert_tag = 'vel'; % or 'vel'

start_simulation(x_start, policy, opt_sim);

function start_simulation(x_start, ds_mod, opt_sim)

    % Set perturbations with the mouse
    pert_force = zeros(2,1);
    dim = 2;
    x_to_plot = ones(dim,50) .* x_start;
    traj_handle = [];
    set(gcf,'WindowButtonDownFcn',@start_perturbation);
    
    while 1
        x = x_to_plot(:,2);
        x_dot = ds_mod(x);
        % euler integration
        if strcmp(opt_sim.pert_tag, 'pos') % position perturbation
            x = x + x_dot*opt_sim.dt;
        else % velocity perturbation
            x = x + (x_dot+pert_force) * opt_sim.dt;
        end
        x_to_plot(:,1) = x; 
        % Plot next point
        delete(traj_handle);
        traj_handle = plot(x_to_plot(1,1:10:end), x_to_plot(2,1:10:end), 'o', 'Linewidth', 2, ...
                            'Color', [0.1 0.8 0.2], 'MarkerSize', 7);
        x_to_plot = circshift(x_to_plot,1,2);
        drawnow;
    end
    
    % Perturbations with the mouse
    function start_perturbation(~,~)
        motionData = [];
        set(gcf,'WindowButtonMotionFcn',@perturbation_from_mouse);
        x = get(gca,'Currentpoint');
        x = x(1,1:2)';
        hand = plot(x(1),x(2),'r.','markersize',20);
        hand2 = plot(x(1),x(2),'r.','markersize',20);
        set(gcf,'WindowButtonUpFcn',@(h,e)stop_perturbation(h,e));
    
        function stop_perturbation(~, ~)
            if strcmp(opt_sim.pert_tag, 'pos') % position perturbation
                pert_force = 1*(motionData(:,end)-motionData(:,1));
                x_to_plot = x_to_plot + pert_force;
            end
            delete(hand)
            delete(hand2)
            set(gcf,'WindowButtonMotionFcn',[]);
            set(gcf,'WindowButtonUpFcn',[]);
            pert_force = zeros(2,1);
        end
    
    
        function perturbation_from_mouse(~,~)
            x = get(gca,'Currentpoint');
            x = x(1,1:2)';
            motionData = [motionData, x];
            if strcmp(opt_sim.pert_tag, 'vel') % velocity perturbation        
                pert_force = 10*(motionData(:,end)-motionData(:,1));
            end
            delete(hand2)
            hand2 = plot([motionData(1,1),motionData(1,end)],[motionData(2,1),motionData(2,end)],'-r');
        end
    end
end

end