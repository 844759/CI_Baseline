function section4_attenuation_v2(cfg)
%SECTION4_ATTENUATION_V2 Comparacion mas conservadora para attenuation.
%
% Idea: el artefacto en forma de anillo suele venir sobre todo de la
% correccion por coseno en angulos rasantes. Esta version usa una
% compensacion muy suave, practicamente distance-only.

outDir = fullfile(cfg.resultsDir, 'section_4_attenuation_v2');
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
    fprintf('[ATT-V2] No se encontro %s\n', datasetFile);
    return;
end

ds = load_nlos_dataset(datasetFile);
voxelRes = cfg.attenuation.voxelRes;
wallStride = cfg.attenuation.wallStride;

opts0.wallStride = wallStride;
opts0.compensateAttenuation = false;
opts0.useAbsAfterComplex = false;

[G0, ~] = nlos_backprojection(ds, voxelRes, opts0);

% Version muy conservadora:
% - distancia suave
% - sin correccion angular explicita
% - clamp bajo
optsV2.wallStride = wallStride;
optsV2.compensateAttenuation = true;
optsV2.useAbsAfterComplex = false;
optsV2.attenuationMode = 'soft';
optsV2.attenuationDistanceExponent = 0.5;
optsV2.attenuationCosineExponent = 0.0;
optsV2.attenuationCosineMin = 0.30;
optsV2.attenuationMaxWeight = 2.0;

[Gv2, ~] = nlos_backprojection(ds, voxelRes, optsV2);

render_volume_views(G0, fullfile(outDir, 'without_compensation'), ...
    sprintf('%s without compensation', ds.fileName), cfg.render);
render_volume_views(Gv2, fullfile(outDir, 'with_conservative_compensation'), ...
    sprintf('%s with conservative compensation', ds.fileName), cfg.render);

fid = fopen(fullfile(outDir, 'attenuation_params.txt'), 'w');
fprintf(fid, 'dataset = %s\n', ds.fileName);
fprintf(fid, 'voxelRes = %d\n', voxelRes);
fprintf(fid, 'wallStride = %d\n', wallStride);
fprintf(fid, 'distanceExponent = %.4f\n', optsV2.attenuationDistanceExponent);
fprintf(fid, 'cosineExponent = %.4f\n', optsV2.attenuationCosineExponent);
fprintf(fid, 'cosineMin = %.4f\n', optsV2.attenuationCosineMin);
fprintf(fid, 'maxWeight = %.4f\n', optsV2.attenuationMaxWeight);
fclose(fid);
end
