function plot_convex_mode(V, att, start)
% draw a single convex mode with a list of vertices V

% plot convex mode
h=plot(V(:, 1), V(:, 2), '--k');
set(h,'LineWidth', 5)

% plot att
p=plot(att(1), att(2), 'o');
p.MarkerFaceColor = [1 0.5 0];
p.MarkerSize = 15;
p.MarkerEdgeColor = [1 0.5 0];

% plot start
p=plot(start(1), start(2), 'ok');
p.MarkerSize = 15;
p.MarkerFaceColor = [0., 0., 0];

end