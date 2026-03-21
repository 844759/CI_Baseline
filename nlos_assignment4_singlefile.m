%% nlos_assignment4_singlefile.m
% Versión en un solo fichero para la práctica de NLOS imaging.
%
% Uso:
%   1) Pon este .m en una carpeta.
%   2) Deja en esa misma carpeta, o en una subcarpeta llamada datasets/, estos archivos:
%        Z_d=0.5_l=[1x1]_s=[256x256].mat
%        usaf_d=0.5_l=[1x1]_s=[256x256].mat
%        bunny_d=0.5_l=[1x1]_s=[256x256].mat
%        bunny_d=0.5_c=[256x256].mat
%   3) Ejecuta este script en Matlab.
%
% Genera resultados en la carpeta results_singlefile/.

%% Assignment 4 - NLOS imaging
% Script principal para ejecutar toda la práctica.
% Ajusta datasetDir a la carpeta donde están los .mat.

clear; clc;

thisFile = mfilename('fullpath');
if isempty(thisFile)
    projectDir = pwd;
    thisDir = projectDir;
else
    thisDir = fileparts(thisFile);
    projectDir = thisDir;
end

datasetDir = fullfile(projectDir, 'datasets');
if ~exist(datasetDir, 'dir')
    datasetDir = projectDir; % permite dejar los .mat junto al script
end
resultsDir = fullfile(projectDir, 'results_singlefile');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

addpath(thisDir);

%% Datasets esperados
zFile      = fullfile(datasetDir, 'Z_d=0.5_l=[1x1]_s=[256x256].mat');
usafFile   = fullfile(datasetDir, 'usaf_d=0.5_l=[1x1]_s=[256x256].mat');
bunnyNCFile = fullfile(datasetDir, 'bunny_d=0.5_l=[1x1]_s=[256x256].mat');
bunnyCFile  = fullfile(datasetDir, 'bunny_d=0.5_c=[256x256].mat');

%% Sección 2.1 - Visualización x-t / y-t
section21Dir = fullfile(resultsDir, 'section_2_1');
if ~exist(section21Dir, 'dir'), mkdir(section21Dir); end

candidateFiles = {zFile, usafFile, bunnyNCFile, bunnyCFile};
for k = 1:numel(candidateFiles)
    if exist(candidateFiles{k}, 'file')
        ds = load_nlos_dataset(candidateFiles{k});
        visualize_transient_slices(ds, section21Dir);
    else
        fprintf('[WARN] No se encontró: %s\n', candidateFiles{k});
    end
end

%% Sección 2.2 - Backprojection, resolución, submuestreo y filtrado
section22Dir = fullfile(resultsDir, 'section_2_2');
if ~exist(section22Dir, 'dir'), mkdir(section22Dir); end

timingTable = table();

if exist(zFile, 'file')
    dsZ = load_nlos_dataset(zFile);
    Tz = run_resolution_study(dsZ, fullfile(section22Dir, 'Z'));
    timingTable = [timingTable; Tz]; %#ok<AGROW>
end

if exist(usafFile, 'file')
    dsUSAF = load_nlos_dataset(usafFile);
    Tusaf = run_resolution_study(dsUSAF, fullfile(section22Dir, 'USAF'));
    timingTable = [timingTable; Tusaf]; %#ok<AGROW>
end

%% Compensación de atenuación (pedida en la introducción)
if exist(zFile, 'file')
    run_attenuation_compensation(load_nlos_dataset(zFile), fullfile(section22Dir, 'attenuation_Z'));
end
if exist(bunnyNCFile, 'file')
    run_attenuation_compensation(load_nlos_dataset(bunnyNCFile), fullfile(section22Dir, 'attenuation_bunny_nonconfocal'));
elseif exist(bunnyCFile, 'file')
    run_attenuation_compensation(load_nlos_dataset(bunnyCFile), fullfile(section22Dir, 'attenuation_bunny_confocal'));
end

