%% ========================================================================
%  DIGITAL TWIN - STEP 4 (REVISED): SCENARIO ENGINE
%  Column detection fixed for actual Excel feature names
%% ========================================================================
clc; clear; close all;

load('DigitalTwin_Base_REVISED.mat');

fprintf('================================================\n');
fprintf('  DIGITAL TWIN STEP 4 (REVISED): SCENARIO ENGINE\n');
fprintf('================================================\n\n');

outputLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
colors4 = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.7 0.3; 0.7 0.3 0.8];
ls      = {'-','--','-.',':'};

X_test_raw    = DT.X_test_raw;
pga_use       = DT_predict_REVISED(DT, X_test_raw);
data_src      = sprintf('%s predictions (revised pipeline)', DT.model_type);
N             = size(X_test_raw,1);
win           = max(15, floor(N/20));
default_feat  = reshape(DT.mu_X, 1, DT.nFeatures);

%% ---- Column detection (correct Excel names) --------------------------
fLow = lower(DT.featureNames);
c_NAF  = find(contains(fLow,'active fault'),     1);
c_FL   = find(contains(fLow,'length of fault'),  1);
c_NEQ  = find(contains(fLow,'earthquake'),       1);
c_Rmax = find(contains(fLow,'rmax'),             1);
c_Rmin = find(contains(fLow,'rmin'),             1);
c_M0   = find(contains(fLow,'min. magnitude'),   1);
c_Mu   = find(contains(fLow,'max. magnitude'),   1);
c_Att  = find(contains(fLow,'attenuationmodel'), 1);

col_Rratio  = find(contains(fLow,'rratio'),  1);
col_Mrange  = find(contains(fLow,'mrange'),  1);
col_logRmax = find(contains(fLow,'logrmax'), 1);
col_logRmin = find(contains(fLow,'logrmin'), 1);
col_logFL   = find(contains(fLow,'logfault'),1);
col_DistMag = find(contains(fLow,'distmag'), 1);

fprintf('Test samples: %d | Source: %s\n\n', N, data_src);

%% ---- Scenario 1: PGA vs NumEQ ----------------------------------------
if ~isempty(c_NEQ)
    fprintf('[1] PGA vs NumEQ\n');
    [xsort,sidx]=sort(X_test_raw(:,c_NEQ));
    fig1=figure('Position',[50 50 950 550],'Color','w'); hold on;
    for k=1:4, scatter(X_test_raw(:,c_NEQ),pga_use(:,k),8,colors4(k,:),'filled','MarkerFaceAlpha',0.25); end
    for k=1:4, plot(xsort,smooth(pga_use(sidx,k),win,'rloess'),ls{k},'LineWidth',2.5,'Color',colors4(k,:)); end
    set(gca,'YScale','log');
    xlabel('No. of Earthquakes','FontSize',12,'FontWeight','bold');
    ylabel('PGA (g)','FontSize',12,'FontWeight','bold');
    title(sprintf('Digital Twin: PGA vs NumEQ\n(%s)',data_src),'FontSize',12,'FontWeight','bold');
    legend(outputLabels,'Location','best','FontSize',10); grid on; box on;
    saveas(fig1,'DT_Scenario_NumEQ_REVISED.png');
    print(fig1,'DT_Scenario_NumEQ_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_NumEQ_REVISED.png\n'); close(fig1);
end

%% ---- Scenario 2: PGA vs Rmax -----------------------------------------
if ~isempty(c_Rmax)
    fprintf('[2] PGA vs Rmax\n');
    [xsort2,sidx2]=sort(X_test_raw(:,c_Rmax));
    fig2=figure('Position',[50 50 950 550],'Color','w'); hold on;
    for k=1:4, scatter(X_test_raw(:,c_Rmax),pga_use(:,k),8,colors4(k,:),'filled','MarkerFaceAlpha',0.25); end
    for k=1:4, plot(xsort2,smooth(pga_use(sidx2,k),win,'rloess'),ls{k},'LineWidth',2.5,'Color',colors4(k,:)); end
    set(gca,'YScale','log');
    xlabel('Rmax (km)','FontSize',12,'FontWeight','bold');
    ylabel('PGA (g)','FontSize',12,'FontWeight','bold');
    title(sprintf('Digital Twin: PGA vs Rmax\n(%s)',data_src),'FontSize',12,'FontWeight','bold');
    legend(outputLabels,'Location','best','FontSize',10); grid on; box on;
    saveas(fig2,'DT_Scenario_Rmax_REVISED.png');
    print(fig2,'DT_Scenario_Rmax_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_Rmax_REVISED.png\n'); close(fig2);
