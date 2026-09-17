%% ========================================================================
%  DIGITAL TWIN - STEP 2 (REVISED): REAL-TIME INFERENCE ENGINE
%  Column detection fixed for actual Excel feature names
%% ========================================================================
clc; clear; close all;

load('DigitalTwin_Base_REVISED.mat');

fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 2 (REVISED): INFERENCE\n');
fprintf('  Surrogate: %s\n', DT.model_type);
fprintf('================================================\n\n');

outputLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
colors4 = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.7 0.3; 0.7 0.3 0.8];
ls      = {'-','--','-.',':'};
nFeat   = DT.nFeatures;

%% ---- Column detection (matched to actual Excel names) ----------------
fLow = lower(DT.featureNames);

col_NAF     = find(contains(fLow,'active fault'),     1);  % 'No of Active Faults'
col_FL      = find(contains(fLow,'length of fault'),  1);  % 'Length of fault (Lf):'
col_NEQ     = find(contains(fLow,'earthquake'),       1);  % 'No of Earthquake...'
col_Rmax    = find(contains(fLow,'rmax'),             1);  % 'Max. Hypocentre distance(Rmax)'
col_Rmin    = find(contains(fLow,'rmin'),             1);  % 'Min. Hypocentre distance(Rmin)'
col_M0      = find(contains(fLow,'min. magnitude'),   1);  % 'Min. Magnitude (M0):'
col_Mu      = find(contains(fLow,'max. magnitude'),   1);  % 'Max. Magnitude (Mu):'
col_aval    = find(contains(fLow,'value of a'),       1);  % 'value of a'
col_bval    = find(contains(fLow,'value of b'),       1);  % 'value of b'
col_Att     = find(contains(fLow,'attenuationmodel'), 1);  % 'AttenuationModel'

% Engineered features
col_Rratio  = find(contains(fLow,'rratio'),  1);
col_Mrange  = find(contains(fLow,'mrange'),  1);
col_logRmax = find(contains(fLow,'logrmax'), 1);
col_logRmin = find(contains(fLow,'logrmin'), 1);
col_logFL   = find(contains(fLow,'logfault'),1);
col_DistMag = find(contains(fLow,'distmag'), 1);

%% ---- Print feature map -----------------------------------------------
fprintf('[0] Feature map (%d features):\n', nFeat);
allColNames = {'NAF','FaultLen','NumEQ','Rmax','Rmin','M0','Mu', ...
               'a_val','b_val','AttModel', ...
               'Rratio','Mrange','logRmax','logRmin','logFL','DistMag'};
allColIdxs  = {col_NAF,col_FL,col_NEQ,col_Rmax,col_Rmin,col_M0,col_Mu, ...
               col_aval,col_bval,col_Att, ...
               col_Rratio,col_Mrange,col_logRmax,col_logRmin,col_logFL,col_DistMag};
for ci = 1:length(allColNames)
    if isempty(allColIdxs{ci})
        fprintf('    %-12s = N/A\n', allColNames{ci});
    else
        fprintf('    %-12s = col %d  (%s)\n', ...
            allColNames{ci}, allColIdxs{ci}, DT.featureNames{allColIdxs{ci}});
    end
end
fprintf('\n');

%% ---- Default feature vector (training mean) --------------------------
default_feat = reshape(DT.mu_X, 1, nFeat);

%% ---- Inline engineered feature update --------------------------------
% Reusable block: updates engineered cols from base physical values in x
% Called after setting any base feature value

%% ========================================================================
%% TEST 1: Single new site prediction
%% ========================================================================
fprintf('[TEST 1] Single new site prediction\n');

naf=8; fl=85; neq=45; rmax=120; rmin=40; m0=4.0; mu=6.5; att=1;

x_new = default_feat;
if ~isempty(col_NAF),  x_new(col_NAF)  = naf;  end
if ~isempty(col_FL),   x_new(col_FL)   = fl;   end
if ~isempty(col_NEQ),  x_new(col_NEQ)  = neq;  end
if ~isempty(col_Rmax), x_new(col_Rmax) = rmax; end
if ~isempty(col_Rmin), x_new(col_Rmin) = rmin; end
if ~isempty(col_M0),   x_new(col_M0)   = m0;   end
if ~isempty(col_Mu),   x_new(col_Mu)   = mu;   end
if ~isempty(col_Att),  x_new(col_Att)  = att;  end

% Update engineered features
if ~isempty(col_Rratio)  && ~isempty(col_Rmax) && ~isempty(col_Rmin)
    x_new(col_Rratio)  = x_new(col_Rmax)/(x_new(col_Rmin)+1);        end
if ~isempty(col_Mrange)  && ~isempty(col_Mu)   && ~isempty(col_M0)
    x_new(col_Mrange)  = x_new(col_Mu) - x_new(col_M0);               end
if ~isempty(col_logRmax) && ~isempty(col_Rmax)
    x_new(col_logRmax) = log(x_new(col_Rmax)+1);                       end
