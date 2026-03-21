function section4_attenuation(cfg)
%SECTION4_ATTENUATION Ilustra el efecto de compensar atenuacion.

outDir = fullfile(cfg.resultsDir, 'section_4_attenuation');
ensure_dir(outDir);

candidates = {
    fullfile(cfg.datasetDir, cfg.files.z), 'Z'; ...
    fullfile(cfg.datasetDir, cfg.files.bunnyConfocal), 'bunny_confocal'
};

for i = 1:size(candidates, 1)
    datasetFile = candidates{i,1};
    tag = candidates{i,2};

    if ~exist(datasetFile, 'file')
        fprintf('[WARN] No se encontro %s\n', datasetFile);
        continue;
    end

    ds = load_nlos_dataset(datasetFile);

    opts0.wallStride = cfg.attenuation.wallStride;
    opts0.compensateAttenuation = false;
    opts0.useAbsAfterComplex = false;

    opts1 = opts0;
    opts1.compensateAttenuation = true;

    [G0, ~] = nlos_backprojection(ds, cfg.attenuation.voxelRes, opts0);
    [G1, ~] = nlos_backprojection(ds, cfg.attenuation.voxelRes, opts1);

    dsOut = fullfile(outDir, tag);
    ensure_dir(dsOut);
    render_volume_views(G0, fullfile(dsOut, 'without_compensation'), sprintf('%s without compensation', ds.fileName), cfg.render);
    render_volume_views(G1, fullfile(dsOut, 'with_compensation'), sprintf('%s with compensation', ds.fileName), cfg.render);

    fprintf('[ATTENUATION] %s hecho\n', ds.fileName);
end
end
