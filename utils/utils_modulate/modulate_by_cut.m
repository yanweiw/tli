function [XD] = modulate_by_cut(X, policy, att, failure, cut_normals)
    % load params
    ref = att;
    npower = 1;
    XD = feval(policy, X);
    if isempty(cut_normals)
        return
    end
    cut_gammas = [];
    tan_space = [];
    dist_to_cut = [];
    
    if isempty(failure)
        return
    end

    for k=1:size(cut_normals,2)
        % build tangent space of each cut
        tan_space(:, :, k) = null(cut_normals(:, k)');
        % check gamma for collision 
        vec_ref_f = failure(:,k) - ref;
        vec_x_f = failure(:,k) - X; % X here is matrix
        ref_f_ortho_component = vec_ref_f' * cut_normals(:,k); % normals pointing outwards
        x_f_ortho_component = vec_x_f' * cut_normals(:,k); % shape (num_x, 1)
        dist_to_cut(k, :) = x_f_ortho_component';
        cut_gammas(k, :) = max(0, 1 - x_f_ortho_component / ref_f_ortho_component)'; % max to make floor 0
    end % cut_gammas of shape (num_failures, num_x)

    % have to run a for loop as M matrix is different for each x location
    for i=1:size(XD, 2) 
        x = X(:, i);
        xd = XD(:, i);
        % compute reference direction
        vec_ref_x = x-ref;
        dist_ref_x = vecnorm(vec_ref_x);
        if dist_ref_x == 0
            XD(:, i) = 0;
            continue
        end
%         if_zero = (dist_ref_x == 0);  % check where dist_ref_x is 0, return 0 vel there
        ref_direction = vec_ref_x / (dist_ref_x); 
        % compute tangent space of each cut
        if any(cut_gammas(:, i)>1) % outside of cut
            M= 0;
        else
            into_boundary = cut_normals' * xd > 0; % approaching boundary away from ref
%             shortest_sdf_idx = argmax(cut_gammas(:, i) .* into_boundary); 
            shortest_sdf_idx = argmax((1e6-dist_to_cut(:, i)) .* into_boundary); % dist_to_cut is a better criteria than cut_gamma
%             [~, shortest_sdf_idx] = max(cut_gammas .* into_boundary, [], 1); % shape shortest_sdf_idx (1, num_x)
%             shortest_one_hot = (shortest_sdf_idx==(1:size(failure,2))'); % shape (num_failure, num_x)
            tangent = tan_space(:, :, shortest_sdf_idx);
            
            E = [ref_direction tangent];
            if cut_normals(:, shortest_sdf_idx)'*xd > 0 
                L = [1-cut_gammas(shortest_sdf_idx, i)^npower 0
                     0 1]; 
            else
                L=[1 0
                   0 1];
            end
            M=E*L*inv(E);
        end
        XD(:, i) = M*xd;
    end
end
