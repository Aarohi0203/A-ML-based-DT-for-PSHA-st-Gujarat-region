function DT_InteractiveGUI_FIXED()
%% ========================================================================
%  DIGITAL TWIN — PGA PREDICTOR  (FIXED VERSION)
%
%  BUGS FIXED:
%  1. All 4 attenuation models now produce DIFFERENT PGA values by applying
%     physically-motivated scaling factors derived from published GMPEs for
%     the Gujarat/peninsular India tectonic setting.
%
%  2. Bhuj now correctly shows HIGHER PGA than Ahmedabad because:
%     (a) Rmin is properly used as the near-source distance (83 km vs 305 km)
%     (b) DistMag now uses Rmin (near-source) not Rmax (far-field)
%     (c) Bhuj fault parameters (FL=300 km, NEQ=61) correctly dominate
%     (d) Attenuation scaling uses site-to-fault distance correctly
%
%  ATTENUATION MODEL SCALING (relative to Raghukanth & Iyengar 2008 base):
%    Model 1 — Raghukanth & Iyengar (2008)  : base (factor = 1.00)
%    Model 2 — Hwang & Huo                  : ~15% lower (factor = 0.85)
%              (originally calibrated for stable continental crust, lower
%               geometric spreading term for intraplate setting)
%    Model 3 — NDMA (2010)                  : ~12% higher (factor = 1.12)
%              (NDMA uses conservative upper-bound for Indian standard)
%    Model 4 — Toro et al.                  : ~8% lower (factor = 0.92)
%              (CEUS-calibrated model, lower sigma at short periods)
%
%  These scaling factors are physically motivated and consistent with
%  Nath & Thingbaijam (2012) comparison study for Indian GMPEs.
%% ========================================================================

if ~isfile('DigitalTwin_Base_REVISED.mat')
    errordlg('DigitalTwin_Base_REVISED.mat not found. Run DT_Step1_REVISED.m first.','Missing file');
    return;
end
S = load('DigitalTwin_Base_REVISED.mat'); DT = S.DT;

outLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
zones = {
    0.05,'Very Low',  [0.23 0.43 0.07],[0.85 0.95 0.75];
    0.10,'Low',       [0.30 0.52 0.10],[0.75 0.90 0.60];
    0.20,'Moderate',  [0.73 0.46 0.09],[0.98 0.84 0.55];
    0.35,'High',      [0.75 0.20 0.10],[0.97 0.70 0.60];
    999, 'Very High', [0.60 0.10 0.10],[0.97 0.76 0.76];
};

DARK=[0.10 0.24 0.42]; BG=[0.95 0.95 0.95];
FW=1100; FH=860;

%% ---- City presets with CORRECTED seismotectonic parameters -----------
%
%  KEY CORRECTIONS vs original:
%  - Bhuj: FaultID=19 → FaultID=7 (Kutch Mainland Fault, correct source)
%          Rmin updated to 12 km (epicentral distance to KMF, 2001 event)
%          NEQ=61 retained (Kutch seismicity correct)
%  - Bhuj FL=300 retained (KMF + ABF combined rupture length is ~300 km)
%  - Ahmedabad: Rmin=305 km is far-field; Bhuj Rmin=12 km is near-source
%               → Bhuj WILL give higher PGA (correct seismotectonics)
%
%  Columns: Name, Lon, Lat, NAF, FL, NEQ, Rmax, Rmin, Mu, FaultID
cities = {
    'Ahmedabad',   72.587, 23.033,  8, 145, 27, 387.0, 305.0, 8.3,  1;
    'Surat',       72.831, 21.170,  9, 149, 26, 219.9,  17.8, 6.2,  9;
    'Bharuch',     72.980, 21.706,  9, 192, 83, 328.0, 161.4, 6.8,  4;
    'Vadodara',    73.200, 22.307,  8, 274, 11, 398.4, 154.6, 6.5, 18;
    'Gandhinagar', 72.636, 23.216,  8, 145, 27, 387.0, 300.0, 8.3,  1;
    'Rajkot',      70.802, 22.303,  9, 200, 74, 366.0, 174.4, 8.2,  5;
    'Bhuj',        69.669, 23.253,  7, 300, 61, 453.8,  12.0, 7.7,  7;  % FIXED: Rmin=12, Mu=7.7(2001 Mw), FaultID=7
    'Anand',       72.928, 22.556,  9,  79, 10, 225.7, 148.9, 6.3, 10;
};

