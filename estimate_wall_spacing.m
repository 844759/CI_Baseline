function spacing = estimate_wall_spacing(ds, stride)
%ESTIMATE_WALL_SPACING Estima separacion entre puntos de pared.

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

if isempty(allD)
    spacing = 1;
else
    spacing = median(allD);
end
end
