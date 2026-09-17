%% ========================================================================
%  DIGITAL TWIN - STEP 6 (REVISED): FULL DASHBOARD + TEXT REPORT
%  SVR Surrogate (Best Model — Test R2=0.9746)
%  Column detection fixed — no hardcoded indices, no DT.col references
%% ========================================================================
clc; clear; close all;

load('DigitalTwin_Base_REVISED.mat');
load('DT_Step3_Results_REVISED.mat');   % pga_mean, pga_cv
load('DT_Step4_Results_REVISED.mat');   % pga_use, Mw_range, pga_Mw
load('DT_Step5_Results_REVISED.mat');   % rolling_rmse, drift_flags, retrain_flags

fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 6 (REVISED): DASHBOARD\n');
fprintf('================================================\n\n');

outputLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
colors4      = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.7 0.3; 0.7 0.3 0.8];
ls           = {'-','--','-.',':'};

X_test_raw = DT.X_test_raw;

%% ---- Column detection (correct Excel names — no DT.col used) ---------
fLow   = lower(DT.featureNames);
c_NEQ  = find(contains(fLow,'earthquake'),       1);  % No of Earthquake...
c_Rmax = find(contains(fLow,'rmax'),             1);  % Max. Hypocentre distance(Rmax)
c_Mu   = find(contains(fLow,'max. magnitude'),   1);  % Max. Magnitude (Mu):
c_Att  = find(contains(fLow,'attenuationmodel'), 1);  % AttenuationModel

fprintf('Column detection: NEQ=%s | Rmax=%s | Mu=%s | Att=%s\n\n', ...
    num2str(c_NEQ), num2str(c_Rmax), num2str(c_Mu), num2str(c_Att));

%% ---- Safe axis values (fallback if column not found) -----------------
if ~isempty(c_Rmax), x_vals = X_test_raw(:,c_Rmax); x_lbl = 'Rmax (km)';
else,                x_vals = (1:size(X_test_raw,1))'; x_lbl = 'Sample index'; end

if ~isempty(c_NEQ),  clr_vals = X_test_raw(:,c_NEQ); clr_lbl = 'NumEQ';
else,                clr_vals = pga_mean(:,1);         clr_lbl = 'PGA (g)';   end

%% ---- Build dashboard figure ------------------------------------------
fig = figure('Position',[20 20 1600 1050],'Color','w');

annotation(fig,'textbox',[0 0.955 1 0.042], ...
    'String',['PSHA Digital Twin Dashboard — SVR (Best Model, Test R2=0.9746) | ' ...
              'Site-Based Split | Gujarat Seismic Hazard'], ...
    'FontSize',12,'FontWeight','bold','HorizontalAlignment','center', ...
    'VerticalAlignment','middle','EdgeColor','none', ...
    'Color',[0.08 0.08 0.38],'BackgroundColor',[0.95 0.97 1.0]);

%% Panels 1-4: Mean PGA scatter (Rmax vs PGA, coloured by NumEQ)
panel_pos = {[0.03 0.53 0.21 0.39],[0.26 0.53 0.21 0.39], ...
             [0.03 0.07 0.21 0.39],[0.26 0.07 0.21 0.39]};

for k=1:4
    ax=axes(fig,'Position',panel_pos{k}); %#ok<LAXES>
    scatter(ax, x_vals, pga_mean(:,k), 8, clr_vals, ...
        'filled','MarkerFaceAlpha',0.6);
    colormap(ax,jet(256));
    cb=colorbar(ax,'eastoutside');
    cb.Label.String=clr_lbl; cb.FontSize=7;
    xlabel(ax,x_lbl,'FontSize',8,'FontWeight','bold');
    ylabel(ax,'Mean PGA (g)','FontSize',8,'FontWeight','bold');
    title(ax,outputLabels{k},'FontSize',8.5,'FontWeight','bold');
    set(ax,'FontSize',7,'Box','on','YScale','log','XGrid','on','YGrid','on','GridAlpha',0.15);
end

%% Panel 5: Mw scenario curves
ax5=axes(fig,'Position',[0.52 0.56 0.22 0.37]); %#ok<LAXES>
hold(ax5,'on');
for k=1:4
    plot(ax5,Mw_range,pga_Mw(:,k),ls{k},'LineWidth',2.2,'Color',colors4(k,:));