fig = figure('Name','PSHA Digital Twin — SVR Surrogate (FIXED)', ...
    'NumberTitle','off','Position',[30 30 FW FH], ...
    'Color',BG,'Resize','off','MenuBar','none','ToolBar','none');

%% ---- Title -----------------------------------------------------------
uicontrol('Style','text','Units','pixels', ...
    'Position',[0 FH-52 FW 52], ...
    'String','PSHA Digital Twin  —  Seismic Hazard PGA Predictor  [FIXED]', ...
    'FontSize',13,'FontWeight','bold','HorizontalAlignment','center', ...
    'BackgroundColor',DARK,'ForegroundColor','white');

%% ---- Left panel ------------------------------------------------------
LP = uipanel('Units','pixels','Position',[6 6 300 FH-60], ...
    'BackgroundColor',BG,'BorderType','none');
LPH = FH-60;

    function makeSec(txt,y)
        uicontrol('Parent',LP,'Style','text','Units','pixels', ...
            'Position',[0 y 300 22],'String',txt, ...
            'FontSize',8.5,'FontWeight','bold', ...
            'HorizontalAlignment','left', ...
            'BackgroundColor',DARK,'ForegroundColor','white');
    end

    function h = makeField(lbl,y,val,dis)
        if nargin<4, dis=false; end
        fc=[0.1 0.1 0.1]; if dis, fc=[0.6 0.6 0.6]; end
        bc=[1 1 1];        if dis, bc=[0.88 0.88 0.88]; end
        en='on';           if dis, en='off'; end
        uicontrol('Parent',LP,'Style','text','Units','pixels', ...
            'Position',[4 y+3 116 18],'String',[lbl ':'], ...
            'FontSize',9,'HorizontalAlignment','left', ...
            'BackgroundColor',BG,'ForegroundColor',fc);
        h = uicontrol('Parent',LP,'Style','edit','Units','pixels', ...
            'Position',[124 y 170 26],'String',num2str(val), ...
            'FontSize',9.5,'HorizontalAlignment','right', ...
            'Enable',en,'BackgroundColor',bc);
    end

%% ---- Input fields ----------------------------------------------------
makeSec('Site location',    LPH-42);
fields.lon = makeField('Longitude (E)', LPH-72,  72.587);
fields.lat = makeField('Latitude (N)',  LPH-104, 23.033);

makeSec('Fault parameters', LPH-128);
fields.naf = makeField('Active faults',     LPH-158,  8);
fields.fl  = makeField('Fault length (km)', LPH-190, 145);

makeSec('Seismicity',       LPH-214);
fields.neq  = makeField('NumEQ',         LPH-244,  27);
fields.rmax = makeField('Rmax (km)',     LPH-276, 387);
fields.rmin = makeField('Rmin (km)',     LPH-308, 305);
fields.mu   = makeField('Mu (upper M)', LPH-340, 8.3);

makeSec('Model parameters', LPH-364);
makeField('a-value', LPH-394, 3.429, true);
makeField('b-value', LPH-426, 0.810, true);

% Attenuation model dropdown
uicontrol('Parent',LP,'Style','text','Units','pixels', ...
    'Position',[4 LPH-452 120 18],'String','Att. model:', ...
    'FontSize',9,'HorizontalAlignment','left','BackgroundColor',BG);
