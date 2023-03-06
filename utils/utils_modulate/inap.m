function [b] =  inap(x, obj, att)
    % check if state x is in ap region defined by obj
    pos = obj.pos;
    vertices = [pos(1:2); [pos(1)+pos(3), pos(2)]; [pos(1), pos(2)+pos(4)]; ...
               [pos(1)+pos(3), pos(2)+pos(4)]];
        b = inhull(x', vertices) || vecnorm(x - att) < 0.4; % x will enter the next ap region if close to attractor
end