end
xlabel(ax5,'M_w','FontSize',9,'FontWeight','bold');
ylabel(ax5,'PGA (g)','FontSize',9,'FontWeight','bold');
title(ax5,'Scenario: M_w sensitivity','FontSize',10,'FontWeight','bold');
legend(ax5,{'2%/50yr','10%/50yr','2%/100yr','10%/100yr'}, ...
    'Location','northwest','FontSize',7);
grid(ax5,'on'); box(ax5,'on');

%% Panel 6: Uncertainty CV% scatter
ax6=axes(fig,'Position',[0.77 0.56 0.21 0.37]); %#ok<LAXES>
if ~isempty(c_NEQ) && ~isempty(c_Rmax)
    scatter(ax6, X_test_raw(:,c_NEQ), X_test_raw(:,c_Rmax), 8, pga_cv(:,1), ...
        'filled','MarkerFaceAlpha',0.7);
    xlabel(ax6,'No. of Earthquakes','FontSize',9,'FontWeight','bold');
    ylabel(ax6,'Rmax (km)','FontSize',9,'FontWeight','bold');
else
    scatter(ax6, x_vals, pga_cv(:,1), 8, [0.8 0.3 0.1], ...
        'filled','MarkerFaceAlpha',0.7);
    xlabel(ax6,x_lbl,'FontSize',9,'FontWeight','bold');
    ylabel(ax6,'CV (%)','FontSize',9,'FontWeight','bold');
end
colormap(ax6,hot(256));
cb6=colorbar(ax6,'eastoutside'); cb6.Label.String='CV (%)'; cb6.FontSize=7;
title(ax6,'Uncertainty CV% (2%/50yr)','FontSize',10,'FontWeight','bold');
set(ax6,'FontSize',8,'Box','on','XGrid','on','YGrid','on','GridAlpha',0.15);

%% Panel 7: Drift monitor
ax7=axes(fig,'Position',[0.52 0.10 0.22 0.37]); %#ok<LAXES>
valid = rolling_rmse > 0;
ev_valid = find(valid);
if any(valid)
    plot(ax7,ev_valid,rolling_rmse(valid)*100,'b-','LineWidth',1.5);
end
hold(ax7,'on');
yline(ax7,15,'r--','LineWidth',1.2,'Label','Alert 15%');
yline(ax7,25,'r-', 'LineWidth',1.8,'Label','Retrain 25%');
if any(drift_flags)
    scatter(ax7,find(drift_flags),rolling_rmse(drift_flags)*100,30,[1 0.6 0],'filled');
end
if any(retrain_flags)
    scatter(ax7,find(retrain_flags),rolling_rmse(retrain_flags)*100,40,[1 0 0],'filled');
end
xlabel(ax7,'Event #','FontSize',9,'FontWeight','bold');
ylabel(ax7,'Rolling error (%)','FontSize',9,'FontWeight','bold');
title(ax7,'Live Drift Monitor','FontSize',10,'FontWeight','bold');
grid(ax7,'on'); box(ax7,'on');

%% Panel 8: Test R2 bar chart
ax8=axes(fig,'Position',[0.77 0.10 0.21 0.37]); %#ok<LAXES>
R2_vals = DT.R2_test;
b=bar(ax8,R2_vals,0.6);
b.CData=colors4; b.FaceColor='flat';
r2_min=max(0,min(R2_vals)-0.08); r2_max=min(1,max(R2_vals)+0.04);
set(ax8,'XTick',1:4,'XTickLabel',{'2%/50','10%/50','2%/100','10%/100'}, ...
    'XTickLabelRotation',20,'FontSize',8,'YLim',[r2_min,r2_max]);
ylabel(ax8,'Test R^2','FontSize',9,'FontWeight','bold');
title(ax8,'SVR Test R² per output','FontSize',10,'FontWeight','bold');
grid(ax8,'on'); box(ax8,'on');
for k=1:4
    text(ax8,k,R2_vals(k)+(r2_max-r2_min)*0.03,sprintf('%.4f',R2_vals(k)), ...
        'HorizontalAlignment','center','FontSize',7.5,'FontWeight','bold');
