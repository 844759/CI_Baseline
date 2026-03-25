function render_volume_views(G, outPrefix, plotTitle, renderCfg)
%RENDER_VOLUME_VIEWS

if nargin < 3
    plotTitle = 'Reconstruccion';
end
if nargin < 4 || isempty(renderCfg)
    renderCfg.frontCollapseDim = 2;
    renderCfg.topCollapseDim = 3;
    renderCfg.sideCollapseDim = 1;
end

save_projection(front_projection(G, renderCfg.frontCollapseDim), ...
    [outPrefix '_front.png'], [plotTitle ' - vista frontal']);
save_projection(front_projection(G, renderCfg.topCollapseDim), ...
    [outPrefix '_top.png'], [plotTitle ' - vista superior']);
save_projection(front_projection(G, renderCfg.sideCollapseDim), ...
    [outPrefix '_side.png'], [plotTitle ' - vista lateral']);
end
