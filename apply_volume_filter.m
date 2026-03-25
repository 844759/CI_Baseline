function Gf = apply_volume_filter(G, mode, sigma)
%APPLY_VOLUME_FILTER

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