if ~isempty(col_logRmin) && ~isempty(col_Rmin)
    x_new(col_logRmin) = log(x_new(col_Rmin)+1);                       end
if ~isempty(col_logFL)   && ~isempty(col_FL)
    x_new(col_logFL)   = log(x_new(col_FL)+1);                         end
if ~isempty(col_DistMag) && ~isempty(col_Rmax) && ~isempty(col_Mu)
    x_new(col_DistMag) = log(x_new(col_Rmax)+1)*x_new(col_Mu);        end

tic;
pga_new  = DT_predict_REVISED(DT, x_new);
t_single = toc;

fprintf('  NAF=%d  FL=%dkm  NumEQ=%d  Rmax=%dkm  M0=%.1f  Mu=%.1f  Att=%d\n', ...
    naf,fl,neq,rmax,m0,mu,att);
for k=1:4
    fprintf('  %-20s = %.5f g\n', outputLabels{k}, pga_new(k));
end
fprintf('  Inference time: %.4f ms\n\n', t_single*1000);

%% ========================================================================
%% TEST 2: Batch prediction on test set
%% ========================================================================
fprintf('[TEST 2] Batch prediction (%d test sites)\n', size(DT.X_test_raw,1));
tic;
pga_batch = DT_predict_REVISED(DT, DT.X_test_raw);
t_batch   = toc;
fprintf('  %d sites in %.3f s (%.1f sites/s)\n\n', ...
    size(DT.X_test_raw,1), t_batch, size(DT.X_test_raw,1)/t_batch);

fprintf('  Accuracy vs ground truth:\n');
for k=1:4
    mre = median(abs(pga_batch(:,k)-DT.Y_pga_test(:,k))./DT.Y_pga_test(:,k))*100;
    fprintf('    %-20s  Median Rel Err = %.2f%%\n', outputLabels{k}, mre);
end
fprintf('\n');

%% ========================================================================
%% TEST 3: Gujarat city PGA table
%% ========================================================================
fprintf('[TEST 3] Gujarat cities PGA table\n\n');

% Name  NAF  FL   NEQ  Rmax  Rmin  M0   Mu   Att
cities = {
    'Ahmedabad',    6,   80,  35,  150, 50,  4.0, 6.2, 1;
    'Surat',        5,   70,  25,  130, 45,  4.0, 6.0, 1;
    'Bharuch',      7,   90,  40,  140, 48,  4.0, 6.3, 2;
    'Vadodara',     6,   75,  30,  135, 46,  4.0, 6.1, 1;
    'Gandhinagar',  6,   80,  35,  148, 50,  4.0, 6.2, 1;
    'Rajkot',       8,   95,  50,  160, 55,  4.0, 6.5, 2;
    'Bhuj',         12,  150, 80,  200, 30,  4.0, 7.6, 3;
    'Anand',        6,   78,  33,  142, 48,  4.0, 6.1, 1;
};

fprintf('  %-14s  %10s  %11s  %11s  %11s\n', ...
    'City','2%/50yr(g)','10%/50yr(g)','2%/100yr(g)','10%/100yr(g)');
fprintf('  %s\n', repmat('-',1,64));

city_pga = zeros(size(cities,1),4);
for c = 1:size(cities,1)
    x_c = default_feat;
    if ~isempty(col_NAF),  x_c(col_NAF)  = cities{c,2}; end
    if ~isempty(col_FL),   x_c(col_FL)   = cities{c,3}; end
    if ~isempty(col_NEQ),  x_c(col_NEQ)  = cities{c,4}; end
    if ~isempty(col_Rmax), x_c(col_Rmax) = cities{c,5}; end
    if ~isempty(col_Rmin), x_c(col_Rmin) = cities{c,6}; end
    if ~isempty(col_M0),   x_c(col_M0)   = cities{c,7}; end
    if ~isempty(col_Mu),   x_c(col_Mu)   = cities{c,8}; end
    if ~isempty(col_Att),  x_c(col_Att)  = cities{c,9}; end
    % Update engineered features
    if ~isempty(col_Rratio)  && ~isempty(col_Rmax) && ~isempty(col_Rmin)
        x_c(col_Rratio)  = x_c(col_Rmax)/(x_c(col_Rmin)+1);          end
    if ~isempty(col_Mrange)  && ~isempty(col_Mu)   && ~isempty(col_M0)
        x_c(col_Mrange)  = x_c(col_Mu) - x_c(col_M0);                 end
    if ~isempty(col_logRmax) && ~isempty(col_Rmax)
        x_c(col_logRmax) = log(x_c(col_Rmax)+1);                       end
    if ~isempty(col_logRmin) && ~isempty(col_Rmin)
        x_c(col_logRmin) = log(x_c(col_Rmin)+1);                       end
    if ~isempty(col_logFL)   && ~isempty(col_FL)
        x_c(col_logFL)   = log(x_c(col_FL)+1);                         end
    if ~isempty(col_DistMag) && ~isempty(col_Rmax) && ~isempty(col_Mu)
        x_c(col_DistMag) = log(x_c(col_Rmax)+1)*x_c(col_Mu);          end

    city_pga(c,:) = DT_predict_REVISED(DT, x_c);
    fprintf('  %-14s  %10.5f  %11.5f  %11.5f  %11.5f\n', ...
        cities{c,1}, city_pga(c,1), city_pga(c,2), city_pga(c,3), city_pga(c,4));
