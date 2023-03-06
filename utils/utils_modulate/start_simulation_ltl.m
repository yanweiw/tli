function start_simulation_ltl(policies, transition, opt_sim)
    % expects a single start, with automaton for mode transitions
    [fig, limits, objs] = plot_ap(0.2);
    atts = opt_sim.atts;
    start = opt_sim.start;
    curr_mode = 1; %starting mode
    [curr_mode, task_succ, target_mode] = transition(curr_mode, start, objs, atts);
    visited_set = {}; % per mode visited set
    failure_set = {};
    cut_normals = {};
    mod_policies = {}; % modulated policies
    for k=1:length(target_mode)
        visited_set{k} = [];
        failure_set{k} = [];
        cut_normals{k} = [];
        mod_policies{k} = policies{k};
    end
    hs = plot_multi_mode([], mod_policies{curr_mode}, limits, atts{curr_mode}, [], [], []);
    
    % Set perturbations with the mouse
    pert_force = zeros(2,1);
    dim = 2;
    x_to_plot = ones(dim,50) .* start;
    traj_handle = [];
    set(gcf,'WindowButtonDownFcn',@start_perturbation);
    time_step = 1;
    while time_step > 0
        x = x_to_plot(:,2); % x_to_plot(:,1) will be rewritten
        x_dot = mod_policies{curr_mode}(x);
            
        % use nomial policy if x is in mode but outside cut (thus 0 vel)
        if sum(x_dot) == 0 
            x_dot = policies{curr_mode}(x);
        end
        
        max_norm=10;
        x_dot_norm_orig = vecnorm(x_dot);
        scaling = ones(size(x_dot_norm_orig));
        exceed_idx = x_dot_norm_orig>max_norm;
        scaling(exceed_idx)=max_norm ./ x_dot_norm_orig(exceed_idx);
        x_dot = x_dot .* scaling;

        % add noise
        if opt_sim.add_noise && mod(time_step, 150) == 0
            noise = normrnd(0, 200, [2, 1]);
            x_dot = x_dot + noise;
        end

        % euler integration
        x = x + (x_dot+pert_force) * opt_sim.dt;
        x_to_plot(:,1) = x; 
        x_query = x_to_plot(:, 20); % can query any 2-50 positions
        % detect mode transitions
        if ~task_succ % task success
            [next_mode, task_succ, desired_plan] = transition(curr_mode, x_query, objs, atts);
            if (next_mode ~= curr_mode) && ~task_succ % mode transition detected
                % for stopping to get images for paper
                set(gcf,'WindowButtonDownFcn',[]); 
                set(gcf,'WindowButtonDownFcn',@start_perturbation);
                if next_mode ~= desired_plan(curr_mode) && opt_sim.if_mod % unexpected transition                    
                    % record failures and optimize cuts
                    visited_set{curr_mode} = [x_query, visited_set{curr_mode}]; % for cutting plane checking
                    failure_set{curr_mode} = [x, failure_set{curr_mode}]; % place cuts
                    events_handle = plot_events([], x_query);
                    failure = failure_set{curr_mode};
                    visited = visited_set{curr_mode};
                    for i=1:size(visited, 2)
                        if size(cut_normals{curr_mode},2) < i
                            x0 = failure(:, i) - visited(:, i);
                            x0 = x0 / vecnorm(x0); % x0 is the initial guess of normal direction of cut
                        else
                            x0 = cut_normals{curr_mode}(:,i);
                        end
                        cut_normal = get_cut(atts{curr_mode-1}, atts{curr_mode}, visited(:, i), visited, x0);
                        cut_normals{curr_mode}(:, i) = cut_normal;
                    end
                    mod_policies{curr_mode} = @(x) modulate_by_cut(x, policies{curr_mode}, ...
                        atts{curr_mode}, visited_set{curr_mode}, cut_normals{curr_mode});                    
                end

                % both desired and undesired mode change
                delete(traj_handle);
                traj_handle = [];
                hs = plot_multi_mode(hs, mod_policies{next_mode}, limits, atts{next_mode}, ...
                    visited_set{next_mode}, failure_set{next_mode}, cut_normals{next_mode});
                % reset to original starting location after mode exit
                x_to_plot = ones(dim,50) .* x;
                pert_force = 0;
                set(gcf,'WindowButtonMotionFcn',[]);
            end
            curr_mode = next_mode;
        end

        traj_handle = [traj_handle, plot(x_to_plot(1,1), x_to_plot(2,1), '.', 'Linewidth', 2, ...
                    'Color', [abs(sum(pert_force))>0 0. 0.], 'MarkerSize', 7)];
        x_to_plot = circshift(x_to_plot,1,2);
        time_step = time_step + 1;
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
            pert_force = 10*(motionData(:,end)-motionData(:,1));
            assignin('base', 'pert_force', pert_force);
            delete(hand2)
            hand2 = plot([motionData(1,1),motionData(1,end)],[motionData(2,1),motionData(2,end)],'-r');
        end
    end

end






