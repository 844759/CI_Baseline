function [G, meta] = nlos_backprojection(ds, voxelResolution, opts)
%NLOS_BACKPROJECTION Backprojection naive confocal/no confocal.
%
% opts.wallStride
% opts.compensateAttenuation
% opts.useAbsAfterComplex
% opts.overrideH

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

for iv = 1:size(voxels, 1)
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

for iv = 1:size(voxels, 1)
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