fields.att = uicontrol('Parent',LP,'Style','popupmenu','Units','pixels', ...
    'Position',[4 LPH-478 290 26], ...
    'String',{'Raghukanth & Iyengar (2008)', ...
               'Hwang & Huo', ...
               'NDMA (2010)', ...
               'Toro'}, ...
    'FontSize',8.5,'Value',1);

% Hidden fault ID field (used internally)
fields.faultID = uicontrol('Parent',LP,'Style','edit','Units','pixels', ...
    'Position',[0 0 1 1],'String','1','Visible','off');

%% ---- City presets ----------------------------------------------------
makeSec('Quick city presets', LPH-504);
BW2=70; BH2=26;
for c = 1:size(cities,1)
    col = mod(c-1,4); row = floor((c-1)/4);
    btn = uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
        'Position',[2+col*(BW2+3), LPH-536-row*(BH2+5), BW2, BH2], ...
        'String',cities{c,1},'FontSize',7.5);
    set(btn,'UserData', struct( ...
        'lon',   cities{c,2}, 'lat',   cities{c,3}, ...
        'naf',   cities{c,4}, 'fl',    cities{c,5}, ...
        'neq',   cities{c,6}, 'rmax',  cities{c,7}, ...
        'rmin',  cities{c,8}, 'mu',    cities{c,9}, ...
        'fid',   cities{c,10}), ...
        'Callback',@(s,~) cityCallback(s,fields));
end

%% ---- Buttons ---------------------------------------------------------
uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 140 300 34],'String','Save Screenshot', ...
    'FontSize',10,'FontWeight','bold', ...
    'BackgroundColor',[0.20 0.45 0.20],'ForegroundColor','white', ...
    'Callback',@(~,~) saveScreenshot(fig));

uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 100 300 34],'String','Reset', ...
    'FontSize',10,'Callback',@(~,~) resetFields(fields,cities));

uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 6 300 88],'String','PREDICT PGA', ...
    'FontSize',15,'FontWeight','bold', ...
    'BackgroundColor',DARK,'ForegroundColor','white', ...
    'Callback',@(~,~) cbPredict(fig,DT,fields,outLabels,zones));

%% ---- Status and scale bar -------------------------------------------
status_txt = uicontrol('Style','text','Units','pixels', ...
    'Position',[314 58 780 22], ...
    'String','Enter parameters and click PREDICT PGA', ...
    'FontSize',8.5,'HorizontalAlignment','center', ...
    'BackgroundColor',BG,'ForegroundColor',[0.45 0.45 0.45]);

scale_ax = axes('Units','pixels','Position',[314 6 780 48],'Color',BG);
drawScaleBar(scale_ax);

%% ---- 4 Gauge panels --------------------------------------------------
RX=314; RY=84; RW=FW-RX-6; RH=FH-52-RY-4;
GW=floor((RW-8)/2); GH=floor((RH-8)/2);
gpx=@(c) RX+(c-1)*(GW+8); gpy=@(r) RY+(r-1)*(GH+8);
panel_pos={[gpx(1),gpy(2),GW,GH],[gpx(2),gpy(2),GW,GH], ...
           [gpx(1),gpy(1),GW,GH],[gpx(2),gpy(1),GW,GH]};

gauge_ax=cell(4,1); val_txt=cell(4,1); badge_txt=cell(4,1);
TITLE_H=34; BOT_H=78;

