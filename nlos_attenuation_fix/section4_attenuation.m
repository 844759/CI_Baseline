function section4_attenuation(cfg)
%SECTION4_ATTENUATION Compara sin compensacion, soft y opcionalmente full.

outDir = fullfile(cfg.resultsDir, 'section_4_attenuation');
ensure_dir(outDir);

run_one(cfg, cfg.files.z, fullfile(outDir, 'Z'));

bunnyNcPath = fullfile(cfg.datasetDir, cfg.files.bunnyNonConfocal);
bunnyCPath  = fullfile(cfg.datasetDir, cfg.files.bunnyConfocal);
if exist(bunnyNcPath, 'file')
    run_one(cfg, cfg.files.bunnyNonConfocal, fullfile(outDir, 'bunny_nonconfocal'));
elseif exist(bunnyCPath, 'file')
    run_one(cfg, cfg.files.bunnyConfocal, fullfile(outDir, 'bunny_confocal'));
end
end

function run_one(cfg, fileName, outDir)
ensure_dir(outDir);

datasetFile = fullfile(cfg.datasetDir, fileName);
if ~exist(datasetFile, 'file')
    fprintf('[ATT] No se encontro %s\n', datasetFile);
    return;
end

ds = load_nlos_dataset(datasetFile);
voxelRes = cfg.attenuation.voxelRes;
wallStride = cfg.attenuation.wallStride;

opts0.wallStride = wallStride;
opts0.compensateAttenuation = false;
opts0.useAbsAfterComplex = false;

tic;
[G0, ~] = nlos_backprojection(ds, voxelRes, opts0);
t0 = toc;

optsSoft.wallStride = wallStride;
optsSoft.compensateAttenuation = true;
optsSoft.useAbsAfterComplex = false;
optsSoft.attenuationMode = 'soft';
optsSoft.attenuationDistanceExponent = 1.0;
optsSoft.attenuationCosineExponent = 0.5;
optsSoft.attenuationCosineMin = 0.20;
optsSoft.attenuationMaxWeight = 8.0;

tic;
[Gsoft, ~] = nlos_backprojection(ds, voxelRes, optsSoft);
tSoft = toc;

render_volume_views(G0, fullfile(outDir, 'without_compensation'), ...
    sprintf('%s without compensation', ds.fileName), cfg.render);
render_volume_views(Gsoft, fullfile(outDir, 'with_soft_compensation'), ...
    sprintf('%s with soft compensation', ds.fileName), cfg.render);

fid = fopen(fullfile(outDir, 'attenuation_params.txt'), 'w');
fprintf(fid, 'dataset = %s\n', ds.fileName);
fprintf(fid, 'voxelRes = %d\n', voxelRes);
fprintf(fid, 'wallStride = %d\n', wallStride);
fprintf(fid, 'soft.distanceExponent = %.4f\n', optsSoft.attenuationDistanceExponent);
fprintf(fid, 'soft.cosineExponent = %.4f\n', optsSoft.attenuationCosineExponent);
fprintf(fid, 'soft.cosineMin = %.4f\n', optsSoft.attenuationCosineMin);
fprintf(fid, 'soft.maxWeight = %.4f\n', optsSoft.attenuationMaxWeight);
fprintf(fid, 'time_without = %.8f\n', t0);
fprintf(fid, 'time_soft = %.8f\n', tSoft);
fclose(fid);

rows = {
    string(ds.fileName), "none", voxelRes, wallStride, t0;
    string(ds.fileName), "soft", voxelRes, wallStride, tSoft
};
T = cell2table(rows, 'VariableNames', {'dataset','mode','voxelRes','wallStride','seconds'});
writetable(T, fullfile(outDir, 'attenuation_summary.csv'));
end
