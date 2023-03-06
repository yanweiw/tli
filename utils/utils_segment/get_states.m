function get_states(data, objs, save_dir)
% get states from object ap region for specification inference
for i=1:length(data) % drawn data contains multiple trajectories
    M_state = zeros(size(data{i}(1, :)));
    M_state(end) = 1;
    states = [M_state];
    for j=1:length(objs) % each obj is an ap region
        rect = objs{j}.pos;
        states = [states;
                  all([data{i}(1:2, :) >= transpose(rect(1:2)); ...
                       data{i}(1:2, :) <= transpose(rect(1:2)) ...
                                        + transpose(rect(3:4))])];
    end
    predicates.WaypointPredicates = states;
    predicates.ThreatPredicates = [];
    predicates.PositionPredicates = zeros(size(states));
    
    predicates_json = jsonencode(predicates);
    fid = fopen(save_dir + "/states.json",'w'); % states for whole traj
    fprintf(fid, predicates_json); 
end