%% Sección 3 - Comparación confocal / no confocal con bunny
section3Dir = fullfile(resultsDir, 'section_3');
if ~exist(section3Dir, 'dir'), mkdir(section3Dir); end
if exist(bunnyNCFile, 'file') && exist(bunnyCFile, 'file')
    Tconf = run_confocal_comparison(bunnyNCFile, bunnyCFile, section3Dir);
    timingTable = [timingTable; Tconf]; %#ok<AGROW>
else
    fprintf('[WARN] Faltan datasets bunny confocal/no confocal para la sección 3.\n');
end

%% Sección 4 - Filtrado Morlet / phasor-based
section4Dir = fullfile(resultsDir, 'section_4');
if ~exist(section4Dir, 'dir'), mkdir(section4Dir); end

if exist(bunnyCFile, 'file')
    Tphasor1 = run_phasor_experiment(load_nlos_dataset(bunnyCFile), fullfile(section4Dir, 'bunny_confocal'));
    timingTable = [timingTable; Tphasor1]; %#ok<AGROW>
end
if exist(usafFile, 'file')
    Tphasor2 = run_phasor_experiment(load_nlos_dataset(usafFile), fullfile(section4Dir, 'usaf_nonconfocal'));
    timingTable = [timingTable; Tphasor2]; %#ok<AGROW>
end

%% Guardar tabla de tiempos
if ~isempty(timingTable)
    writetable(timingTable, fullfile(resultsDir, 'timings_summary.csv'));
end

fprintf('\nProceso completado. Revisa la carpeta: %s\n', resultsDir);



function ds = load_nlos_dataset(filePath)
%LOAD_NLOS_DATASET Carga un dataset .mat de la práctica y unifica su acceso.

raw = load(filePath);
rawFields = fieldnames(raw);
if numel(rawFields) == 1 && isstruct(raw.(rawFields{1}))
    s = raw.(rawFields{1});
else
    s = raw;
end

if ~isfield(s, 'data')
    error('El dataset no contiene el campo "data".');
end

A = double(s.data);

[~, fileName, ext] = fileparts(filePath);
ds.filePath = filePath;
ds.fileName = [fileName ext];

ds.deltaT = scalarize(getFieldOr(s, {'deltaT'}, 1));
ds.t0 = scalarize(getFieldOr(s, {'t0'}, 0));

ds.volumePosition = force_xyz(getFieldOr(s, {'volumePosition', 'hiddenVolumePosition'}, [0 0 0]), [0 0 0]);
ds.volumeSize = force_xyz(getFieldOr(s, {'volumeSize', 'hiddenVolumeSize'}, [1 1 1]), [1 1 1]);

ds.laserPosition = force_xyz(getFieldOr(s, {'laserOrigin', 'laserPosition'}, [0 0 0]), [0 0 0]);
ds.cameraPosition = force_xyz(getFieldOr(s, {'spadOrigin', 'cameraPosition'}, [0 0 0]), [0 0 0]);

laserGridPosRaw = getFieldOr(s, {'laserGridPositions', 'laserPositions'}, []);
cameraGridPosRaw = getFieldOr(s, {'cameraGridPositions', 'spadPositions'}, []);
laserGridNRaw   = getFieldOr(s, {'laserGridNormals', 'laserNormals'}, []);
cameraGridNRaw  = getFieldOr(s, {'cameraGridNormals', 'spadNormals'}, []);

ds.laserGridPoints = infer_grid_points(laserGridPosRaw);
ds.cameraGridPoints = infer_grid_points(cameraGridPosRaw);

ds.isConfocal = infer_is_confocal(getFieldOr(s, {'isConfocal'}, []), A, ds.fileName);

ds.laserGridPositions = positions_to_grid(laserGridPosRaw, ds.laserGridPoints);
ds.cameraGridPositions = positions_to_grid(cameraGridPosRaw, ds.cameraGridPoints);

ds.laserGridNormals = normals_to_grid(laserGridNRaw, ds.laserGridPoints, [0 0 1]);
ds.cameraGridNormals = normals_to_grid(cameraGridNRaw, ds.cameraGridPoints, [0 0 1]);

