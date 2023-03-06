function [p] = plot_cut(failure, cut_normal)
    xrange = linspace(-8, 8);
    yrange = (dot(failure, cut_normal) - cut_normal(1)*xrange)/cut_normal(2);
    p=line(xrange, yrange, 'Linewidth', 2);
    p.Color=[0 0.4470 0.7410 0.5];
%     quiver(failure(1), failure(2), cut_normal(1), cut_normal(2), 10);
end