end

%% ---- Scenario 3: PGA vs Fault Length ---------------------------------
if ~isempty(c_FL)
    fprintf('[3] PGA vs Fault Length\n');
    [xsort3,sidx3]=sort(X_test_raw(:,c_FL));
    fig3=figure('Position',[50 50 950 550],'Color','w'); hold on;
    for k=1:4, scatter(X_test_raw(:,c_FL),pga_use(:,k),8,colors4(k,:),'filled','MarkerFaceAlpha',0.25); end
    for k=1:4, plot(xsort3,smooth(pga_use(sidx3,k),win,'rloess'),ls{k},'LineWidth',2.5,'Color',colors4(k,:)); end
    set(gca,'YScale','log');
    xlabel('Fault Length (km)','FontSize',12,'FontWeight','bold');
    ylabel('PGA (g)','FontSize',12,'FontWeight','bold');
    title(sprintf('Digital Twin: PGA vs Fault Length\n(%s)',data_src),'FontSize',12,'FontWeight','bold');
    legend(outputLabels,'Location','best','FontSize',10); grid on; box on;
    saveas(fig3,'DT_Scenario_FaultLength_REVISED.png');
    print(fig3,'DT_Scenario_FaultLength_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_FaultLength_REVISED.png\n'); close(fig3);
end

%% ---- Scenario 4: PGA vs Mu -------------------------------------------
if ~isempty(c_Mu)
    fprintf('[4] PGA vs Max Magnitude (Mu)\n');
    [xsort4,sidx4]=sort(X_test_raw(:,c_Mu));
    fig4=figure('Position',[50 50 950 550],'Color','w'); hold on;
    for k=1:4, scatter(X_test_raw(:,c_Mu),pga_use(:,k),8,colors4(k,:),'filled','MarkerFaceAlpha',0.25); end
    for k=1:4, plot(xsort4,smooth(pga_use(sidx4,k),win,'rloess'),ls{k},'LineWidth',2.5,'Color',colors4(k,:)); end
    set(gca,'YScale','log');
    xlabel('Max Magnitude (Mu)','FontSize',12,'FontWeight','bold');
    ylabel('PGA (g)','FontSize',12,'FontWeight','bold');
    title(sprintf('Digital Twin: PGA vs Max Magnitude\n(%s)',data_src),'FontSize',12,'FontWeight','bold');
    legend(outputLabels,'Location','best','FontSize',10); grid on; box on;
    saveas(fig4,'DT_Scenario_Mu_REVISED.png');
    print(fig4,'DT_Scenario_Mu_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_Mu_REVISED.png\n'); close(fig4);
end

%% ---- Scenario 5: Mw sweep -------------------------------------------
fprintf('[5] Mw scenario sweep\n');
if ~isempty(c_Mu)
    Mw_range = linspace(5.5, 8.3, 50)';
    x_Mw     = repmat(default_feat, length(Mw_range), 1);
    x_Mw(:,c_Mu) = Mw_range;
    if ~isempty(col_Mrange) && ~isempty(c_M0)
        x_Mw(:,col_Mrange) = Mw_range - x_Mw(:,c_M0);       end
    if ~isempty(col_DistMag) && ~isempty(c_Rmax)
        x_Mw(:,col_DistMag)= log(x_Mw(:,c_Rmax)+1).*Mw_range; end
    pga_Mw = DT_predict_REVISED(DT, x_Mw);
else
    Mw_range = linspace(5.5,8.3,50)';
    pga_Mw   = repmat(mean(pga_use),50,1);
end

fig5=figure('Position',[50 50 800 500],'Color','w'); hold on;
for k=1:4, plot(Mw_range,pga_Mw(:,k),ls{k},'LineWidth',2.5,'Color',colors4(k,:)); end
xlabel('Moment Magnitude M_w','FontSize',12,'FontWeight','bold');
ylabel('PGA (g)','FontSize',12,'FontWeight','bold');
title('Digital Twin Scenario: PGA vs M_w','FontSize',12,'FontWeight','bold');
legend(outputLabels,'Location','northwest','FontSize',10); grid on; box on;
saveas(fig5,'DT_Scenario_Mw_REVISED.png');
print(fig5,'DT_Scenario_Mw_REVISED','-dpng','-r300');
fprintf('  Saved: DT_Scenario_Mw_REVISED.png\n'); close(fig5);

