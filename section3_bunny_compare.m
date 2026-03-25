function section3_bunny_compare(cfg)
%SECTION3_BUNNY_COMPARE

outDir = fullfile(cfg.resultsDir, 'section_3_bunny');
ensure_dir(outDir);

ncFile = fullfile(cfg.datasetDir, cfg.files.bunnyNonConfocal);
cFile  = fullfile(cfg.datasetDir, cfg.files.bunnyConfocal);

if ~exist(ncFile, 'file') || ~exist(cFile, 'file')
    error('Faltan bunny no confocal o confocal.');
end

dsNC = load_nlos_dataset(ncFile);
dsC  = load_nlos_dataset(cFile);

opts.wallStride = cfg.bunny.wallStride;
opts.compensateAttenuation = false;
opts.useAbsAfterComplex = false;

tic; [Gnc, ~] = nlos_backprojection(dsNC, cfg.bunny.voxelRes, opts); tNC = toc;
tic; [Gc,  ~] = nlos_backprojection(dsC,  cfg.bunny.voxelRes, opts); tC  = toc;

Gnc_log = apply_volume_filter(Gnc, 'log', 1.0);
Gc_log  = apply_volume_filter(Gc,  'log', 1.0);

render_volume_views(Gnc,     fullfile(outDir, 'bunny_nonconfocal_raw'), 'Bunny non-confocal raw', cfg.render);
render_volume_views(Gnc_log, fullfile(outDir, 'bunny_nonconfocal_log'), 'Bunny non-confocal LoG', cfg.render);
render_volume_views(Gc,      fullfile(outDir, 'bunny_confocal_raw'),    'Bunny confocal raw', cfg.render);
render_volume_views(Gc_log,  fullfile(outDir, 'bunny_confocal_log'),    'Bunny confocal LoG', cfg.render);

rows = {
    string(dsNC.fileName), dsNC.isConfocal, cfg.bunny.voxelRes, cfg.bunny.wallStride, tNC, "raw/log";
    string(dsC.fileName),  dsC.isConfocal,  cfg.bunny.voxelRes, cfg.bunny.wallStride, tC,  "raw/log"
};
T = cell2table(rows, 'VariableNames', {'dataset', 'isConfocal', 'voxelResolution', 'wallStride', 'seconds', 'filters'});
writetable(T, fullfile(outDir, 'timings_section3.csv'));

fprintf('[BUNNY] non-confocal %.3fs | confocal %.3fs\n', tNC, tC);
end
