function segment_ap_entry(data, objs, save_dir)
% segment drawn data upon new ap region entry, i.e. when atomic propositions
% , aka the sensor first changes value
segs = cell(1,length(objs));
for i=1:length(data)
    prev_t = 1;
    for j=1:length(objs)
        state_change{j}.inROI = false; state_change{j}.track = [];
    end
    for t=1:size(data{i}, 2)
        for j=1:length(objs)
            rect = objs{j}.pos;
            if ~state_change{j}.inROI
                if all(data{i}(1:2, t) >= transpose(rect(1:2))) && ...
                   all(data{i}(1:2, t) <= transpose(rect(1:2)) ...
                                    + transpose(rect(3:4)))
                    state_change{j}.inROI = true;
                    
                    segs{j}{end+1} = data{i}(:, prev_t:t);
                    prev_t = t+1;
                end
            end
        end
    end
end

% save segments
for i=1:length(segs)
    seg={};
    seg.drawn_data = segs{i};
    [Data, Data_sh, att, x0_all, dt] = processDrawnData(seg.drawn_data); % to get att
    seg.Data=Data; seg.Data_sh=Data_sh; seg.att=att; seg.x0_all=x0_all; seg.dt=dt;
    save(save_dir+'/seg'+num2str(i,'%02d')+'.mat', 'seg')
end

end