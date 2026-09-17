%% ========================================================================
%  DIGITAL TWIN - STEP 5 (REVISED): DRIFT MONITOR & AUTO-RETRAINING
%
%  REVISED for new pipeline (16 features, site-based split):
%    - Loads DigitalTwin_Base_REVISED.mat and Step3_ANN_BayesOpt_REVISED.mat
%    - Drift comparison in PGA (g) space using correct inverse-transform
%    - Retraining data normalised with training-set mu_Y/sigma_Y (no leakage)
%    - DT_predict_REVISED.m used throughout
%% ========================================================================
clc; clear; close all;

load('DigitalTwin_Base_REVISED.mat');
load('Step3_ANN_BayesOpt_REVISED.mat','X_train','Y_train','X_test','Y_test','mu_Y','sigma_Y'); % shared pipeline vars
load('Step4_MultiModel_REVISED.mat','Y_pred_svr','R2_svr_test'); % SVR best model



fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 5 (REVISED): DRIFT MONITOR\n');
fprintf('================================================\n\n');

DRIFT_THRESHOLD   = 0.15;
RETRAIN_THRESHOLD = 0.25;
WINDOW_SIZE       = 50;
outputLabels      = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
colors4           = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.7 0.3; 0.7 0.3 0.8];

%% ---- Simulate incoming events ----------------------------------------
rng(42);
N_events  = 200;
N_avail   = size(X_test,1);
event_idx = randperm(N_avail, min(N_events,N_avail));
N_events  = length(event_idx);

X_events = X_test(event_idx,:);          % normalised

% Ground-truth PGA in g (from normalised log-PGA)
Y_log_events = Y_test(event_idx,:) .* sigma_Y + mu_Y;
Y_pga_events = exp(Y_log_events);

% Simulate 5% measurement noise
Y_observed = Y_pga_events .* (1 + randn(size(Y_pga_events))*0.05);
Y_observed = max(Y_observed, 1e-5);

fprintf('Simulating %d incoming seismic events...\n\n', N_events);

%% ---- Predict using revised Digital Twin ------------------------------
sigma_safe  = DT.sigma_X; sigma_safe(sigma_safe==0)=1;
X_events_raw= X_events .* sigma_safe + DT.mu_X;
Y_predicted = DT_predict_REVISED(DT, X_events_raw);

rel_errors   = abs(Y_predicted - Y_observed)./max(Y_observed,1e-5);
mean_rel_err = mean(rel_errors,2);

%% ---- Rolling drift detection -----------------------------------------
rolling_rmse  = zeros(N_events,1);
drift_flags   = false(N_events,1);
retrain_flags = false(N_events,1);

for i = WINDOW_SIZE:N_events
    w_err            = mean_rel_err(i-WINDOW_SIZE+1:i);
    rolling_rmse(i)  = mean(w_err);
    drift_flags(i)   = rolling_rmse(i) > DRIFT_THRESHOLD;
    retrain_flags(i) = rolling_rmse(i) > RETRAIN_THRESHOLD;
end

n_drift  =sum(drift_flags);
n_retrain=sum(retrain_flags);
fprintf('Rolling window     : %d events\n', WINDOW_SIZE);
fprintf('Drift alerts       : %d / %d windows (threshold=%.0f%%)\n', ...
    n_drift, N_events, DRIFT_THRESHOLD*100);
fprintf('Retrain alerts     : %d / %d windows (threshold=%.0f%%)\n', ...
    n_retrain, N_events, RETRAIN_THRESHOLD*100);
fprintf('Overall mean error : %.2f%%\n\n', mean(mean_rel_err)*100);

fprintf('Per-output error summary:\n');
fprintf('  %-16s  %10s  %10s  %10s\n','Output','MedRelErr%%','90th pct%%','Max%%');
fprintf('  %s\n',repmat('-',1,52));
for k=1:4
    re_k=rel_errors(:,k)*100;
    fprintf('  %-16s  %10.2f  %10.2f  %10.2f\n', ...
        outputLabels{k},median(re_k),prctile(re_k,90),max(re_k));
end

%% ---- Dashboard plot --------------------------------------------------
fig=figure('Position',[50 50 1200 800],'Color','w');

ax1=subplot(2,3,[1,2]);
plot(ax1,1:N_events,rolling_rmse*100,'b-','LineWidth',1.8); hold(ax1,'on');
fill(ax1,[1 WINDOW_SIZE WINDOW_SIZE 1],[0 0 100 100],[0.8 0.8 0.8],'FaceAlpha',0.3,'EdgeColor','none');
yline(ax1,DRIFT_THRESHOLD*100,'r--','LineWidth',1.5,'Label','Drift 15%');
yline(ax1,RETRAIN_THRESHOLD*100,'r-','LineWidth',2.0,'Label','Retrain 25%');
if any(drift_flags)
    scatter(ax1,find(drift_flags),rolling_rmse(drift_flags)*100,50,[1 0.6 0],'filled','DisplayName','Drift alert');