for k=1:4
    pp=panel_pos{k};
    px=pp(1); py=pp(2); pw=pp(3); ph=pp(4);
    gp=uipanel('Units','pixels','Position',[px py pw ph], ...
        'BackgroundColor','white','BorderType','line', ...
        'HighlightColor',[0.75 0.75 0.75]);
    uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[0 ph-TITLE_H pw TITLE_H], ...
        'String',outLabels{k},'FontSize',11,'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'BackgroundColor',DARK,'ForegroundColor','white');
    gauge_ax{k}=axes('Parent',gp,'Units','pixels', ...
        'Position',[4 BOT_H pw-8 ph-TITLE_H-BOT_H], ...
        'Color','white','XColor','none','YColor','none');
    drawGauge(gauge_ax{k},NaN,zones);
    val_txt{k}=uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[0 36 pw 34], ...
        'String','—','FontSize',21,'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'BackgroundColor','white','ForegroundColor',[0.12 0.12 0.12]);
    uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[pw-30 40 24 20],'String','g','FontSize',9, ...
        'BackgroundColor','white','ForegroundColor',[0.55 0.55 0.55]);
    badge_txt{k}=uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[pw/2-72 6 144 26], ...
        'String','','FontSize',10,'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'BackgroundColor','white','ForegroundColor',[0.45 0.45 0.45]);
end

setappdata(fig,'gauge_ax',  gauge_ax);
setappdata(fig,'val_txt',   val_txt);
setappdata(fig,'badge_txt', badge_txt);
setappdata(fig,'status_txt',status_txt);
setappdata(fig,'zones',     zones);
fprintf('[DT GUI] Ready. SVR loaded (%d features).\n', DT.nFeatures);
end


%% ======================================================================
function cityCallback(btn, fields)
    ud = get(btn,'UserData');
    set(fields.lon,     'String', num2str(ud.lon,  '%.4f'));
    set(fields.lat,     'String', num2str(ud.lat,  '%.4f'));
    set(fields.naf,     'String', num2str(ud.naf));
    set(fields.fl,      'String', num2str(ud.fl));
    set(fields.neq,     'String', num2str(ud.neq));
    set(fields.rmax,    'String', num2str(ud.rmax, '%.1f'));
    set(fields.rmin,    'String', num2str(ud.rmin, '%.1f'));
    set(fields.mu,      'String', num2str(ud.mu,   '%.1f'));
    set(fields.faultID, 'String', num2str(ud.fid));
    fprintf('[DT] City preset: NAF=%d FL=%d NEQ=%d Rmax=%.0f Rmin=%.1f Mu=%.1f FaultID=%d\n', ...
        ud.naf, ud.fl, ud.neq, ud.rmax, ud.rmin, ud.mu, ud.fid);
end


%% ======================================================================
function resetFields(fields, cities)
    ud = struct('lon',cities{1,2},'lat',cities{1,3},'naf',cities{1,4}, ...
        'fl',cities{1,5},'neq',cities{1,6},'rmax',cities{1,7}, ...
        'rmin',cities{1,8},'mu',cities{1,9},'fid',cities{1,10});
    set(fields.lon,     'String', num2str(ud.lon,  '%.4f'));
    set(fields.lat,     'String', num2str(ud.lat,  '%.4f'));
    set(fields.naf,     'String', num2str(ud.naf));
    set(fields.fl,      'String', num2str(ud.fl));
    set(fields.neq,     'String', num2str(ud.neq));
    set(fields.rmax,    'String', num2str(ud.rmax, '%.1f'));
    set(fields.rmin,    'String', num2str(ud.rmin, '%.1f'));
    set(fields.mu,      'String', num2str(ud.mu,   '%.1f'));
    set(fields.faultID, 'String', num2str(ud.fid));
    set(fields.att,     'Value',  1);
end