%% ---- Scenario 6: Attenuation model -----------------------------------
if ~isempty(c_Att)
    fprintf('[6] Attenuation model comparison\n');
    att_vals=unique(X_test_raw(:,c_Att));
    fig6=figure('Position',[50 50 1100 700],'Color','w');
    for k=1:4
        subplot(2,2,k); hold on;
        grp_data=[]; grp_label=[];
        for a=1:length(att_vals)
            idx_a=X_test_raw(:,c_Att)==att_vals(a);
            if sum(idx_a)<5, continue; end
            grp_data=[grp_data; pga_use(idx_a,k)];
            grp_label=[grp_label; repmat(a,sum(idx_a),1)];
        end
        boxplot(grp_data,grp_label,'Labels', ...
            arrayfun(@(v)sprintf('Att=%d',v),att_vals,'UniformOutput',false),'Symbol','+');
        set(gca,'YScale','log','FontSize',9);
        ylabel('PGA (g)','FontSize',9); title(outputLabels{k},'FontSize',10,'FontWeight','bold');
        grid on;
    end
    sgtitle('Digital Twin: PGA by Attenuation Model','FontSize',12,'FontWeight','bold');
    saveas(fig6,'DT_Scenario_AttModel_REVISED.png');
    print(fig6,'DT_Scenario_AttModel_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_AttModel_REVISED.png\n'); close(fig6);
end

%% ---- Scenario 7: PGA scatter (NumEQ vs Rmax) -------------------------
fprintf('[7] PGA scatter — NumEQ vs Rmax\n');
if ~isempty(c_NEQ) && ~isempty(c_Rmax)
    fig7=figure('Position',[50 50 1200 500],'Color','w');
    for k=1:4
        subplot(1,4,k);
        scatter(X_test_raw(:,c_NEQ),X_test_raw(:,c_Rmax),15,log10(pga_use(:,k)),'filled','MarkerFaceAlpha',0.7);
        colormap(jet(256));
        cb=colorbar; cb.Label.String='log_{10}(PGA g)'; cb.FontSize=8;
        xlabel('No. of Earthquakes','FontSize',9,'FontWeight','bold');
        ylabel('Rmax (km)','FontSize',9,'FontWeight','bold');
        title(outputLabels{k},'FontSize',9,'FontWeight','bold'); grid on; box on;
    end
    sgtitle(sprintf('Digital Twin: PGA in NumEQ-Rmax Space\n(%s)',data_src),'FontSize',12,'FontWeight','bold');
    saveas(fig7,'DT_Scenario_PGAscatter_REVISED.png');
    print(fig7,'DT_Scenario_PGAscatter_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_PGAscatter_REVISED.png\n'); close(fig7);
end

%% ---- Scenario 8: Sensitivity tornado ---------------------------------
fprintf('[8] Sensitivity tornado\n');
act_cols  = []; act_names = {};
if ~isempty(c_NAF),  act_cols(end+1)=c_NAF;  act_names{end+1}='No of Active Faults'; end
if ~isempty(c_FL),   act_cols(end+1)=c_FL;   act_names{end+1}='Fault Length';         end
if ~isempty(c_NEQ),  act_cols(end+1)=c_NEQ;  act_names{end+1}='No of Earthquakes';    end
if ~isempty(c_Rmax), act_cols(end+1)=c_Rmax; act_names{end+1}='Rmax (km)';            end
if ~isempty(c_Rmin), act_cols(end+1)=c_Rmin; act_names{end+1}='Rmin (km)';            end
if ~isempty(c_Mu),   act_cols(end+1)=c_Mu;   act_names{end+1}='Max Magnitude (Mu)';   end
if ~isempty(c_Att),  act_cols(end+1)=c_Att;  act_names{end+1}='Attenuation Model';    end

n_act=length(act_cols); k_plot=1;
pga_lo_q=zeros(n_act,1); pga_hi_q=zeros(n_act,1);
for f=1:n_act
    fv=X_test_raw(:,act_cols(f));
    idx_lo=fv<=prctile(fv,10); idx_hi=fv>=prctile(fv,90);
    if sum(idx_lo)<3||sum(idx_hi)<3, continue; end
    pga_lo_q(f)=median(pga_use(idx_lo,k_plot));
    pga_hi_q(f)=median(pga_use(idx_hi,k_plot));
end
delta_q=pga_hi_q-pga_lo_q;
[~,sidx]=sort(abs(delta_q),'descend');

