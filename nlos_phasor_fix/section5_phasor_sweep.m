function section5_phasor_sweep(cfg)
%SECTION5_PHASOR_SWEEP
% Barrido corregido de parametros Morlet/phasor para bunny confocal.
%
% Correcciones respecto a la version anterior:
% - lambda_c se calcula usando el spacing EFECTIVO tras wallStride.
% - lambda_c cumple lambda_c >= 2 * spacing_efectivo.
% - sigma sigue el rango recomendado del guion.
% - se guarda una baseline confocal LoG sin phasor para comparar.

outDir = fullfile(cfg.resultsDir, 'section_5_phasor');
ensure_dir(outDir);

datasetFile = fullfile(cfg.datasetDir, cfg.files.bunnyConfocal);
if ~exist(datasetFile, 'file')
    error('No se encontro %s', datasetFile);
end

ds = load_nlos_dataset(datasetFile);
spacingEff = estimate_wall_spacing(ds, cfg.phasor.wallStride);
lambdaMin = 2 * spacingEff;
lambdaList = lambdaMin * cfg.phasor.lambdaMultipliers;

fprintf('[PHASOR] dataset = %s\n', ds.fileName);
printf('[PHASOR] wallStride = %d\n', cfg.phasor.wallStride);
printf('[PHASOR] spacing efectivo = %.8f\n', spacingEff);
printf('[PHASOR] lambda minimo (2*spacing) = %.8f\n', lambdaMin);

summaryRows = {};
runId = 0;

if cfg.phasor.saveBaselineConfocalLoG
    baselineDir = fullfile(outDir, 'baseline_confocal_log');
    ensure_dir(baselineDir);

    optsBase.wallStride = cfg.phasor.wallStride;
    optsBase.compensateAttenuation = false;
    optsBase.useAbsAfterComplex = false;

    tic;
    [Gbase, ~] = nlos_backprojection(ds, cfg.phasor.voxelRes, optsBase);
    baseElapsed = toc;

    if cfg.phasor.applyLoG
        GbaseView = apply_volume_filter(Gbase, 'log', cfg.phasor.logSigma);
    else
        GbaseView = Gbase;
    end

    render_volume_views(Gbase, fullfile(baselineDir, 'confocal_raw'), ...
        sprintf('%s confocal raw baseline', ds.fileName), cfg.render);
    render_volume_views(GbaseView, fullfile(baselineDir, 'confocal_log'), ...
        sprintf('%s confocal LoG baseline', ds.fileName), cfg.render);

    fidBase = fopen(fullfile(baselineDir, 'params.txt'), 'w');
    fprintf(fidBase, 'baseline = confocal backprojection + LoG\n');
    fprintf(fidBase, 'voxelRes = %d\n', cfg.phasor.voxelRes);
    fprintf(fidBase, 'wallStride = %d\n', cfg.phasor.wallStride);
    fprintf(fidBase, 'elapsed = %.8f\n', baseElapsed);
    fclose(fidBase);
end

for i = 1:numel(lambdaList)
    lambdaC = lambdaList(i);

    if cfg.phasor.useRecommendedSigmas
        sigmaList = recommended_sigma_values(lambdaC);
    else
        sigmaList = lambdaC;
    end

    for j = 1:numel(sigmaList)
        sigma = sigmaList(j);
        runId = runId + 1;

        [Hf, params] = morlet_filter_temporal(ds, lambdaC, sigma);

        opts.wallStride = cfg.phasor.wallStride;
        opts.compensateAttenuation = false;
        opts.useAbsAfterComplex = true;
        opts.overrideH = Hf;

        tic;
        [Gphasor, ~] = nlos_backprojection(ds, cfg.phasor.voxelRes, opts);
        elapsed = toc;

        GphasorAbs = abs(Gphasor);
        if cfg.phasor.applyLoG
            GphasorView = apply_volume_filter(GphasorAbs, 'log', cfg.phasor.logSigma);
        else
            GphasorView = GphasorAbs;
        end

        tag = sprintf('run_%02d_lambda_%0.6f_sigma_%0.6f', runId, params.lambdaC, params.sigma);
        tag = strrep(tag, '.', 'p');

        dsOut = fullfile(outDir, tag);
        ensure_dir(dsOut);

        render_volume_views(GphasorAbs, fullfile(dsOut, 'phasor_raw'), ...
            sprintf('%s phasor raw', ds.fileName), cfg.render);
        render_volume_views(GphasorView, fullfile(dsOut, 'phasor_log'), ...
            sprintf('%s phasor LoG', ds.fileName), cfg.render);

        fid = fopen(fullfile(dsOut, 'params.txt'), 'w');
        fprintf(fid, 'lambdaC = %.8f\n', params.lambdaC);
        fprintf(fid, 'sigma   = %.8f\n', params.sigma);
        fprintf(fid, 'omegaC  = %.8f\n', params.omegaC);
        fprintf(fid, 'spacingEff = %.8f\n', spacingEff);
        fprintf(fid, 'lambdaMin = %.8f\n', lambdaMin);
        fprintf(fid, 'voxelRes = %d\n', cfg.phasor.voxelRes);
        fprintf(fid, 'wallStride = %d\n', cfg.phasor.wallStride);
        fprintf(fid, 'elapsed = %.8f\n', elapsed);
        fclose(fid);

        summaryRows(end+1,:) = { ...
            runId, params.lambdaC, params.sigma, spacingEff, lambdaMin, ...
            cfg.phasor.wallStride, cfg.phasor.voxelRes, elapsed}; %#ok<AGROW>

        fprintf('[PHASOR] run %d | lambda=%.6f sigma=%.6f time=%.3fs\n', ...
            runId, params.lambdaC, params.sigma, elapsed);
    end
end

T = cell2table(summaryRows, 'VariableNames', ...
    {'runId','lambdaC','sigma','spacingEff','lambdaMin','wallStride','voxelRes','seconds'});
writetable(T, fullfile(outDir, 'phasor_summary.csv'));
end
