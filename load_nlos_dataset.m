function ds = load_nlos_dataset(filePath)
%LOAD_NLOS_DATASET Carga un .mat y normaliza el acceso a sus campos.

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
if isempty(P)
    G = [];
    return;
end

P = double(P);
Nx = gridPoints(1);
Ny = gridPoints(2);

if ndims(P) == 3 && size(P, 3) == 3
    G = P;
elseif ndims(P) == 3 && size(P, 1) == 3
    G = permute(P, [2 3 1]);
elseif isvector(P) && numel(P) == 3
    G = reshape(rowvec(P), [1 1 3]);
elseif ismatrix(P) && size(P, 2) == 3
    G = reshape(P, [Nx, Ny, 3]);
elseif ismatrix(P) && size(P, 1) == 3
    G = reshape(P.', [Nx, Ny, 3]);
else
    error('Formato no soportado para laser/cameraGridPositions.');
end
end

function G = normals_to_grid(N, gridPoints, defaultNormal)
Nx = gridPoints(1);
Ny = gridPoints(2);

if isempty(N)
    G = repmat(reshape(defaultNormal, [1 1 3]), [Nx, Ny, 1]);
    return;
end

N = double(N);

if ndims(N) == 3 && size(N, 3) == 3
    G = N;
elseif ndims(N) == 3 && size(N, 1) == 3
    G = permute(N, [2 3 1]);
elseif isvector(N) && numel(N) == 3
    G = repmat(reshape(rowvec(N), [1 1 3]), [Nx, Ny, 1]);
elseif ismatrix(N) && size(N, 2) == 3
    G = reshape(N, [Nx, Ny, 3]);
elseif ismatrix(N) && size(N, 1) == 3
    G = reshape(N.', [Nx, Ny, 3]);
else
    G = repmat(reshape(defaultNormal, [1 1 3]), [Nx, Ny, 1]);
end
end

function H = collapse_bounces(A, isConfocal)
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
        error('Formato confocal no soportado.');
    end
else
    if nd == 6
        H = sum(A, 5);
        H = reshape(H, [sz(1), sz(2), sz(3), sz(4), sz(6)]);
    elseif nd == 5
        H = reshape(A, sz);
    else
        error('Formato no confocal no soportado.');
    end
end
end
