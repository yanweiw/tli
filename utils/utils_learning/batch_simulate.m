function [rch_rate, inv_rate, succ_rate, failure, visited] = batch_simulate(policy, start, opt_sim)
% batch simulate trajectories to test mode invariance
% expect multiple starts in a batch
    if opt_sim.if_plot
        [fig, limits, objs] = plot_ap(0);
%       title('')
        plot_convex_mode(opt_sim.V, opt_sim.att, opt_sim.start);
        data = opt_sim.Data;
        scatter(data(1,:), data(2,:),20,[0 0 0],'filled')
    end
    V = opt_sim.V;
    opt_sim.dt = 0.01;

    % define dynamics
    if isempty(policy) % if policy = [], use linear ds
        policy = @(x) (att-x)/norm(att-x); 
        opt_sim.if_mod = 0;
    end
    if opt_sim.if_plot
        policy_handle = plot_policy(policy, limits);
    end

    time_step = 1;
    time_max = 1000;
    invariance = ones(1, size(start,2));
    trajectory = reshape(repmat(start, 1, time_max), [size(start), time_max]);
    failure = [];
    visited = [];
    while time_step <= time_max
        x = trajectory(:, :, time_step);
        in_mode = inhull(x', V)'; % shape (num_x, 1)
        if time_step > 1 % sampled started do not contain failures
            failure = [failure trajectory(:, logical((~in_mode).*invariance), time_step)];
            visited = [visited trajectory(:, logical((~in_mode).*invariance), time_step-1)];
        end
        invariance = invariance .* in_mode;
        x_dot = policy(x);
        if opt_sim.if_mod
            orig_x_dot = opt_sim.orig_policy(x);
%             use_orig = logical((sum(x_dot) == 0).*inhull(x', V)');
            use_orig = (sum(x_dot) == 0);
            x_dot(:, use_orig) = orig_x_dot(:, use_orig);
        end
        time_step = time_step + 1;
        % capping the control input
        max_norm=20;
        x_dot_norm_orig = vecnorm(x_dot);
        scaling = ones(size(x_dot_norm_orig));
        exceed_idx = x_dot_norm_orig>max_norm;
        scaling(exceed_idx)=max_norm ./ x_dot_norm_orig(exceed_idx);
        x_dot = x_dot .* scaling;
        trajectory(:, :, time_step) = x + x_dot * opt_sim.dt;
    end

    reached = zeros(1, size(start,2));
    success = zeros(1, size(start,2));
    for i=1:size(start,2)
        if vecnorm(trajectory(:, i, time_max)-opt_sim.att) < 0.4 % goal reached
            reached(i) = 1;
        end
        success(i) = reached(i) * invariance(i);
        if opt_sim.if_plot
            X = trajectory(1, i, :);
            Y = trajectory(2, i, :);
            if success(i)
                h = plot(X(:), Y(:));
                set(h,'color',[0, 0, 1, 0.5]);
            else
                h = plot(X(:), Y(:));
                set(h,'color',[1, 0, 0, 0.5]);                
%                 set(h,'LineWidth', 2);
            end
            set(h,'LineWidth', 2);
        end
    end
    inv_rate = sum(invariance) / length(invariance);
    rch_rate = sum(reached) / length(reached);
    succ_rate = sum(success) / length(success);
end