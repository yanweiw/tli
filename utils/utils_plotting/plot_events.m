function [ps] = plot_events(visited, failure)
    ps = [];
    for i=1:size(visited, 2)
        p=plot(visited(1,i), visited(2,i), 'o');
        p.MarkerFaceColor = [0.9290, 0.6940, 0.1250];
        p.MarkerSize = 10;
        p.MarkerEdgeColor = [0.9290, 0.6940, 0.1250];
        ps = [ps p];
    end
    for i=1:size(failure, 2)
        p=plot(failure(1,i), failure(2,i), 'xr', 'Linewidth', 2);
        p.MarkerSize = 10;
        ps = [ps, p];
    end
end