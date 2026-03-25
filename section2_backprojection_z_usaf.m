function section2_backprojection_z_usaf(cfg)
%SECTION2_BACKPROJECTION_Z_USAF

outDir = fullfile(cfg.resultsDir, 'section_2_backprojection');
ensure_dir(outDir);

timingRows = {};

datasets = {
    fullfile(cfg.datasetDir, cfg.files.z), 'Z'; ...
    fullfile(cfg.datasetDir, cfg.files.usaf), 'USAF'
};

for i = 1:size(datasets, 1)
    datasetFile = datasets{i,1};
    datasetTag  = datasets{i,2};

    if ~exist(datasetFile, 'file')
        fprintf('[WARN] No se encontro %s\n', datasetFile);
        continue;
    end

    ds = load_nlos_dataset(datasetFile);
    dsOut = fullfile(outDir, datasetTag);
    ensure_dir(dsOut);

    for ii = 1:size(cfg.study.configs, 1)
        vr = cfg.study.configs(ii,1);
        ws = cfg.study.configs(ii,2);

        opts.wallStride = ws;
        opts.compensateAttenuation = false;
        opts.useAbsAfterComplex = false;

        tic;
        [G, ~] = nlos_backprojection(ds, vr, opts);
        elapsed = toc;

        G_lap = apply_volume_filter(G, 'laplacian');
        G_log = apply_volume_filter(G, 'log', 1.0);

        tag = sprintf('vox%d_stride%d', vr, ws);
        render_volume_views(G, fullfile(dsOut, [tag '_raw']), sprintf('%s raw', ds.fileName), cfg.render);
        render_volume_views(G_lap, fullfile(dsOut, [tag '_lap']), sprintf('%s lap', ds.fileName), cfg.render);
        render_volume_views(G_log, fullfile(dsOut, [tag '_log']), sprintf('%s log', ds.fileName), cfg.render);

        timingRows(end+1,:) = {string(ds.fileName), ds.isConfocal, vr, ws, elapsed, "raw/lap/log"}; %#ok<AGROW>
        fprintf('[%s] vox=%d stride=%d time=%.3fs\n', datasetTag, vr, ws, elapsed);
    end
end

if ~isempty(timingRows)
    T = cell2table(timingRows, 'VariableNames', ...
        {'dataset', 'isConfocal', 'voxelResolution', 'wallStride', 'seconds', 'filters'});
    writetable(T, fullfile(outDir, 'timings_section2.csv'));
end
end
