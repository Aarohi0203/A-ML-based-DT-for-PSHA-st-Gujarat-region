%% ========================================================================
%  DIGITAL TWIN - STEP 1 (REVISED): SURROGATE MODEL LOADER
%  SVR Best Model (Test R2=0.9746)
%% ========================================================================
clc; clear; close all;

fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 1 (REVISED): MODEL LOADER\n');
fprintf('================================================\n\n');

%% ---- 1. Load shared pipeline -----------------------------------------
load('Step3_ANN_BayesOpt_REVISED.mat', ...
    'mu_X','sigma_X','mu_Y','sigma_Y', ...
    'featureNames','targetNames','nFeatures', ...
    'X_train','X_val','X_test', ...
    'Y_train','Y_val', ...
    'Y_train_raw','Y_test_raw', ...
    'idxTrain','idxVal','idxTest');

%% ---- CRITICAL FIX: pad featureNames to match nFeatures ---------------
% Step 3 saves only the 11 base feature names but mu_X has 17 elements
% because 6 engineered features were appended to X without saving their names.
% We must add the engineered names here before ANY use of featureNames.
eng_names = {'Rratio','Mrange','logRmax','logRmin','logFaultLen','DistMag'};
while length(featureNames) < nFeatures
    idx_eng = length(featureNames) - 10;   % how many engineered already added
    if idx_eng >= 1 && idx_eng <= length(eng_names)
        featureNames{end+1} = eng_names{idx_eng};
    else
        featureNames{end+1} = sprintf('Engineered_%d', length(featureNames)-10);
    end
end

fprintf('[1] Shared pipeline loaded.\n');
fprintf('    nFeatures      : %d\n', nFeatures);
fprintf('    featureNames   : %d names (after padding)\n', length(featureNames));
fprintf('    mu_X elements  : %d\n', numel(mu_X));
fprintf('    Train rows     : %d | Test rows: %d\n\n', size(X_train,1), size(X_test,1));

fprintf('    All feature names:\n');
for f = 1:nFeatures
    fprintf('      [%2d] %s\n', f, featureNames{f});
end
fprintf('\n');

%% ---- 2. Best model from Step 5 ---------------------------------------
load('Step5_FinalResults_REVISED.mat', ...
    'best_idx','modelNames','mean_R2_test','mean_R2_train','verdicts');

fprintf('[2] Best model: %s (Test R2=%.4f, Gap=%.4f, %s)\n\n', ...
    modelNames{best_idx}, mean_R2_test(best_idx), ...
    mean_R2_train(best_idx)-mean_R2_test(best_idx), verdicts{best_idx});

%% ---- 3. Load SVR params from Step 4 ----------------------------------
load('Step4_MultiModel_REVISED.mat', ...
    'best_svr_params','Y_pred_svr','Y_pred_svr_train', ...
    'R2_svr_train','R2_svr_test','metrics_svr');
fprintf('[3] SVR params loaded.\n\n');

%% ---- 4. Refit SVR models (Step 4 saves params not model objects) -----
fprintf('[4] Refitting 4 SVR models (1-3 minutes)...\n\n');

svr_models = cell(4,1);
for k = 1:4
    fprintf('    Output %d/%d: %s\n', k, 4, targetNames{k});
    bp  = best_svr_params{k};
    mdl = fitrsvm([X_train; X_val], [Y_train(:,k); Y_val(:,k)], ...
        'KernelFunction','rbf', ...
        'BoxConstraint', bp.BoxConstraint, ...
        'KernelScale',   bp.KernelScale, ...
        'Epsilon',       bp.Epsilon);
    svr_models{k} = mdl;
    fprintf('    [OK]\n');
end
fprintf('\n');

%% ---- 5. Reconstruct physical-unit test features ----------------------
sigma_safe = sigma_X; sigma_safe(sigma_safe==0) = 1;
X_test_raw = X_test .* sigma_safe + mu_X;

%% ---- 6. Self-test metrics --------------------------------------------
fprintf('[6] SVR Test Performance:\n');
fprintf('    %-26s  %8s  %8s  %8s\n','Output','TrainR2','TestR2','Gap');
fprintf('    %s\n', repmat('-',1,54));
for k = 1:4
    fprintf('    %-26s  %8.4f  %8.4f  %8.4f\n', targetNames{k}, ...
        R2_svr_train(k), R2_svr_test(k), R2_svr_train(k)-R2_svr_test(k));
