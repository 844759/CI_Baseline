function section1_transients(cfg)
%SECTION1_TRANSIENTS Visualize the transient slices of the datasets.

outDir = fullfile(cfg.resultsDir, 'section_1_transients');
ensure_dir(outDir);

candidates = {
    fullfile(cfg.datasetDir, cfg.files.z), ...
    fullfile(cfg.datasetDir, cfg.files.usaf), ...
    fullfile(cfg.datasetDir, cfg.files.bunnyNonConfocal), ...
    fullfile(cfg.datasetDir, cfg.files.bunnyConfocal)
};

for k = 1:numel(candidates)
    if exist(candidates{k}, 'file')
        ds = load_nlos_dataset(candidates{k});
        visualize_transient_slices(ds, outDir);
        fprintf('[OK] Transient: %s\n', ds.fileName);
    else
        fprintf('[WARN] not found: %s\n', candidates{k});
    end
end
end
