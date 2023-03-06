function [cut_normal] = get_cut(start, att, failure, visited, x0)
    % expect single failure and get single cut, multiple visited
    if isempty(failure)
        cut_normal = [];
        return
    end
    loss = @(x) ((att-failure)'*x)^2 / norm(att-failure);
    att_box = [att+[0.4 0]', att+[-0.4 0]', att+[0 0.4]', att+[0 -0.4]'];
    visited = [visited, start, att, att_box];
    options = optimoptions("fmincon","Algorithm","interior-point","EnableFeasibilityMode",true,"SubproblemAlgorithm","cg");    
    cut_normal = fmincon(loss, x0, (visited-failure)', zeros(size(visited,2),1),[],[],[],[], @normal, options);
    
    function [c, ceq] = normal(x)
        c = [];
        ceq = (norm(x))-1;
    end
end