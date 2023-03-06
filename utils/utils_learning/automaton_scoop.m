function [next_mode, task_succ, desired_plan] = automaton_scoop(curr_mode, x, objs, atts)
    % given current mode, and x position predict next mode
    % Use curr_mode instead of mode, where mode i
    desired_plan = [2, 3, 4, 4]; % next_mode = desired_plan(curr_mode)
    sensor = 1; % default reaching mode
    task_succ = 0;

    for i=1:length(objs)
        if inap(x, objs{i}, atts{i})
            sensor = i+1;
        end
    end

    if curr_mode == 1 % reaching mode
        if sensor == 2
            next_mode = 2;
            return
        else
            next_mode = 1;
            return
        end

    elseif curr_mode == 2 % scooping mode
        if sensor == 3
            next_mode = 3;
            return
        elseif sensor == 1
            next_mode = 1;
            return
        else
            next_mode = 2;
            return
        end

    elseif curr_mode == 3 % transporting mode
        if sensor == 1
            next_mode = 1;
            return
        elseif sensor == 2
            next_mode = 2;
            return
        elseif sensor == 3
            next_mode = 3;
            return
        elseif sensor == 4 % task success
            next_mode = 4; 
            task_succ = 1;
            return
        else
            error('Wrong mode transition: %d -> %d',  mode, sensor);
        end
    elseif curr_mode == 4 % task success
        next_mode = 4;
        task_succ = 1;
        return
    else
        error('Wrong mode transition: %d -> %d',  mode, sensor);
    end
end