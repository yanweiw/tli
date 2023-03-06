function [models] = load_ds(do_segment, model_dir)

if ~do_segment
    ds = load(model_dir+'/ds.mat');
    ds.ds_lpv = @(x) lpv_ds(x, ds.ds_gmm, ds.A_k, ds.b_k);
    models{1} = ds;
else
    ap_idx = 1;
    while isfile(model_dir+'/ds'+num2str(ap_idx,'%02d')+'.mat')
        ds = load(model_dir+'/ds'+num2str(ap_idx,'%02d')+'.mat');
        ds.ds_lpv = @(x) lpv_ds(x, ds.ds_gmm, ds.A_k, ds.b_k);    
        models{ap_idx} = ds;
        ap_idx = ap_idx+1;
    end    
end

end