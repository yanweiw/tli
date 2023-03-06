function start_simulation(policy, opt_sim)
    % This function is used by single_mode.m
    % Expects a single start
    [fig, limits, objs] = plot_ap(0);
    V = opt_sim.V;
    att = opt_sim.att;
    start = opt_sim.start;
    plot_convex_mode(V, att, start);


    % define dynamics
    if isempty(policy) % if policy = [], use linear ds
        policy = @(x) (att-x)/norm(att-x); 
        opt_sim.if_mod = 0;
    end

    policy_handle = plot_policy(policy, limits);

    % Set perturbations with the mouse
    pert_force = zeros(2,1);
    dim = 2;
    x_to_plot = ones(dim,50) .* start;
    traj_handle = [];
    set(gcf,'WindowButtonDownFcn',@start_perturbation);
    visited = [];
    failure = [];
    cut_handles = [];
    cut_normals = [];

    while 1
        x = x_to_plot(:,2);
        if (isempty(failure) || ~opt_sim.if_mod)
            x_dot = policy(x);
        else
            x_dot = modulate_by_cut(x, policy, att, visited, cut_normals);
            % use nomial policy if x is in mode but outside cut (thus 0 vel)
            if sum(x_dot) == 0 && inhull(x', V)
                x_dot = policy(x);
            end
        end
        
        % euler integration
        if strcmp(opt_sim.pert_tag, 'pos') % position perturbation
            x = x + x_dot*opt_sim.dt;
        else % velocity perturbation
            x = x + (x_dot+pert_force) * opt_sim.dt;
        end
        x_to_plot(:,1) = x; 

        % check if x is in mode
        if ~inhull(x', V)
            x_prev = x_to_plot(:, 2);
            visited = [x_prev, visited]; % for cutting plane checking
            failure = [x, failure]; % place cuts
            plot_events(x_prev, failure);
            
            % optimize and plot cuts
            if opt_sim.if_mod
                for i=1:length(cut_handles)
                    delete(cut_handles(i))
                end
                for i=1:size(failure, 2)
                    if size(cut_normals,2) < i
    %                     x0s = null((att-failure(:,i))');
    %                     x0 = x0s(:,1);
                        x0 = failure(:, i) - (att+start)/2;
                        x0 = x0 / vecnorm(x0);
                    else
                        x0 = cut_normals(:,i);
                    end
                    cut_normal = get_cut(start, att, visited(:, i), visited, x0);
                    cut_normals(:, i) = cut_normal;
                    p = plot_cut(visited(:, i), cut_normals(:, i));
                    cut_handles = [cut_handles, p];
                end
            end

            % reset to original starting location after mode exit
            x_to_plot = ones(dim,50) .* start;
            pert_force = 0;
            set(gcf,'WindowButtonMotionFcn',[]);
            
            % modulate to plot the new vector field
            if opt_sim.if_mod
                policy_mod = @(x) modulate_by_cut(x, policy, att, visited, cut_normals);
            else
                policy_mod = policy;
            end
            delete(traj_handle);
            traj_handle = [];
            delete(policy_handle);
            policy_handle = plot_policy(policy_mod, limits);
        end

        % Plot next point
%         delete(traj_handle);
        traj_handle = [traj_handle, plot(x_to_plot(1,1), x_to_plot(2,1), '.', 'Linewidth', 2, ...
                            'Color', [abs(sum(pert_force))>0 0. 0.], 'MarkerSize', 7)];
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
%             if strcmp(opt_sim.pert_tag, 'pos') % position perturbation
%                 pert_force = 1*(motionData(:,end)-motionData(:,1));
%                 x_to_plot = x_to_plot + pert_force;
%             end
            delete(hand)
            delete(hand2)
            set(gcf,'WindowButtonMotionFcn',[]);
            set(gcf,'WindowButtonUpFcn',[]);
            pert_force = zeros(2,1);
            assignin('base', 'pert_force', pert_force);
        end
    
    
        function perturbation_from_mouse(~,~)
            x = get(gca,'Currentpoint');
            x = x(1,1:2)';
            motionData = [motionData, x];
%             if strcmp(opt_sim.pert_tag, 'vel') % velocity perturbation        
                pert_force = 10*(motionData(:,end)-motionData(:,1));
                assignin('base', 'pert_force', pert_force);
%             end
            delete(hand2)
            hand2 = plot([motionData(1,1),motionData(1,end)],[motionData(2,1),motionData(2,end)],'-r');
        end
    end

end






