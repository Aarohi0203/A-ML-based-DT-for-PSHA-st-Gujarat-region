%% ========================================================================
%  DIGITAL TWIN - STEP 3 (REVISED): UNCERTAINTY QUANTIFICATION
%  Column detection fixed for actual Excel feature names
%% ========================================================================
clc; clear; close all;

load('DigitalTwin_Base_REVISED.mat');


fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 3 (REVISED): UNCERTAINTY\n');
fprintf('================================================\n\n');

N_ensemble   = 200;
conf_level   = 0.90;
perturb_frac = 0.03;
outputLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
colors4      = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.7 0.3; 0.7 0.3 0.8];

X_test_raw = DT.X_test_raw;
N_test     = size(X_test_raw, 1);

% Physical std per feature
feat_std_phys = DT.sigma_X;
perturb_sigma = perturb_frac * feat_std_phys;

fprintf('Ensemble size   : %d\n', N_ensemble);
fprintf('Confidence level: %d%%\n', conf_level*100);
fprintf('Perturbation    : %.0f%% of each feature physical std\n\n', perturb_frac*100);

%% ---- Column detection (correct Excel names) --------------------------
fLow = lower(DT.featureNames);
col_FL   = find(contains(fLow,'length of fault'),  1);
col_NEQ  = find(contains(fLow,'earthquake'),       1);
col_Rmax = find(contains(fLow,'rmax'),             1);
col_Rmin = find(contains(fLow,'rmin'),             1);
col_Mu   = find(contains(fLow,'max. magnitude'),   1);
col_M0   = find(contains(fLow,'min. magnitude'),   1);

% Engineered feature columns
col_Rratio  = find(contains(fLow,'rratio'),  1);
col_Mrange  = find(contains(fLow,'mrange'),  1);
col_logRmax = find(contains(fLow,'logrmax'), 1);
col_logRmin = find(contains(fLow,'logrmin'), 1);
col_logFL   = find(contains(fLow,'logfault'),1);
col_DistMag = find(contains(fLow,'distmag'), 1);

%% ---- Ensemble predictions --------------------------------------------
pga_ensemble = zeros(N_test, 4, N_ensemble);

for e = 1:N_ensemble
    noise  = randn(N_test, DT.nFeatures) .* perturb_sigma;
    X_pert = X_test_raw + noise;

    % Clamp physical limits using detected columns
    if ~isempty(col_FL),   X_pert(:,col_FL)   = max(X_pert(:,col_FL),   1);   end
    if ~isempty(col_NEQ),  X_pert(:,col_NEQ)  = max(X_pert(:,col_NEQ),  1);   end
    if ~isempty(col_Rmax), X_pert(:,col_Rmax) = max(X_pert(:,col_Rmax), 1);   end
    if ~isempty(col_Rmin), X_pert(:,col_Rmin) = max(X_pert(:,col_Rmin), 0.1); end
    if ~isempty(col_Mu),   X_pert(:,col_Mu)   = max(X_pert(:,col_Mu),   4.0); end

    % Recompute engineered features after perturbation
    if ~isempty(col_Rratio)  && ~isempty(col_Rmax) && ~isempty(col_Rmin)
        X_pert(:,col_Rratio)  = X_pert(:,col_Rmax)./(X_pert(:,col_Rmin)+1);          end
    if ~isempty(col_Mrange)  && ~isempty(col_Mu) && ~isempty(col_M0)
        X_pert(:,col_Mrange)  = X_pert(:,col_Mu) - X_pert(:,col_M0);                  end
    if ~isempty(col_logRmax) && ~isempty(col_Rmax)
        X_pert(:,col_logRmax) = log(X_pert(:,col_Rmax)+1);                             end
    if ~isempty(col_logRmin) && ~isempty(col_Rmin)
        X_pert(:,col_logRmin) = log(X_pert(:,col_Rmin)+1);                             end
    if ~isempty(col_logFL)   && ~isempty(col_FL)
        X_pert(:,col_logFL)   = log(X_pert(:,col_FL)+1);                               end
    if ~isempty(col_DistMag) && ~isempty(col_Rmax) && ~isempty(col_Mu)
        X_pert(:,col_DistMag) = log(X_pert(:,col_Rmax)+1).*X_pert(:,col_Mu);          end

    pga_ensemble(:,:,e) = DT_predict_REVISED(DT, X_pert);

    if mod(e,50)==0, fprintf('  Ensemble %3d/%d done\n',e,N_ensemble); end