end
if any(retrain_flags)
    scatter(ax1,find(retrain_flags),rolling_rmse(retrain_flags)*100,70,[1 0 0],'filled','DisplayName','Retrain alert');
end
xlim(ax1,[1 N_events]); ylim(ax1,[0,max(rolling_rmse*100)*1.3+1]);
xlabel(ax1,'Event number','FontSize',11,'FontWeight','bold');
ylabel(ax1,'Rolling mean relative error (%)','FontSize',11,'FontWeight','bold');
title(ax1,sprintf('Model Drift Monitor — rolling window (%d events)',WINDOW_SIZE),'FontSize',12,'FontWeight','bold');
legend(ax1,'Location','northwest','FontSize',8); grid(ax1,'on');

ax2=subplot(2,3,3);
boxplot(ax2,rel_errors*100,'Labels',{'2%/50yr','10%/50yr','2%/100yr','10%/100yr'},'Symbol','+');
yline(ax2,DRIFT_THRESHOLD*100,'r--','LineWidth',1.5);
ylabel(ax2,'Relative error (%)','FontSize',10);
title(ax2,'Error per output','FontSize',11,'FontWeight','bold');
grid(ax2,'on'); box(ax2,'on');

ax3=subplot(2,3,4);
cum_err=cumsum(mean_rel_err)./(1:N_events)';
plot(ax3,1:N_events,cum_err*100,'k-','LineWidth',1.8);
yline(ax3,DRIFT_THRESHOLD*100,'r--','LineWidth',1.5,'Label','Alert level');
xlabel(ax3,'Event number','FontSize',10,'FontWeight','bold');
ylabel(ax3,'Cumulative mean error (%)','FontSize',10,'FontWeight','bold');
title(ax3,'Cumulative accuracy','FontSize',11,'FontWeight','bold');
grid(ax3,'on'); box(ax3,'on');

ax4=subplot(2,3,5);
scatter(ax4,Y_observed(:,1),Y_predicted(:,1),12,[0.2 0.4 0.8],'filled','MarkerFaceAlpha',0.4);
hold(ax4,'on');
lims=[min([Y_observed(:,1);Y_predicted(:,1)]),max([Y_observed(:,1);Y_predicted(:,1)])];
plot(ax4,lims,lims,'k-','LineWidth',1.5);
set(ax4,'XScale','log','YScale','log');
xlabel(ax4,'Observed PGA (g)','FontSize',10,'FontWeight','bold');
ylabel(ax4,'Predicted PGA (g)','FontSize',10,'FontWeight','bold');
title(ax4,'Pred vs Observed (2%/50yr)','FontSize',10,'FontWeight','bold');
grid(ax4,'on'); box(ax4,'on');

ax5=subplot(2,3,6);
histogram(ax5,mean_rel_err*100,25,'FaceColor',[0.2 0.5 0.8],'EdgeColor','none');
xline(ax5,DRIFT_THRESHOLD*100,'r--','LineWidth',1.5,'Label','Drift');
xline(ax5,RETRAIN_THRESHOLD*100,'r-','LineWidth',2.0,'Label','Retrain');
xlabel(ax5,'Mean relative error (%)','FontSize',10,'FontWeight','bold');
ylabel(ax5,'Count','FontSize',10,'FontWeight','bold');
title(ax5,'Error distribution','FontSize',10,'FontWeight','bold');
grid(ax5,'on'); box(ax5,'on');

sgtitle('Digital Twin (Revised) — Live Drift Monitor','FontSize',14,'FontWeight','bold');
saveas(fig,'DT_DriftMonitor_REVISED.png');
print(fig,'DT_DriftMonitor_REVISED','-dpng','-r300');
fprintf('\n  Saved: DT_DriftMonitor_REVISED.png\n'); close(fig);

%% ---- Auto-retraining trigger -----------------------------------------
if any(retrain_flags)
    fprintf('\n[ALERT] Drift detected — preparing retraining data\n');
    % Normalise new observations with TRAINING mu_Y/sigma_Y (no leakage)
    Y_log_new  = log(max(Y_observed,1e-10));
    Y_norm_new = (Y_log_new - mu_Y) ./ sigma_Y;

    X_train_updated = [X_train; X_events];
    Y_train_updated = [Y_train; Y_norm_new];

    fprintf('  Updated training set: %d samples (was %d)\n', ...
        size(X_train_updated,1), size(X_train,1));
    save('DT_RetrainData_REVISED.mat','X_train_updated','Y_train_updated');
    fprintf('  Saved: DT_RetrainData_REVISED.mat\n');
else
    fprintf('\n[OK] No significant drift. Model is stable.\n');
end

save('DT_Step5_Results_REVISED.mat', ...
    'rolling_rmse','drift_flags','retrain_flags','rel_errors', ...
    'mean_rel_err','N_events','WINDOW_SIZE');
fprintf('\n  Saved: DT_Step5_Results_REVISED.mat\n');
fprintf('\n================================================\n');
fprintf('  DT STEP 5 COMPLETE\n');
fprintf('================================================\n');