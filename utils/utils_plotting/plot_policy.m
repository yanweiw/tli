function [h] = plot_policy(policy, limits)
    nx=100;
    ny=100;
    axlim = limits;
    ax_x=linspace(axlim(1),axlim(2),nx); % computing the mesh points along each axis
    ax_y=linspace(axlim(3),axlim(4),ny); % computing the mesh points along each axis
    [x_tmp, y_tmp]=meshgrid(ax_x,ax_y);  % meshing the input domain
    x=[x_tmp(:), y_tmp(:)]';
    
    xd = policy(x);
%     xd = xd ./ vecnorm(xd);
%     h = quiver(x(1, :), x(2, :), xd(1, :), xd(2, :), 20);
    h = streamslice(x_tmp,y_tmp,reshape(xd(1,:),ny,nx),reshape(xd(2,:),ny,nx),4,'method','cubic');
    set(h,'LineWidth', 0.75)
    set(h,'color',[0.0667  0.0667 0.0667, 0.3]);
    grid off
end