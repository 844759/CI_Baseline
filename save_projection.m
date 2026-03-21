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
