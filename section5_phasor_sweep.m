function section5_phasor_sweep(cfg)
%SECTION5_PHASOR_SWEEP
% Hace un pequeno barrido de parametros Morlet/phasor para bunny confocal.
%
% Motivacion:
% el phasor actual puede verse demasiado difuso, asi que esta seccion guarda
% varias combinaciones de lambda y sigma para comparar.

outDir = fullfile(cfg.resultsDir, 'section_5_phasor');
ensure_dir(outDir);

datasetFile = fullfile(cfg.datasetDir, cfg.files.bunnyConfocal);
if ~exist(datasetFile, 'file')
    error('No se encontro %s', datasetFile);
end

ds = load_nlos_dataset(datasetFile);
baseSpacing = estimate_wall_spacing(ds, 1);

summaryRows = {};
runId = 0;

for i = 1:numel(cfg.phasor.lambdaFactors)
    lambdaC = cfg.phasor.lambdaFactors(i) * baseSpacing;

    for j = 1:numel(cfg.phasor.sigmaFactors)
        sigma = cfg.phasor.sigmaFactors(j) * lambdaC;
        runId = runId + 1;

        [Hf, params] = morlet_filter_temporal(ds, lambdaC, sigma);

        opts.wallStride = cfg.phasor.wallStride;
        opts.compensateAttenuation = false;
        opts.useAbsAfterComplex = true;
        opts.overrideH = Hf;

        tic;
        [Gphasor, ~] = nlos_backprojection(ds, cfg.phasor.voxelRes, opts);
        elapsed = toc;

        if cfg.phasor.applyLoG
            Gphasor_log = apply_volume_filter(abs(Gphasor), 'log', 1.0);
        else
            Gphasor_log = abs(Gphasor);
        end

        tag = sprintf('run_%02d_lambda_%0.3f_sigma_%0.3f', runId, params.lambdaC, params.sigma);
        tag = strrep(tag, '.', 'p');

        dsOut = fullfile(outDir, tag);
        ensure_dir(dsOut);

        render_volume_views(abs(Gphasor), fullfile(dsOut, 'phasor_raw'), ...
            sprintf('%s phasor raw', ds.fileName), cfg.render);
        render_volume_views(abs(Gphasor_log), fullfile(dsOut, 'phasor_log'), ...
            sprintf('%s phasor LoG', ds.fileName), cfg.render);

        fid = fopen(fullfile(dsOut, 'params.txt'), 'w');
        fprintf(fid, 'lambdaC = %.8f\n', params.lambdaC);
        fprintf(fid, 'sigma   = %.8f\n', params.sigma);
        fprintf(fid, 'omegaC  = %.8f\n', params.omegaC);
        fprintf(fid, 'baseSpacing = %.8f\n', baseSpacing);
        fprintf(fid, 'voxelRes = %d\n', cfg.phasor.voxelRes);
        fprintf(fid, 'wallStride = %d\n', cfg.phasor.wallStride);
        fclose(fid);

        summaryRows(end+1,:) = {runId, params.lambdaC, params.sigma, elapsed}; %#ok<AGROW>
        fprintf('[PHASOR] run %d | lambda=%.4f sigma=%.4f time=%.3fs\n', ...
            runId, params.lambdaC, params.sigma, elapsed);
    end
end

T = cell2table(summaryRows, 'VariableNames', {'runId', 'lambdaC', 'sigma', 'seconds'});
writetable(T, fullfile(outDir, 'phasor_summary.csv'));
end