ds.timeNormalized = infer_time_normalization(ds.fileName);
ds.H = collapse_bounces(A, ds.isConfocal);
end

function value = getFieldOr(s, names, defaultValue)
value = defaultValue;
for i = 1:numel(names)
    if isfield(s, names{i})
        value = s.(names{i});
        return;
    end
end
end

function x = rowvec(x)
x = double(x(:)).';
end

function x = scalarize(x)
x = double(x);
if isempty(x)
    x = 0;
else
    x = x(1);
end
end

function x = force_xyz(x, defaultValue)
if nargin < 2
    defaultValue = [0 0 0];
end
if isempty(x)
    x = defaultValue;
    return;
end
x = rowvec(x);
if isscalar(x)
    x = [x x x];
elseif numel(x) ~= 3
    x = defaultValue;
end
end

function tf = infer_is_confocal(explicitFlag, A, fileName)
if ~isempty(explicitFlag)
    tf = logical(explicitFlag(1));
    return;
end

if contains(fileName, '_c=[')
    tf = true;
    return;
elseif contains(fileName, '_l=[') || contains(fileName, '_s=[')
    tf = false;
    return;
end

nd = ndims(A);
if nd == 3 || nd == 4
    tf = true;
elseif nd == 5 || nd == 6
    tf = false;
else
    error('No se pudo inferir si el dataset es confocal o no confocal.');
end
end

function tf = infer_time_normalization(fileName)
tf = contains(fileName, 'usaf_d=0.5_l=[1x1]_s=[256x256]') || ...
     contains(fileName, 'bunny_d=0.5_c=[256x256]');
end

function gp = infer_grid_points(P)
if isempty(P)
    gp = [1 1];
    return;
end

sz = size(P);

if ndims(P) == 3 && sz(3) == 3
    gp = [sz(1) sz(2)];
elseif ndims(P) == 3 && sz(1) == 3
    gp = [sz(2) sz(3)];
elseif isvector(P) && numel(P) == 3
    gp = [1 1];
elseif ismatrix(P) && (sz(1) == 3 || sz(2) == 3)
    n = max(sz);
    if n == 3
        gp = [1 1];
    else
        side = round(sqrt(n));
        if side * side == n
            gp = [side side];
        else
            gp = [n 1];
        end
    end
else
    gp = [1 1];
end
gp = double(gp(:)).';
end

function G = positions_to_grid(P, gridPoints)
% Devuelve una matriz Nx x Ny x 3.
if isempty(P)
    G = [];
    return;
end

P = double(P);
Nx = gridPoints(1);
Ny = gridPoints(2);

if ndims(P) == 3 && size(P, 3) == 3
    G = P;
    return;
elseif ndims(P) == 3 && size(P, 1) == 3
    G = permute(P, [2 3 1]);
    return;
elseif isvector(P) && numel(P) == 3
    G = reshape(rowvec(P), [1 1 3]);
    return;
elseif ismatrix(P) && size(P, 2) == 3
    G = reshape(P, [Nx, Ny, 3]);
    return;
