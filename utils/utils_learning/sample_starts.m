function [starts] = sample_starts(num, noise_level, opt_sim)
    % sample #num of data points and add guassian noise 
    data = opt_sim.Data(1:2, :);
    V = opt_sim.V;
    starts = zeros(2, num);
    bfr = 0.1; % buffer from boundary
    for i=1:num
        candidate = datasample(data, 1, 2);
        if ~inhull(candidate', V)
            error('Orignial data not in mode')
        end
        cand_ = candidate + normrnd(0, noise_level, [2, 1]);
        cand_box = [cand_+[bfr 0]', cand_+[-bfr 0]', cand_+[0 bfr]', cand_+[0 -bfr]'];
        while ~all(inhull(cand_box', V))
            cand_ = candidate + normrnd(0, noise_level, [2, 1]);
            cand_box = [cand_+[bfr 0]', cand_+[-bfr 0]', cand_+[0 bfr]', cand_+[0 -bfr]'];
        end
        starts(:, i) = cand_;
    end
end