end
fprintf('    MEAN                        %8.4f  %8.4f  %8.4f\n\n', ...
    mean(R2_svr_train), mean(R2_svr_test), mean(R2_svr_train-R2_svr_test));

%% ---- 7. Column detection (correct Excel names) ----------------------
fprintf('[7] Detecting column indices...\n');
fLow = lower(featureNames);

col_struct.NAF      = find(contains(fLow,'active fault'),     1);
col_struct.FaultLen = find(contains(fLow,'length of fault'),  1);
col_struct.NumEQ    = find(contains(fLow,'earthquake'),       1);
col_struct.Rmax     = find(contains(fLow,'rmax'),             1);
col_struct.Rmin     = find(contains(fLow,'rmin'),             1);
col_struct.M0       = find(contains(fLow,'min. magnitude'),   1);
col_struct.Mu       = find(contains(fLow,'max. magnitude'),   1);
col_struct.aval     = find(contains(fLow,'value of a'),       1);
col_struct.bval     = find(contains(fLow,'value of b'),       1);
col_struct.AttModel = find(contains(fLow,'attenuationmodel'), 1);
col_struct.Rratio   = find(strcmp(fLow,'rratio'),             1);
col_struct.Mrange   = find(strcmp(fLow,'mrange'),             1);
col_struct.logRmax  = find(strcmp(fLow,'logrmax'),            1);
col_struct.logRmin  = find(strcmp(fLow,'logrmin'),            1);
col_struct.logFL    = find(strcmp(fLow,'logfaultlen'),        1);
col_struct.DistMag  = find(strcmp(fLow,'distmag'),            1);

fields = fieldnames(col_struct);
for f = 1:length(fields)
    idx = col_struct.(fields{f});
    if isempty(idx)
        fprintf('    %-12s = N/A\n', fields{f});
    else
        fprintf('    %-12s = col %d  (%s)\n', fields{f}, idx, featureNames{idx});
    end
end
fprintf('\n');

%% ---- 8. Build DT struct ----------------------------------------------
fprintf('[8] Building DT struct...\n');

DT              = struct();
DT.model_type   = 'SVR';
DT.best_idx     = best_idx;
DT.mu_X         = mu_X;
DT.sigma_X      = sigma_X;
DT.mu_Y         = mu_Y;
DT.sigma_Y      = sigma_Y;
DT.featureNames = featureNames;   % 17 names (11 base + 6 engineered)
DT.targetNames  = targetNames;
DT.nFeatures    = nFeatures;      % 17
DT.outputs      = targetNames;
DT.R2_train     = R2_svr_train;
DT.R2_test      = R2_svr_test;
DT.R2           = R2_svr_test;
DT.RMSE         = metrics_svr.RMSE;
DT.MAE          = metrics_svr.MAE;
DT.svr_models   = svr_models;
DT.svr_params   = best_svr_params;
DT.col          = col_struct;
DT.created      = datetime('now');
DT.X_test_raw   = X_test_raw;
DT.Y_pga_test   = Y_test_raw;
DT.pga_pred     = Y_pred_svr;
DT.X_train_norm = X_train;
DT.Y_train_norm = Y_train;

fprintf('    mu_X size    : %d (must equal nFeatures=%d)\n', numel(DT.mu_X), nFeatures);
fprintf('    sigma_X size : %d\n', numel(DT.sigma_X));
fprintf('    featureNames : %d names\n', length(DT.featureNames));

if numel(DT.mu_X) ~= nFeatures
    error('SIZE MISMATCH: mu_X has %d elements but nFeatures=%d. Check Step 3.', ...
        numel(DT.mu_X), nFeatures);
end
fprintf('    [OK] Sizes consistent.\n');

%% ---- 9. Save ---------------------------------------------------------
save('DigitalTwin_Base_REVISED.mat','DT');
fprintf('\n  Saved: DigitalTwin_Base_REVISED.mat\n');
fprintf('\n================================================\n');
fprintf('  DT STEP 1 COMPLETE\n');
fprintf('  Model     : SVR\n');
fprintf('  nFeatures : %d\n', nFeatures);
fprintf('  Test R2   : %.4f\n', mean(R2_svr_test));
fprintf('  Ready for Steps 2-6\n');
fprintf('================================================\n');