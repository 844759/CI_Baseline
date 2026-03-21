function P = front_projection(G, dim)
%FRONT_PROJECTION Maximum intensity projection.
if nargin < 2
    dim = 3;
end
P = squeeze(max(G, [], dim));
end