fig8=figure('Position',[50 50 950 600],'Color','w'); hold on;
for f=1:n_act
    fi=sidx(f); ypos=n_act+1-f; val=delta_q(fi);
    col=[0.8 0.2 0.2]; if val<0, col=[0.2 0.4 0.8]; end
    barh(ypos,val,0.55,'FaceColor',col,'EdgeColor','none');
    if abs(val)>0
        text(val+sign(val)*max(abs(delta_q))*0.01,ypos,sprintf('%.4f g',val),...
            'FontSize',8,'VerticalAlignment','middle');
    end
end
xline(0,'k-','LineWidth',2);
set(gca,'YTick',1:n_act,'YTickLabel',flipud(act_names(sidx)),'FontSize',10);
xlabel('Median PGA (g): 90th - 10th percentile','FontSize',11,'FontWeight','bold');
title(sprintf('Sensitivity Tornado — %s',outputLabels{k_plot}),'FontSize',11,'FontWeight','bold');
h1=patch(NaN,NaN,[0.8 0.2 0.2]); h2=patch(NaN,NaN,[0.2 0.4 0.8]);
legend([h1 h2],{'PGA increases','PGA decreases'},'Location','southeast','FontSize',9);
grid on; box on;
saveas(fig8,'DT_Scenario_Tornado_REVISED.png');
print(fig8,'DT_Scenario_Tornado_REVISED','-dpng','-r300');
fprintf('  Saved: DT_Scenario_Tornado_REVISED.png\n'); close(fig8);

%% ---- Scenario 9: 2D Heatmap NumEQ vs Rmax ---------------------------
if ~isempty(c_NEQ) && ~isempty(c_Rmax)
    fprintf('[9] 2D heatmap: NumEQ vs Rmax\n');
    neq_vals=X_test_raw(:,c_NEQ); rmax_vals=X_test_raw(:,c_Rmax); pga_vals=pga_use(:,1);
    n_grid=80;
    neq_vec =linspace(min(neq_vals), max(neq_vals), n_grid);
    rmax_vec=linspace(min(rmax_vals),max(rmax_vals),n_grid);
    [NEQ_grid,RMAX_grid]=meshgrid(neq_vec,rmax_vec);
    PGA_grid=griddata(neq_vals,rmax_vals,pga_vals,NEQ_grid,RMAX_grid,'linear');
    PGA_grid=fillmissing(PGA_grid,'nearest',1);
    PGA_grid=fillmissing(PGA_grid,'nearest',2);
    PGA_grid=imgaussfilt(PGA_grid,2.0);
    k_hull=convhull(neq_vals,rmax_vals);
    in_hull=inpolygon(NEQ_grid(:),RMAX_grid(:),neq_vals(k_hull),rmax_vals(k_hull));
    PGA_grid(~reshape(in_hull,n_grid,n_grid))=NaN;

    fig9=figure('Position',[50 50 900 680],'Color','w');
    contourf(NEQ_grid,RMAX_grid,PGA_grid,25,'LineStyle','none');
    colormap(jet(256));
    caxis([prctile(pga_vals,5),prctile(pga_vals,95)]);
    cb=colorbar; cb.Label.String='PGA 2%/50yr (g)'; cb.Label.FontSize=11; cb.FontSize=10;
    hold on;
    contour(NEQ_grid,RMAX_grid,PGA_grid,8,'k-','LineWidth',0.7);
    plot(neq_vals(k_hull),rmax_vals(k_hull),'k-','LineWidth',1.8);
    scatter(neq_vals,rmax_vals,5,'k','filled','MarkerFaceAlpha',0.12);
    xlabel('No. of Earthquakes','FontSize',12,'FontWeight','bold');
    ylabel('Rmax (km)','FontSize',12,'FontWeight','bold');
    title('Digital Twin 2D Heatmap — PGA 2%/50yr','FontSize',12,'FontWeight','bold');
    grid on; box on;
    saveas(fig9,'DT_Scenario_2D_Heatmap_REVISED.png');
    print(fig9,'DT_Scenario_2D_Heatmap_REVISED','-dpng','-r300');
    fprintf('  Saved: DT_Scenario_2D_Heatmap_REVISED.png\n'); close(fig9);
end

%% ---- Save -----------------------------------------------------------
save('DT_Step4_Results_REVISED.mat', ...
    'pga_use','delta_q','sidx','act_names', ...
    'Mw_range','pga_Mw','X_test_raw','outputLabels','data_src');
fprintf('\n  Saved: DT_Step4_Results_REVISED.mat\n');
fprintf('\n================================================\n');
fprintf('  DT STEP 4 COMPLETE\n');
fprintf('================================================\n');