end
fprintf('\n');

%% ---- Statistics ------------------------------------------------------
pga_mean = mean(pga_ensemble,3);
pga_std  = std(pga_ensemble, 0,3);
pga_cv   = pga_std./pga_mean*100;
alpha    = 1-conf_level;
pga_lo   = prctile(pga_ensemble, alpha/2*100,    3);
pga_hi   = prctile(pga_ensemble, (1-alpha/2)*100, 3);

fprintf('%d%% CI Summary:\n', conf_level*100);
fprintf('  %-16s  %9s  %9s  %9s  %9s  %8s\n', ...
    'Output','Mean(g)','Std(g)','CI_lo(g)','CI_hi(g)','CV%%');
fprintf('  %s\n',repmat('-',1,72));
for k=1:4
    fprintf('  %-16s  %9.5f  %9.5f  %9.5f  %9.5f  %7.2f\n', ...
        outputLabels{k}, mean(pga_mean(:,k)), mean(pga_std(:,k)), ...
        mean(pga_lo(:,k)), mean(pga_hi(:,k)), mean(pga_cv(:,k)));
end

%% ---- Calibration check -----------------------------------------------
fprintf('\nCalibration (%d%% CI):\n', conf_level*100);
for k=1:4
    in_ci = mean(DT.Y_pga_test(:,k)>=pga_lo(:,k) & ...
                 DT.Y_pga_test(:,k)<=pga_hi(:,k))*100;
    fprintf('  %-16s  %.1f%% inside CI (target: %d%%)\n', ...
        outputLabels{k}, in_ci, conf_level*100);
end

%% ---- Fig 1: Uncertainty distributions --------------------------------
fig2 = figure('Position',[50 50 1000 500],'Color','w');
for k=1:4
    subplot(1,4,k); hold on;
    data_k = pga_ensemble(:,k,:); data_k=data_k(:);
    histogram(data_k,30,'Normalization','pdf', ...
        'FaceColor',colors4(k,:),'FaceAlpha',0.6,'EdgeColor','none');
    xline(mean(pga_mean(:,k)),'k-', 'LineWidth',2,'Label','Mean');
    xline(mean(pga_lo(:,k)),  'b--','LineWidth',1.5,'Label','5th pct');
    xline(mean(pga_hi(:,k)),  'r--','LineWidth',1.5,'Label','95th pct');
    xlabel('PGA (g)','FontSize',9); ylabel('Density','FontSize',9);
    title(outputLabels{k},'FontSize',9,'FontWeight','bold'); grid on;
end
sgtitle(sprintf('PGA Ensemble Distribution — %d%% CI',conf_level*100), ...
    'FontSize',12,'FontWeight','bold');
saveas(fig2,'DT_UncertaintyDistributions_REVISED.png');
print(fig2,'DT_UncertaintyDistributions_REVISED','-dpng','-r300');
fprintf('\n  Saved: DT_UncertaintyDistributions_REVISED.png\n');
close(fig2);

%% ---- Fig 2: CV% box plot ---------------------------------------------
fig3 = figure('Position',[50 50 900 500],'Color','w');
for k=1:4
    subplot(1,4,k);
    boxplot(pga_cv(:,k),'Symbol','+');
    ylabel('CV (%)','FontSize',9);
    title(outputLabels{k},'FontSize',9,'FontWeight','bold');
    grid on; box on;
end
sgtitle('Uncertainty CV% per Output','FontSize',12,'FontWeight','bold');
saveas(fig3,'DT_UncertaintyCV_REVISED.png');
print(fig3,'DT_UncertaintyCV_REVISED','-dpng','-r300');
fprintf('  Saved: DT_UncertaintyCV_REVISED.png\n');
close(fig3);

%% ---- Save ------------------------------------------------------------
save('DT_Step3_Results_REVISED.mat', ...
    'pga_mean','pga_std','pga_lo','pga_hi','pga_cv','pga_ensemble', ...
    'N_ensemble','conf_level','perturb_frac');
fprintf('  Saved: DT_Step3_Results_REVISED.mat\n');
fprintf('\n================================================\n');
fprintf('  DT STEP 3 COMPLETE\n');
fprintf('================================================\n');