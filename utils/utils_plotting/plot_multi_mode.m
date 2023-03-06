function [hs] = plot_multi_mode(hs, policy, limits, att, visited, failure, cut_normals)
    for j=1:length(hs)
        delete(hs(j));
    end
    % plot vector field
    policy_handle = plot_policy(policy, limits);
    % plot att
    att_handle = plot(att(1), att(2), 'o');
    att_handle.MarkerFaceColor = [1 0.5 0];
    att_handle.MarkerSize = 15;
    att_handle.MarkerEdgeColor = [1 0.5 0];
    % plot failure events
%     events_handle = plot_events(visited, failure);
    % plot cut
    cut_handles = [];
    for i=1:size(visited, 2)
        cut_handle = plot_cut(visited(:, i), cut_normals(:,i));
        cut_handles = [cut_handles, cut_handle];
    end
    hs = [policy_handle', att_handle, cut_handles];%, events_handle];
end