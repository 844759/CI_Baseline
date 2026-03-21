function cfg = default_cfg()
%DEFAULT_CFG Centraliza rutas y parametros del pipeline.

thisFile = mfilename('fullpath');
if isempty(thisFile)
    projectDir = pwd;
else
    projectDir = fileparts(thisFile);
end

datasetDir = fullfile(projectDir, 'datasets');
if ~exist(datasetDir, 'dir')
    datasetDir = projectDir;
end

resultsDir = fullfile(projectDir, 'results_modular');
ensure_dir(resultsDir);

cfg.projectDir = projectDir;
cfg.datasetDir = datasetDir;
cfg.resultsDir = resultsDir;

cfg.files.z = 'Z_d=0.5_l=[1x1]_s=[256x256].mat';
cfg.files.usaf = 'usaf_d=0.5_l=[1x1]_s=[256x256].mat';
cfg.files.bunnyNonConfocal = 'bunny_d=0.5_l=[1x1]_s=[256x256].mat';
cfg.files.bunnyConfocal = 'bunny_d=0.5_c=[256x256].mat';

% Configuracion razonable para no eternizar la implementacion naive
cfg.study.configs = [ ...
    16 16; ...
    16  8; ...
    16  1; ...
    32 16; ...
    32  8; ...
    64 16  ...
];

cfg.bunny.voxelRes = 32;
cfg.bunny.wallStride = 8;
cfg.attenuation.voxelRes = 32;
cfg.attenuation.wallStride = 8;

% Sweep phasor/Morlet corregido segun el guion.
cfg.phasor.voxelRes = 32;
cfg.phasor.wallStride = 8;

% lambda_c debe ser al menos 2 * spacing_efectivo.
% Estos multiplicadores se aplican sobre lambdaMin = 2 * spacingEff.
cfg.phasor.lambdaMultipliers = [1 2 4];

% Sigma se toma con los tres valores recomendados por el enunciado.
cfg.phasor.useRecommendedSigmas = true;

cfg.phasor.applyLoG = true;
cfg.phasor.logSigma = 1.0;
cfg.phasor.saveBaselineConfocalLoG = true;

% La geometria de estos datos suele tener la profundidad en Y.
cfg.render.frontCollapseDim = 2;
cfg.render.topCollapseDim = 3;
cfg.render.sideCollapseDim = 1;
end