elseif ismatrix(P) && size(P, 1) == 3
    G = reshape(P.', [Nx, Ny, 3]);
    return;
else
    error('Formato no soportado para laser/cameraGridPositions.');
end
end

function G = normals_to_grid(N, gridPoints, defaultNormal)
if isempty(N)
    G = repmat(reshape(defaultNormal, [1 1 3]), [gridPoints(1), gridPoints(2), 1]);
    return;
end

N = double(N);
Nx = gridPoints(1);
Ny = gridPoints(2);

if ndims(N) == 3 && size(N, 3) == 3
    G = N;
    return;
elseif ndims(N) == 3 && size(N, 1) == 3
    G = permute(N, [2 3 1]);
    return;
elseif isvector(N) && numel(N) == 3
    G = repmat(reshape(rowvec(N), [1 1 3]), [Nx, Ny, 1]);
    return;
elseif ismatrix(N) && size(N, 2) == 3
    G = reshape(N, [Nx, Ny, 3]);
    return;
elseif ismatrix(N) && size(N, 1) == 3
    G = reshape(N.', [Nx, Ny, 3]);
    return;
else
    G = repmat(reshape(defaultNormal, [1 1 3]), [Nx, Ny, 1]);
end
end

function H = collapse_bounces(A, isConfocal)
% Convierte el campo data en un tensor espacial + temporal,
% sumando la dimensión de bounces si existe.

sz = size(A);
while numel(sz) > 2 && sz(end) == 1
    sz(end) = [];
end
nd = numel(sz);

if isConfocal
    if nd == 4
        H = sum(A, 3);
        H = reshape(H, [sz(1), sz(2), sz(4)]);
    elseif nd == 3
        H = reshape(A, sz);
    else
        error('Formato confocal no soportado. Se esperaba [Nx Ny B T] o [Nx Ny T].');
    end
else
    if nd == 6
        H = sum(A, 5);
        H = reshape(H, [sz(1), sz(2), sz(3), sz(4), sz(6)]);
    elseif nd == 5
        H = reshape(A, sz);
    else
        error('Formato no confocal no soportado. Se esperaba [Lx Ly Sx Sy B T] o [Lx Ly Sx Sy T].');
    end
end
end

function visualize_transient_slices(ds, outDir)
%VISUALIZE_TRANSIENT_SLICES Genera cortes x-t e y-t usando imagesc y hot.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ds.isConfocal
    % H: Nx x Ny x T
    xt = squeeze(sum(ds.H, 2)); % Nx x T
    yt = squeeze(sum(ds.H, 1)); % Ny x T
else
    % H: Lx x Ly x Sx x Sy x T
    Hsum = squeeze(sum(sum(ds.H, 1), 2)); % Sx x Sy x T
    xt = squeeze(sum(Hsum, 2));
    yt = squeeze(sum(Hsum, 1));
end

xt = double(xt.');
yt = double(yt.');

make_slice_figure(xt, sprintf('%s - corte x-t', ds.fileName), ...
    fullfile(outDir, [sanitize_filename(ds.fileName), '_xt.png']), 'x');
make_slice_figure(yt, sprintf('%s - corte y-t', ds.fileName), ...
    fullfile(outDir, [sanitize_filename(ds.fileName), '_yt.png']), 'y');
end

function make_slice_figure(M, titleStr, savePath, axisName)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 500]);
imagesc(1:size(M,2), 1:size(M,1), log1p(M));
axis tight;
set(gca, 'DataAspectRatioMode', 'auto');
colormap(hot);
colorbar;
xlabel(axisName);
ylabel('bin temporal');
title(titleStr, 'Interpreter', 'none');
set(gca, 'YDir', 'normal');
exportgraphics(fig, savePath, 'Resolution', 200);
close(fig);
end

function s = sanitize_filename(s)
s = strrep(s, '.', '_');
s = strrep(s, '[', '');
s = strrep(s, ']', '');
s = strrep(s, '=', '-');
s = strrep(s, ',', '_');
end


function [G, meta] = nlos_backprojection(ds, voxelResolution, opts)
%NLOS_BACKPROJECTION Backprojection naïve para datasets confocales y no confocales.
%
% opts.wallStride               -> submuestreo sobre la pared (por defecto 1)
% opts.compensateAttenuation    -> true/false
% opts.useAbsAfterComplex       -> true/false (para H filtrada con Morlet)
% opts.overrideH                -> tensor H alternativo (p. ej. tras filtrado temporal)

if nargin < 3
    opts = struct();
end
if ~isfield(opts, 'wallStride'), opts.wallStride = 1; end
if ~isfield(opts, 'compensateAttenuation'), opts.compensateAttenuation = false; end
if ~isfield(opts, 'useAbsAfterComplex'), opts.useAbsAfterComplex = false; end
if ~isfield(opts, 'overrideH') || isempty(opts.overrideH)
    H = ds.H;
else
    H = opts.overrideH;
end

if isscalar(voxelResolution)
    voxelResolution = [voxelResolution voxelResolution voxelResolution];
end

[xv, yv, zv] = voxel_centers(ds.volumePosition, ds.volumeSize, voxelResolution);
[X, Y, Z] = ndgrid(xv, yv, zv);
voxels = [X(:), Y(:), Z(:)];
G = zeros(size(X));

if ds.isConfocal
    [G, meta] = backproject_confocal(ds, H, voxels, G, voxelResolution, opts);
else
    [G, meta] = backproject_nonconfocal(ds, H, voxels, G, voxelResolution, opts);
end

if opts.useAbsAfterComplex
    G = abs(G);
end

meta.voxelResolution = voxelResolution;
meta.numVoxels = numel(G);
end

function [G, meta] = backproject_confocal(ds, H, voxels, G, voxelResolution, opts)
Nx = size(ds.laserGridPositions, 1);
Ny = size(ds.laserGridPositions, 2);
stride = opts.wallStride;
ix = 1:stride:Nx;
iy = 1:stride:Ny;

numVox = size(voxels, 1);
for iv = 1:numVox
    xv = voxels(iv, :);
    accum = 0;

    for a = ix
        for b = iy
            xl = squeeze(ds.laserGridPositions(a, b, :)).';
            nWall = squeeze(ds.laserGridNormals(a, b, :)).';

            d2 = norm(xv - xl);
            d3 = d2;

            if ds.timeNormalized
                tof = d2 + d3;
            else
                d1 = norm(ds.laserPosition - xl);
                d4 = norm(ds.cameraPosition - xl);
                tof = d1 + d2 + d3 + d4;
            end

            tidx = 1 + round((tof - ds.t0) / ds.deltaT);
            if tidx < 1 || tidx > size(H, 3)
                continue;
            end

            val = H(a, b, tidx);

            if opts.compensateAttenuation
                dirWall = safe_normalize(xv - xl);
                cosWall = max(abs(dot(nWall, dirWall)), 1e-6);
                weight = (d2^2 * d3^2) / (cosWall^2);
                val = val .* weight;
            end

            accum = accum + val;
        end
    end

    G(iv) = accum;
end

G = reshape(G, voxelResolution);
meta.numWallSamples = numel(ix) * numel(iy);
end

function [G, meta] = backproject_nonconfocal(ds, H, voxels, G, voxelResolution, opts)
Lx = size(ds.laserGridPositions, 1);
Ly = size(ds.laserGridPositions, 2);
Sx = size(ds.cameraGridPositions, 1);
Sy = size(ds.cameraGridPositions, 2);
stride = opts.wallStride;

ilx = 1:stride:Lx;
ily = 1:stride:Ly;
isx = 1:stride:Sx;
isy = 1:stride:Sy;

numVox = size(voxels, 1);
for iv = 1:numVox
    xv = voxels(iv, :);
    accum = 0;

    for a = ilx
        for b = ily
            xl = squeeze(ds.laserGridPositions(a, b, :)).';
            nL = squeeze(ds.laserGridNormals(a, b, :)).';
            d1 = norm(ds.laserPosition - xl);
            d2 = norm(xv - xl);

            for c = isx
                for d = isy
                    xs = squeeze(ds.cameraGridPositions(c, d, :)).';
                    nS = squeeze(ds.cameraGridNormals(c, d, :)).';
                    d3 = norm(xv - xs);
                    d4 = norm(ds.cameraPosition - xs);

                    if ds.timeNormalized
                        tof = d2 + d3;
                    else
                        tof = d1 + d2 + d3 + d4;
                    end

                    tidx = 1 + round((tof - ds.t0) / ds.deltaT);
                    if tidx < 1 || tidx > size(H, 5)
                        continue;
                    end

                    val = H(a, b, c, d, tidx);

                    if opts.compensateAttenuation
                        dirL = safe_normalize(xv - xl);
                        dirS = safe_normalize(xv - xs);
                        cosL = max(abs(dot(nL, dirL)), 1e-6);
                        cosS = max(abs(dot(nS, dirS)), 1e-6);
                        weight = (d2^2 * d3^2) / (cosL * cosS);
                        val = val .* weight;
                    end

                    accum = accum + val;
                end
            end
        end
    end

    G(iv) = accum;
end

G = reshape(G, voxelResolution);
meta.numLaserSamples = numel(ilx) * numel(ily);
meta.numSpadSamples = numel(isx) * numel(isy);
end

function [xv, yv, zv] = voxel_centers(volumePosition, volumeSize, voxelResolution)
mins = volumePosition - volumeSize ./ 2;
maxs = volumePosition + volumeSize ./ 2;

xv = linspace(mins(1), maxs(1), voxelResolution(1));
yv = linspace(mins(2), maxs(2), voxelResolution(2));
zv = linspace(mins(3), maxs(3), voxelResolution(3));
end

function v = safe_normalize(v)
n = norm(v);
if n < 1e-12
    return;
end
v = v ./ n;
end


function Gf = apply_volume_filter(G, mode, sigma)
%APPLY_VOLUME_FILTER Filtrado 3D: laplaciano o LoG.
if nargin < 3
    sigma = 1.0;
end

switch lower(mode)
    case {'lap', 'laplacian'}
        h = laplacian_kernel_3d();
        Gf = imfilter(double(G), -h, 'symmetric');
    case {'log', 'laplacian-of-gaussian', 'laplacian_of_gaussian'}
        h = log_kernel_3d(7, sigma);
        Gf = imfilter(double(G), -h, 'symmetric');
    otherwise
        error('Modo de filtrado no soportado: %s', mode);
end

Gf(Gf < 0) = 0;
end

function h = laplacian_kernel_3d()
h = zeros(3, 3, 3);
h(2,2,2) = 6;
h(1,2,2) = -1; h(3,2,2) = -1;
h(2,1,2) = -1; h(2,3,2) = -1;
h(2,2,1) = -1; h(2,2,3) = -1;
end

function h = log_kernel_3d(sz, sigma)
if mod(sz, 2) == 0
    sz = sz + 1;
end
half = floor(sz/2);
[x, y, z] = ndgrid(-half:half, -half:half, -half:half);
r2 = x.^2 + y.^2 + z.^2;
h = ((r2 - 3*sigma^2) ./ (sigma^4)) .* exp(-r2 ./ (2*sigma^2));
h = h - mean(h(:));
h = h ./ max(abs(h(:)) + eps);
end


function P = front_projection(G, dim)
%FRONT_PROJECTION Proyección 2D por maximum intensity projection.
if nargin < 2
    dim = 3;
end
P = squeeze(max(G, [], dim));
end


function render_volume_views(G, outPrefix, plotTitle)

if nargin < 3
    plotTitle = 'Reconstrucción';
end

% Frente: colapsar profundidad (y)
save_projection(squeeze(max(G, [], 2)), [outPrefix, '_front.png'], [plotTitle, ' - vista frontal']);

% Superior: colapsar z
save_projection(squeeze(max(G, [], 3)), [outPrefix, '_top.png'], [plotTitle, ' - vista superior']);

% Lateral: colapsar x
save_projection(squeeze(max(G, [], 1)), [outPrefix, '_side.png'], [plotTitle, ' - vista lateral']);
end

function save_projection(P, savePath, titleStr)
fig = figure('Visible', 'off', 'Color', 'w');
imagesc(P.');
axis image;
colormap(hot);
colorbar;
title(titleStr, 'Interpreter', 'none');
set(gca, 'YDir', 'normal');
exportgraphics(fig, savePath, 'Resolution', 200);
close(fig);
end


function [Hf, params] = morlet_filter_temporal(ds, lambdaC, sigma)
%MORLET_FILTER_TEMPORAL Filtra H en la dimensión temporal usando una onda de Morlet.
%
% Km(t) = exp(2j*pi*Oc*t) * exp(-t^2/(2*sigma^2)), con Oc = 1/lambdaC
% Se implementa la convolución 1D temporal mediante FFT.

if nargin < 2 || isempty(lambdaC)
    spacing = estimate_wall_spacing(ds, 1);
    lambdaC = 2.5 * spacing;
end
if nargin < 3 || isempty(sigma)
    sigma = lambdaC;
end

omegaC = 1 / lambdaC;

timeDim = ndims(ds.H);
T = size(ds.H, timeDim);

t = ((0:T-1) - floor(T/2)) * ds.deltaT;
Km = exp(2j*pi*omegaC*t) .* exp(-(t.^2) / (2*sigma^2));
Km = Km(:).';

Hf = fftconv_along_dim(ds.H, Km, timeDim);

params.lambdaC = lambdaC;
params.sigma = sigma;
params.omegaC = omegaC;
end

function Y = fftconv_along_dim(X, h, dim)
n = size(X, dim);
m = numel(h);
nfft = 2^nextpow2(n + m - 1);

FX = fft(X, nfft, dim);
Hf = fft(h, nfft);
shape = ones(1, ndims(X));
shape(dim) = nfft;
Hf = reshape(Hf, shape);

Yfull = ifft(FX .* Hf, [], dim);
startIdx = floor(m/2) + 1;
endIdx = startIdx + n - 1;
subs = repmat({':'}, 1, ndims(X));
subs{dim} = startIdx:endIdx;
Y = Yfull(subs{:});
end

function spacing = estimate_wall_spacing(ds, stride)
if nargin < 2
    stride = 1;
end

if ds.isConfocal
    G = ds.laserGridPositions;
else
    G = ds.cameraGridPositions;
end

G = G(1:stride:end, 1:stride:end, :);

ptsX = squeeze(G(:,1,:));
ptsY = squeeze(G(1,:,:));

dx = diff(ptsX, 1, 1);
dy = diff(ptsY, 1, 1);

dx = sqrt(sum(dx.^2, 2));
dy = sqrt(sum(dy.^2, 2));
allD = [dx(:); dy(:)];
allD = allD(allD > 0);
spacing = median(allD);
end


function T = run_resolution_study(ds, outDir)
%RUN_RESOLUTION_STUDY Compara resolución de volumen y submuestreo de pared.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% Barrido recortado para una implementación naïve.
% Evita combinaciones que se disparan en tiempo (por ejemplo 64^3 con stride 8 o 1).
configs = [ ...
    16 16; ...
    16  8; ...
    16  1; ...
    32 16; ...
    32  8; ...
    64 16  ...
];

rows = {};
for ii = 1:size(configs,1)
    vr = configs(ii,1);
    ws = configs(ii,2);

    opts = struct();
    opts.wallStride = ws;
    opts.compensateAttenuation = false;

    tic;
    [G, ~] = nlos_backprojection(ds, vr, opts);
    elapsed = toc;

    G_lap = apply_volume_filter(G, 'laplacian');
    G_log = apply_volume_filter(G, 'log', 1.0);

    tag = sprintf('vox%d_stride%d', vr, ws);
    render_volume_views(G, fullfile(outDir, [tag, '_raw']), sprintf('%s raw', ds.fileName));
    render_volume_views(G_lap, fullfile(outDir, [tag, '_lap']), sprintf('%s lap', ds.fileName));
    render_volume_views(G_log, fullfile(outDir, [tag, '_log']), sprintf('%s log', ds.fileName));

    rows(end+1, :) = {string(ds.fileName), ds.isConfocal, vr, ws, elapsed, "raw/lap/log"}; %#ok<AGROW>
    fprintf('Dataset=%s, vox=%d, stride=%d, time=%.3fs', ds.fileName, vr, ws, elapsed);
end

T = cell2table(rows, 'VariableNames', {'dataset', 'isConfocal', 'voxelResolution', 'wallStride', 'seconds', 'filters'});
end


function run_attenuation_compensation(ds, outDir)
%RUN_ATTENUATION_COMPENSATION Ilustra el efecto de la compensación parcial de atenuación.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

voxelRes = 32;
wallStride = 8;

opts1 = struct('wallStride', wallStride, 'compensateAttenuation', false);
opts2 = struct('wallStride', wallStride, 'compensateAttenuation', true);

[G0, ~] = nlos_backprojection(ds, voxelRes, opts1);
[G1, ~] = nlos_backprojection(ds, voxelRes, opts2);

render_volume_views(G0, fullfile(outDir, 'without_compensation'), sprintf('%s without compensation', ds.fileName));
render_volume_views(G1, fullfile(outDir, 'with_compensation'), sprintf('%s with compensation', ds.fileName));
end


function T = run_confocal_comparison(nonConfocalFile, confocalFile, outDir)
%RUN_CONFOCAL_COMPARISON Reconstruye bunny en modo no confocal y confocal.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

dsNC = load_nlos_dataset(nonConfocalFile);
dsC  = load_nlos_dataset(confocalFile);

voxelRes = 32;
wallStride = 8;

opts = struct('wallStride', wallStride, 'compensateAttenuation', false);

tic;
[Gnc, ~] = nlos_backprojection(dsNC, voxelRes, opts);
tNC = toc;

tic;
[Gc, ~] = nlos_backprojection(dsC, voxelRes, opts);
tC = toc;

Gnc_log = apply_volume_filter(Gnc, 'log', 1.0);
Gc_log  = apply_volume_filter(Gc, 'log', 1.0);

render_volume_views(Gnc, fullfile(outDir, 'bunny_nonconfocal_raw'), 'Bunny no confocal');
render_volume_views(Gc,  fullfile(outDir, 'bunny_confocal_raw'), 'Bunny confocal');
render_volume_views(Gnc_log, fullfile(outDir, 'bunny_nonconfocal_log'), 'Bunny no confocal LoG');
render_volume_views(Gc_log,  fullfile(outDir, 'bunny_confocal_log'), 'Bunny confocal LoG');

rows = {
    string(dsNC.fileName), false, voxelRes, wallStride, tNC, "raw/log";
    string(dsC.fileName),  true,  voxelRes, wallStride, tC,  "raw/log"
};
T = cell2table(rows, 'VariableNames', {'dataset', 'isConfocal', 'voxelResolution', 'wallStride', 'seconds', 'filters'});
end


function T = run_phasor_experiment(ds, outDir)
%RUN_PHASOR_EXPERIMENT Filtrado temporal Morlet + backprojection.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

voxelRes = 32;
wallStride = 8;

[Hf, params] = morlet_filter_temporal(ds, [], []);

opts = struct();
opts.wallStride = wallStride;
opts.overrideH = Hf;
opts.useAbsAfterComplex = true;
opts.compensateAttenuation = false;

tic;
[Gphasor, ~] = nlos_backprojection(ds, voxelRes, opts);
tPhasor = toc;

Gphasor_log = apply_volume_filter(Gphasor, 'log', 1.0);

render_volume_views(abs(Gphasor), fullfile(outDir, 'phasor_raw'), sprintf('%s phasor raw', ds.fileName));
render_volume_views(abs(Gphasor_log), fullfile(outDir, 'phasor_log'), sprintf('%s phasor LoG', ds.fileName));

fid = fopen(fullfile(outDir, 'phasor_params.txt'), 'w');
fprintf(fid, 'lambdaC = %.6f\n', params.lambdaC);
fprintf(fid, 'sigma   = %.6f\n', params.sigma);
fprintf(fid, 'omegaC  = %.6f\n', params.omegaC);
fclose(fid);

rows = {
    string(ds.fileName), ds.isConfocal, voxelRes, wallStride, tPhasor, "phasor/log"
};
T = cell2table(rows, 'VariableNames', {'dataset', 'isConfocal', 'voxelResolution', 'wallStride', 'seconds', 'filters'});
end