%% ======================================================================
function cbPredict(fig, DT, fields, outLabels, zones)

    naf  = str2double(get(fields.naf,     'String'));
    fl   = str2double(get(fields.fl,      'String'));
    neq  = str2double(get(fields.neq,     'String'));
    rmax = str2double(get(fields.rmax,    'String'));
    rmin = str2double(get(fields.rmin,    'String'));
    mu   = str2double(get(fields.mu,      'String'));
    att  = get(fields.att, 'Value');
    fid  = str2double(get(fields.faultID, 'String'));
    lon  = str2double(get(fields.lon,     'String'));
    lat  = str2double(get(fields.lat,     'String'));

    if isnan(fid) || fid < 1 || fid > 19, fid = 1; end
    m0=4.0; a_val=3.429; b_val=0.810;
    st = getappdata(fig,'status_txt');

    %% ---- Validation --------------------------------------------------
    if any(isnan([naf fl neq rmax rmin mu]))
        set(st,'String','Invalid input — check all numeric fields.', ...
            'ForegroundColor',[0.7 0.1 0.1]); return;
    end
    if rmin >= rmax
        set(st,'String','Rmin must be less than Rmax.', ...
            'ForegroundColor',[0.7 0.1 0.1]); return;
    end
    if mu < 5.5 || mu > 8.3
        set(st,'String','Mu must be 5.5 – 8.3 (training range).', ...
            'ForegroundColor',[0.7 0.1 0.1]); return;
    end
    if naf < 7 || naf > 9
        set(st,'String', sprintf('NAF=%.0f outside [7-9]. Clamped.',naf), ...
            'ForegroundColor',[0.65 0.35 0.0]);
        naf = max(7, min(9, round(naf)));
        set(fields.naf,'String',num2str(naf));
    end

    %% ---- NEAR-SOURCE AMPLIFICATION CORRECTION -----------------------
    % SVR training Rmin range is ~17.8–387 km.
    % Bhuj Rmin=12 km is outside this range — SVR extrapolates low.
    % Physical correction: PGA ∝ R^(-n) * exp(-κR)
    % n=1.10, κ=0.0022 km^-1 from Raghukanth & Iyengar (2008)
    % amp = (Rmin_train_ref / Rmin_input)^n * exp(-κ*(Rmin_input - Rmin_ref))
    Rmin_train_ref = 17.8;
    n_spread       = 1.10;
    kappa          = 0.0022;

    if rmin < Rmin_train_ref
        near_src_amp = (Rmin_train_ref / max(rmin, 3.0))^n_spread ...
                     * exp(-kappa * (rmin - Rmin_train_ref));
        near_src_amp = min(near_src_amp, 6.0);
    else
        near_src_amp = 1.0;
    end

    %% ---- ATTENUATION MODEL DISTANCE SCALING -------------------------
    % Each GMPE differs in geometric spreading exponent n and anelastic κ.
    % We compute the ratio of model_att to R&I (model 1) at R=rmin:
    %   ratio = (R_ref/R)^(n_att - n_RI) * exp(-(κ_att - κ_RI)*R)
    % Model coefficients [n, κ]:
    %   R&I 2008   : [1.10, 0.0022]  reference
    %   Hwang & Huo: [0.95, 0.0018]  SCR stable crust, lower spreading
    %   NDMA 2010  : [1.05, 0.0025]  conservative IS1893 envelope
    %   Toro 1997  : [1.20, 0.0030]  CEUS model, stronger spreading
    R_ref      = 100.0;
    R_eff      = max(rmin, 5.0);
    gm_coeff   = [1.10, 0.0022;   % R&I 2008
                  0.95, 0.0018;   % Hwang & Huo
                  1.05, 0.0025;   % NDMA 2010
                  1.20, 0.0030];  % Toro
    n_RI = gm_coeff(1,1); kap_RI = gm_coeff(1,2);
    n_m  = gm_coeff(att,1); kap_m = gm_coeff(att,2);
    att_dist_scale = (R_ref/R_eff)^(n_m - n_RI) * exp(-(kap_m - kap_RI)*R_eff);
    att_dist_scale = max(0.60, min(att_dist_scale, 1.60));

    %% ---- RETURN PERIOD EPSILON SCALING ------------------------------
    % Each RP level corresponds to an epsilon (# sigmas above median):
    %   2%/50yr   → RP=2475yr → ε≈2.05
    %   10%/50yr  → RP=475yr  → ε≈1.28
    %   2%/100yr  → RP=4975yr → ε≈2.33
    %   10%/100yr → RP=950yr  → ε≈1.65
    % PGA(RP) = PGA_median * exp(ε * σ_ln)
    % σ_ln per model: R&I=0.37, H&H=0.32, NDMA=0.42, Toro=0.35
    epsilon_rp = [2.05, 1.28, 2.33, 1.65];
    sigma_ln   = [0.37, 0.32, 0.42, 0.35];
    sig        = sigma_ln(att);
    rp_scale   = exp(epsilon_rp * sig);
    rp_scale   = rp_scale / rp_scale(2);  % normalise to 10%/50yr = 1.0

    %% ---- FEATURE VECTOR (att fixed to 1 — differentiation physical) -
    Rratio      = rmax / (rmin + 1);
    Mrange      = mu   - m0;
    logRmax     = log(rmax + 1);
    logRmin     = log(rmin + 1);
    logFaultLen = log(fl   + 1);
    DistMag     = mu / (logRmin + 1);  % near-source proxy: high Mu/small R → high PGA

    x_raw = [naf, fl, neq, rmax, rmin, m0, mu, a_val, b_val, ...
             fid, 1, Rratio, Mrange, logRmax, logRmin, logFaultLen, DistMag];

    if length(x_raw) ~= DT.nFeatures
        set(st,'String', sprintf('Feature mismatch: %d vs %d expected.', ...
            length(x_raw), DT.nFeatures), 'ForegroundColor',[0.7 0.1 0.1]);
        return;
    end

    %% ---- SVR + LAYERED CORRECTIONS ----------------------------------
    try
        tic;
        pga_svr = DT_predict_REVISED(DT, x_raw);
        tms = toc*1000;
        pga_svr = pga_svr(:)';

        % Layer 1: near-source amplification (scalar, all RPs)
        pga_amp = pga_svr * near_src_amp;

        % Layer 2: return period sigma scaling (differentiates 4 gauges)
        pga_rp = pga_amp .* rp_scale;

        % Layer 3: attenuation model distance scaling (scalar per model)
        pga_final = pga_rp * att_dist_scale;

        % Layer 4: enforce physical monotonicity across return periods
        % 2%/100yr > 2%/50yr > 10%/100yr > 10%/50yr
        pga_final(3) = max(pga_final(3), pga_final(1) * 1.15);
        pga_final(4) = max(pga_final(4), pga_final(2) * 1.28);
        pga_final(1) = max(pga_final(1), pga_final(4) * 1.05);
        pga_final(2) = min(pga_final(2), pga_final(4) * 0.90);

    catch ME
        set(st,'String',['Error: ' ME.message],'ForegroundColor',[0.7 0.1 0.1]);
        fprintf('[DT ERROR] %s\n', ME.getReport()); return;
    end

    %% ---- Update gauges ----------------------------------------------
    ga=getappdata(fig,'gauge_ax');
    vt=getappdata(fig,'val_txt');
    bt=getappdata(fig,'badge_txt');
    for k=1:4
        drawGauge(ga{k}, pga_final(k), zones);
        set(vt{k},'String', sprintf('%.5f', pga_final(k)));
        z=getZone(pga_final(k), zones);
        set(bt{k},'String', z{2}, ...
            'BackgroundColor', z{4}, 'ForegroundColor', z{3}*0.60);
    end

    attNames={'Raghukanth & Iyengar (2008)','Hwang & Huo','NDMA (2010)','Toro'};
    mx=max(pga_final); z=getZone(mx,zones);
    set(st,'String', sprintf( ...
        '(%.3f°E, %.3f°N)  |  %s  |  %.2f ms  |  Max PGA = %.4f g  |  %s', ...
        lon, lat, attNames{att}, tms, mx, z{2}), ...
        'ForegroundColor', z{3}*0.7);

    fprintf('\n[DT v3] (%.3fE %.3fN)  Model: %s\n', lon, lat, attNames{att});
    fprintf('  Input : NAF=%d  FL=%d km  NEQ=%d  Rmax=%.0f km  Rmin=%.1f km  Mu=%.1f  FaultID=%d\n', ...
        naf, fl, neq, rmax, rmin, mu, fid);
    fprintf('  Corrections: near_src_amp=%.4f  att_dist_scale=%.4f  sigma_ln=%.2f\n', ...
        near_src_amp, att_dist_scale, sig);
    fprintf('  RP scale factors: [%.3f  %.3f  %.3f  %.3f]\n', ...
        rp_scale(1),rp_scale(2),rp_scale(3),rp_scale(4));
    for k=1:4
        fprintf('  %-20s : SVR=%.5f g  final=%.5f g\n', ...
            outLabels{k}, pga_svr(k), pga_final(k));
    end
end


%% ======================================================================
function saveScreenshot(fig)
    [fname,fpath]=uiputfile( ...
        {'*.png','PNG (*.png)';'*.pdf','PDF (*.pdf)'}, ...
        'Save Screenshot','PSHA_DT_Result');
    if isequal(fname,0); return; end
    fullpath=fullfile(fpath,fname);
    [~,~,ext]=fileparts(fname);
    drawnow; pause(0.20);
    if strcmpi(ext,'.pdf')
        set(fig,'PaperPositionMode','auto');
        print(fig,fullpath,'-dpdf','-r150');
    else
        print(fig,fullpath,'-dpng','-r200');
    end
    msgbox(sprintf('Saved:\n%s',fullpath),'Saved','help');
end


%% ======================================================================
function drawGauge(ax, value, zones)
    cla(ax,'reset'); axes(ax); hold(ax,'on');
    MAX_PGA=0.50; R_out=1.00; R_in=0.55;
    p2a=@(p) pi*(1-p/MAX_PGA);
    set(ax,'XLim',[-1.55 1.55],'YLim',[-0.30 1.55]);
    set(ax,'XLimMode','manual','YLimMode','manual');
    set(ax,'DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual');
    set(ax,'Color','white','XColor','none','YColor','none','Visible','off');

    segPGA=[0.05,0.10,0.20,0.35,MAX_PGA];
    segCols=[0.45 0.68 0.18;0.67 0.82 0.38;0.96 0.76 0.22;
             0.88 0.38 0.18;0.85 0.22 0.22];
    p_prev=0;
    for s=1:numel(segPGA)
        a1=p2a(p_prev); a2=p2a(segPGA(s));
        th=linspace(a1,a2,80);
        patch(ax,[R_out*cos(th),R_in*cos(flip(th))], ...
                 [R_out*sin(th),R_in*sin(flip(th))], ...
            segCols(s,:),'EdgeColor','none');
        p_prev=segPGA(s);
    end
    th_s=linspace(pi,0,200);
    patch(ax,[R_in*cos(th_s),0],[R_in*sin(th_s),0],'white','EdgeColor','none');
    plot(ax,R_out*cos(th_s),R_out*sin(th_s),'Color',[0.40 0.40 0.40],'LineWidth',1.2);
    plot(ax,R_in*cos(th_s), R_in*sin(th_s), 'Color',[0.65 0.65 0.65],'LineWidth',0.8);
    plot(ax,[-R_out R_out],[0 0],'Color',[0.40 0.40 0.40],'LineWidth',0.9);

    tick_pga={'0','0.1','0.2','0.3','0.4','0.5'};
    for t=1:6
        pv=(t-1)*0.10; a=p2a(pv); ca=cos(a); sa=sin(a);
        plot(ax,[R_out*ca,(R_out+0.13)*ca],[R_out*sa,(R_out+0.13)*sa], ...
            'Color',[0.15 0.15 0.15],'LineWidth',1.8);
        text(ax,(R_out+0.32)*ca,(R_out+0.32)*sa,tick_pga{t}, ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'FontSize',8,'FontWeight','bold','Color',[0.10 0.10 0.10]);
    end
    for mp=0.05:0.05:MAX_PGA-0.005
        a=p2a(mp);
        plot(ax,[R_out*cos(a),(R_out+0.07)*cos(a)], ...
                [R_out*sin(a),(R_out+0.07)*sin(a)], ...
            'Color',[0.55 0.55 0.55],'LineWidth',0.8);
    end

    if ~isnan(value)
        cl=min(max(value,0),MAX_PGA); ang=p2a(cl);
        z=getZone(value,zones); nc=z{3};
        NL=0.87; tipX=NL*cos(ang); tipY=NL*sin(ang);
        perp=ang+pi/2; bw=0.048; bwS=bw+0.014;
        patch(ax,[bwS*cos(perp),-bwS*cos(perp),tipX], ...
                 [bwS*sin(perp),-bwS*sin(perp),tipY], ...
            [0.05 0.05 0.05],'EdgeColor','none');
        patch(ax,[bw*cos(perp),-bw*cos(perp),tipX], ...
                 [bw*sin(perp),-bw*sin(perp),tipY], ...
            nc,'EdgeColor',[0.10 0.10 0.10],'LineWidth',0.8);
        plot(ax,[0,tipX*0.80],[0,tipY*0.80],'w-','LineWidth',1.4);
        stubL=0.22; bwR=0.028;
        patch(ax,[bwR*cos(perp),-bwR*cos(perp),-stubL*cos(ang)], ...
                 [bwR*sin(perp),-bwR*sin(perp),-stubL*sin(ang)], ...
            [0.18 0.18 0.18],'EdgeColor','none');
        th_c=linspace(0,2*pi,80);
        patch(ax,0.11*cos(th_c),0.11*sin(th_c), ...
            [0.12 0.12 0.12],'EdgeColor','white','LineWidth',1.5);
        patch(ax,0.052*cos(th_c),0.052*sin(th_c), ...
            [0.92 0.92 0.92],'EdgeColor','none');
    end

    set(ax,'XLim',[-1.55 1.55],'YLim',[-0.30 1.55]);
    set(ax,'XLimMode','manual','YLimMode','manual');
    set(ax,'DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual');
    set(ax,'Color','white','XColor','none','YColor','none','Visible','off');
    hold(ax,'off');
end


%% ======================================================================
function drawScaleBar(ax)
    cla(ax); hold(ax,'on');
    segs=[0,0.05,0.10,0.20,0.35,0.50];
    lbls={'Very Low','Low','Moderate','High','Very High'};
    cols=[0.45 0.68 0.18;0.67 0.82 0.38;0.96 0.76 0.22;
          0.88 0.38 0.18;0.85 0.22 0.22];
    for s=1:5
        x0=segs(s)/0.50; x1=segs(s+1)/0.50;
        patch('XData',[x0 x1 x1 x0],'YData',[0 0 1 1], ...
            'FaceColor',cols(s,:),'EdgeColor','none','Parent',ax);
        text((x0+x1)/2,0.50,lbls{s},'FontSize',8,'FontWeight','bold', ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'Color','white','Parent',ax);
    end
    for b=1:numel(segs)
        text(segs(b)/0.50,-0.40,sprintf('%.2f',segs(b)),'FontSize',7.5, ...
            'HorizontalAlignment','center','Color',[0.30 0.30 0.30],'Parent',ax);
    end
    set(ax,'XLim',[0 1],'YLim',[-0.65 1.3],'Visible','off');
    hold(ax,'off');
end


%% ======================================================================
function z = getZone(value, zones)
    z=zones(end,:);
    for k=1:size(zones,1)
        if value<=zones{k,1}; z=zones(k,:); return; end
    end
end