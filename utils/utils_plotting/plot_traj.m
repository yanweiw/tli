function [hd] = plot_traj(seg)
% plot trajectory segments 
hd = scatter(seg.Data(1,:), seg.Data(2,:),10,[0 0 0],'filled');
% hd = scatter(seg.drawn_data(1,:), seg.drawn_data(2,:),10,[1 0 0],'filled');
end