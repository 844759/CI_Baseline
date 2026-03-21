function visualize_transient_slices(ds, outDir)
%VISUALIZE_TRANSIENT_SLICES Guarda cortes x-t e y-t.

ensure_dir(outDir);

if ds.isConfocal
    xt = squeeze(sum(ds.H, 2)); % Nx x T
    yt = squeeze(sum(ds.H, 1)); % Ny x T
else
    Hsum = squeeze(sum(sum(ds.H, 1), 2)); % Sx x Sy x T
    xt = squeeze(sum(Hsum, 2));
    yt = squeeze(sum(Hsum, 1));
end

xt = double(xt.');
yt = double(yt.');

make_slice_figure(xt, sprintf('%s - corte x-t', ds.fileName), ...
    fullfile(outDir, [sanitize_filename(ds.fileName) '_xt.png']), 'x');
make_slice_figure(yt, sprintf('%s - corte y-t', ds.fileName), ...
    fullfile(outDir, [sanitize_filename(ds.fileName) '_yt.png']), 'y');
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
