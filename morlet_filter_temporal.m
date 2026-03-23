function [Hf, params] = morlet_filter_temporal(ds, lambdaC, sigma)
%MORLET_FILTER_TEMPORAL Filtra H a lo largo del tiempo con una onda de Morlet.
%
% Implementa:
%   H' = H *t Km
% con
%   Km(t) = exp(2j*pi*Omega_c*t) * exp(-(t.^2)/(2*sigma^2))
%
% Nota: el filtro se aplica solo una vez sobre la dimension temporal,
% tal y como indica el guion. El valor absoluto debe aplicarse despues,
% sobre la reconstruccion compleja, no sobre Hf.

if nargin < 2 || isempty(lambdaC)
    spacing = estimate_wall_spacing(ds, 1);
    lambdaC = 2 * spacing;
end
if nargin < 3 || isempty(sigma)
    sigma = lambdaC;
end

omegaC = 1 / lambdaC;
timeDim = ndims(ds.H);
T = size(ds.H, timeDim);

% El dominio temporal del dataset esta en unidades de distancia optica.
% Centramos el kernel en 0 para hacer convolucion "same".
t = ((0:T-1) - floor(T/2)) * ds.deltaT;
Km = exp(2j*pi*omegaC*t) .* exp(-(t.^2) / (2*sigma^2));
Km = Km(:).';

Hf = fftconv_same_along_dim(ds.H, Km, timeDim);

params.lambdaC = lambdaC;
params.sigma = sigma;
params.omegaC = omegaC;
params.kernelLength = numel(Km);
end

function Y = fftconv_same_along_dim(X, h, dim)
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