end

%% ========================================================================
%% TEST 4: Feature sensitivity sweep
%% ========================================================================
fprintf('\n[TEST 4] Feature sensitivity sweep\n');

% Only add sweeps for columns that were found
sweep_defs = {};
if ~isempty(col_NEQ),  sweep_defs(end+1,:) = {'No. of Earthquakes', 5,   180, 25, col_NEQ};  end
if ~isempty(col_Rmax), sweep_defs(end+1,:) = {'Rmax (km)',          24,  520, 25, col_Rmax}; end
if ~isempty(col_FL),   sweep_defs(end+1,:) = {'Fault Length (km)',  15,  420, 25, col_FL};   end
if ~isempty(col_Mu),   sweep_defs(end+1,:) = {'Max Magnitude (Mu)', 5.5, 8.3, 20, col_Mu};  end

nSweeps = size(sweep_defs,1);
fprintf('  %d sweeps found (only detected columns)\n', nSweeps);

if nSweeps > 0
    fig_sens = figure('Position',[50 50 1200 800],'Color','w');
    nRows = ceil(nSweeps/2);

    for s = 1:nSweeps
        feat_name  = sweep_defs{s,1};
        sweep_vals = linspace(sweep_defs{s,2}, sweep_defs{s,3}, sweep_defs{s,4})';
        col_idx    = sweep_defs{s,5};

        x_sweep = repmat(default_feat, length(sweep_vals), 1);
        x_sweep(:, col_idx) = sweep_vals;

        % Update engineered features for each sweep row
        for row = 1:length(sweep_vals)
            rv   = x_sweep(row, col_Rmax);
            ri   = x_sweep(row, col_Rmin);
            mu_v = x_sweep(row, col_Mu);
            m0_v = x_sweep(row, col_M0);
            fl_v = x_sweep(row, col_FL);
            if ~isempty(col_Rratio)  && ~isempty(col_Rmax) && ~isempty(col_Rmin)
                x_sweep(row,col_Rratio)  = rv/(ri+1);             end
            if ~isempty(col_Mrange)  && ~isempty(col_Mu) && ~isempty(col_M0)
                x_sweep(row,col_Mrange)  = mu_v - m0_v;           end
            if ~isempty(col_logRmax) && ~isempty(col_Rmax)
                x_sweep(row,col_logRmax) = log(rv+1);              end
            if ~isempty(col_logRmin) && ~isempty(col_Rmin)
                x_sweep(row,col_logRmin) = log(ri+1);              end
            if ~isempty(col_logFL)   && ~isempty(col_FL)
                x_sweep(row,col_logFL)   = log(fl_v+1);            end
            if ~isempty(col_DistMag) && ~isempty(col_Rmax) && ~isempty(col_Mu)
                x_sweep(row,col_DistMag) = log(rv+1)*mu_v;         end
        end

        pga_sweep = DT_predict_REVISED(DT, x_sweep);

        subplot(nRows, 2, s); hold on;
        for k=1:4
            plot(sweep_vals, pga_sweep(:,k), ls{k}, ...
                'LineWidth',2.5,'Color',colors4(k,:));
        end
        xlabel(feat_name,'FontSize',11,'FontWeight','bold');
        ylabel('PGA (g)','FontSize',11,'FontWeight','bold');
        title(sprintf('PGA vs %s', feat_name),'FontSize',11,'FontWeight','bold');
        if s==1, legend(outputLabels,'Location','best','FontSize',9); end
        grid on; box on;
    end
    sgtitle(sprintf('Digital Twin (%s): Feature Sensitivity',DT.model_type), ...
        'FontSize',13,'FontWeight','bold');
    saveas(fig_sens,'DT_Step2_Sensitivity_REVISED.png');
    print(fig_sens,'DT_Step2_Sensitivity_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Step2_Sensitivity_REVISED.png\n');
    close(fig_sens);
else
    fprintf('  [WARNING] No sweep columns detected — check featureNames.\n');
end

%% ---- Save -----------------------------------------------------------
save('DT_Step2_Results_REVISED.mat','pga_batch','city_pga','cities','t_batch');
fprintf('\n  Saved: DT_Step2_Results_REVISED.mat\n');
fprintf('\n================================================\n');
fprintf('  DT STEP 2 COMPLETE\n');
fprintf('================================================\n');