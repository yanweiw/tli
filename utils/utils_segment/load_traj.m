function [segs, hds, h_atts] = load_traj(do_segment, data_dir, objs)

if ~do_segment
    segs{1} = load(data_dir+'/traj.mat').seg;
    hds{1} = plot_traj(segs{1});
    h_atts = [];
else
    ap_idx = 1;
    while isfile(data_dir+'/seg'+num2str(ap_idx,'%02d')+'.mat')
        segs{ap_idx} = load(data_dir+'/seg'+num2str(ap_idx,'%02d')+'.mat').seg;
        hds{ap_idx} = scatter(segs{ap_idx}.Data(1,:),segs{ap_idx}.Data(2,:), ...
                 'MarkerFaceColor', objs{ap_idx}.color, 'MarkerEdgeColor', [1 1 1]); 
        % plot att
        h_atts{ap_idx} = plot(segs{ap_idx}.att(1), segs{ap_idx}.att(2), 'o');
        h_atts{ap_idx}.MarkerFaceColor = [1 0.5 0];
        h_atts{ap_idx}.MarkerSize = 15;
        h_atts{ap_idx}.MarkerEdgeColor = [1 0.5 0];
%         h_atts{ap_idx} = scatter(segs{ap_idx}.att(1),segs{ap_idx}.att(2),150,[0 0 0],'d','Linewidth',2);
        ap_idx = ap_idx+1;
    end
end

end