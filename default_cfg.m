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

% Sweep corto para phasor/Morlet
cfg.phasor.voxelRes = 32;
cfg.phasor.wallStride = 8;
cfg.phasor.lambdaFactors = [1.5 2.5 3.5];
cfg.phasor.sigmaFactors = [0.5 1.0 1.5];
cfg.phasor.applyLoG = true;

% La geometria de estos datos suele tener la profundidad en Y.
% Por eso la "vista frontal" recomendable colapsa Y.
cfg.render.frontCollapseDim = 2;
cfg.render.topCollapseDim = 3;
cfg.render.sideCollapseDim = 1;
end