end

saveas(fig,'DT_Dashboard_REVISED.png');
print(fig,'DT_Dashboard_REVISED','-dpng','-r300');
fprintf('  Saved: DT_Dashboard_REVISED.png\n'); close(fig);

%% ---- Text report -----------------------------------------------------
fid=fopen('DT_Report_REVISED.txt','w');
fprintf(fid,'=============================================================\n');
fprintf(fid,'  PSHA DIGITAL TWIN — PERFORMANCE REPORT (REVISED)\n');
fprintf(fid,'  Best Model: SVR | Site-Based Split | Gujarat Seismic Hazard\n');
fprintf(fid,'  Generated: %s\n', datestr(now));
fprintf(fid,'=============================================================\n\n');

fprintf(fid,'PIPELINE:\n');
fprintf(fid,'  Split method : Site-based (no spatial leakage)\n');
fprintf(fid,'  Features     : %d (no Lat/Lon; incl. engineered)\n', DT.nFeatures);
fprintf(fid,'  Normalisation: Training set statistics only\n\n');

fprintf(fid,'MODEL PERFORMANCE (SVR — Best Model):\n');
fprintf(fid,'  %-24s  %8s  %8s  %8s\n','Output','Train R2','Test R2','Gap');
fprintf(fid,'  %s\n',repmat('-',1,52));
for k=1:4
    gap=DT.R2_train(k)-DT.R2_test(k);
    fprintf(fid,'  %-24s  %8.4f  %8.4f  %8.4f\n', ...
        outputLabels{k},DT.R2_train(k),DT.R2_test(k),gap);
end
fprintf(fid,'  Mean                      %8.4f  %8.4f  %8.4f\n\n', ...
    mean(DT.R2_train),mean(DT.R2_test),mean(DT.R2_train-DT.R2_test));

gap_mean=mean(DT.R2_train-DT.R2_test);
if     gap_mean<0.02, verdict='Generalises well — no overfitting';
elseif gap_mean<0.05, verdict='Minor overfit — acceptable';
elseif gap_mean<0.10, verdict='Moderate overfit';
else,                 verdict='SIGNIFICANT OVERFIT'; end
fprintf(fid,'  Verdict: %s\n\n',verdict);

fprintf(fid,'UNCERTAINTY (90%% CI, ensemble=200):\n');
fprintf(fid,'  %-24s  %8s  %8s\n','Output','Mean CV%%','Max CV%%');
fprintf(fid,'  %s\n',repmat('-',1,44));
for k=1:4
    fprintf(fid,'  %-24s  %8.2f  %8.2f\n', ...
        outputLabels{k},mean(pga_cv(:,k)),max(pga_cv(:,k)));
end

fprintf(fid,'\nDRIFT MONITORING (%d simulated events):\n',length(rolling_rmse));
fprintf(fid,'  Drift alerts  : %d\n',sum(drift_flags));
fprintf(fid,'  Retrain alerts: %d\n',sum(retrain_flags));
if any(retrain_flags), ms='RETRAIN RECOMMENDED'; else, ms='STABLE'; end
fprintf(fid,'  Model status  : %s\n',ms);

fprintf(fid,'\nFEATURES USED (%d):\n',DT.nFeatures);
for f=1:DT.nFeatures
    fprintf(fid,'  [%2d] %s\n',f,DT.featureNames{f});
end
fprintf(fid,'\nNOTE: City predictions for cities outside the 4 training cities\n');
fprintf(fid,'are extrapolations. SVR (RBF kernel) extrapolates smoothly but\n');
fprintf(fid,'uncertainty is higher for non-training cities (see Step 3 CI).\n');
fprintf(fid,'\n=============================================================\n');
fclose(fid);
fprintf('  Saved: DT_Report_REVISED.txt\n');

fprintf('\n================================================\n');
fprintf('  DT STEP 6 COMPLETE — DIGITAL TWIN DEPLOYED\n');
fprintf('  Best Model : SVR\n');
fprintf('  Test R2    : %.4f\n', mean(DT.R2_test));
fprintf('  Verdict    : %s\n', verdict);
fprintf('================================================\n');