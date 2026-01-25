%% =========================================================
%  Extract DU15 network time series from fsLR10k CIFTI dtseries
%  Vertex-wise detrend (NaN-aware)
%  Network-level average (DCM-ready)
%  Using FieldTrip ft_read_cifti
%% =========================================================

clc; clear;

%% ---------------- Paths ----------------
roi_file = '/Users/xuerufan/DCM-Project-PhD-Study3-/output/ROI_fsLR10k/DU15Net_fsLR10k.dscalar.nii';
data_dir = '/Volumes/Zuolab_XRF/data/abide/fslr10k/';
out_dir  = '/Volumes/Zuolab_XRF/data/abide/timeseries/';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

nROI = 15;

%% ---------------- Load ROI ----------------
roi_cifti = ft_read_cifti(roi_file);
roi_vec   = roi_cifti.dscalar(:);   % [20484 × 1]

assert(numel(roi_vec) == 20484, 'Unexpected ROI size');

%% ---------------- Find dtseries ----------------
files = dir(fullfile(data_dir, '*_func.dtseries.nii'));
files = files(~startsWith({files.name}, '._'));

%% =========================================================
for i = 1:numel(files)

    func_file = fullfile(files(i).folder, files(i).name);
%     fprintf('Processing %s\n', files(i).name);

    func_cifti = ft_read_cifti(func_file);
    full_data  = func_cifti.dtseries(1:20484, :);  % cortex only

    if size(full_data,1) ~= numel(roi_vec)
        error('Vertex mismatch: %s', files(i).name);
    end

    nTime = size(full_data, 2);
    ROI_ts = nan(nROI, nTime);

    %% ---------------- Network loop ----------------
    for r = 1:nROI

        mask = (roi_vec == r);
        assert(any(mask), 'Empty DU15Net%d', r);

        ts = full_data(mask, :);          % [nVertex × nTime]
        ts_detrend = nan(size(ts));

        %% ---------- Vertex-wise detrend ----------
        for v = 1:size(ts,1)

            v_ts = ts(v,:);
            good = ~isnan(v_ts);

            % 至少需要足够多的有效时间点
            if sum(good) <= 10
                continue;
            end

            v_valid = v_ts(good);

            % 手写零方差检查（Windows / Mac 都稳定）
            if max(v_valid) == min(v_valid)
                continue;
            end

            v_ts_d = v_ts;
            v_ts_d(good) = detrend(v_valid, 'linear');
            ts_detrend(v,:) = v_ts_d;
        end

        %% ---------- Network average ----------
        ROI_ts(r,:) = nanmean(ts_detrend, 1);

    end

    %% ---------------- Parse filename ----------------
    fname = files(i).name;
    parts = split(fname, '_');

    siteName = parts{1};
    subName  = parts{2};

    %% ---------------- Save ----------------
    out_file = fullfile(out_dir, [subName '_DU15_network_ts.mat']);
    save(out_file, 'ROI_ts', 'siteName', 'subName');

end

fprintf('DONE!\n');
