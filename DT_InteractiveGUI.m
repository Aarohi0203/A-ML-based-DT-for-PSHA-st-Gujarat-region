function DT_InteractiveGUI()
%% ========================================================================
%  DIGITAL TWIN — PGA PREDICTOR (COMPLETE FINAL VERSION - NEEDLE FIXED)
%  Attenuation models:
%   1 = Raghukanth & Iyengar (2008)
%   2 = Hwang & Huo
%   3 = NDMA (2010)
%   5 = Toro  (coded as 5 in training data)
%% ========================================================================
if ~isfile('DigitalTwin_Base_REVISED.mat')
    errordlg('DigitalTwin_Base_REVISED.mat not found.','Missing file'); return;
end
S = load('DigitalTwin_Base_REVISED.mat'); DT = S.DT;

outLabels = {'PGA 2%/50yr','PGA 10%/50yr','PGA 2%/100yr','PGA 10%/100yr'};
zones = {
    0.05,'Very low',  [0.23 0.43 0.07],[0.85 0.95 0.75];
    0.10,'Low',       [0.30 0.52 0.10],[0.75 0.90 0.60];
    0.20,'Moderate',  [0.73 0.46 0.09],[0.98 0.84 0.55];
    0.35,'High',      [0.75 0.20 0.10],[0.97 0.70 0.60];
    999, 'Very high', [0.60 0.10 0.10],[0.97 0.76 0.76];
};

DARK = [0.10 0.24 0.42];
BG   = [0.95 0.95 0.95];
FW   = 1100; FH = 820;

fig = figure('Name','PSHA Digital Twin','NumberTitle','off', ...
    'Position',[30 30 FW FH],'Color',BG, ...
    'Resize','off','MenuBar','none','ToolBar','none');

%% ---- Title -----------------------------------------------------------
uicontrol('Style','text','Units','pixels', ...
    'Position',[0 FH-52 FW 52], ...
    'String','PSHA Digital Twin  —  Seismic Hazard PGA Predictor', ...
    'FontSize',13,'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'BackgroundColor',DARK,'ForegroundColor','white');

%% ---- Left panel ------------------------------------------------------
LP = uipanel('Units','pixels','Position',[6 6 300 FH-60], ...
    'BackgroundColor',BG,'BorderType','none');

    function makeSec(txt,y)
        uicontrol('Parent',LP,'Style','text','Units','pixels', ...
            'Position',[0 y 300 22],'String',txt, ...
            'FontSize',8.5,'FontWeight','bold', ...
            'HorizontalAlignment','left', ...
            'BackgroundColor',DARK,'ForegroundColor','white');
    end

    function h = makeField(lbl,y,val,dis)
        if nargin<4, dis=false; end
        fc = [0.1 0.1 0.1]; if dis, fc=[0.6 0.6 0.6]; end
        bc = [1 1 1];        if dis, bc=[0.88 0.88 0.88]; end
        en = 'on';           if dis, en='off'; end
        uicontrol('Parent',LP,'Style','text','Units','pixels', ...
            'Position',[4 y+3 116 18],'String',[lbl ':'], ...
            'FontSize',9,'HorizontalAlignment','left', ...
            'BackgroundColor',BG,'ForegroundColor',fc);
        h = uicontrol('Parent',LP,'Style','edit','Units','pixels', ...
            'Position',[124 y 170 26],'String',num2str(val), ...
            'FontSize',9.5,'HorizontalAlignment','right', ...
            'Enable',en,'BackgroundColor',bc);
    end

LPH = FH - 60;

makeSec('Site location',         LPH-42);
fields.lon = makeField('Longitude (E)', LPH-72,  72.98);
fields.lat = makeField('Latitude (N)',  LPH-104, 21.71);

makeSec('Fault parameters',      LPH-128);
fields.nf  = makeField('Active faults',     LPH-158,  8);
fields.fl  = makeField('Fault length (km)', LPH-190, 85);

makeSec('Seismicity',            LPH-214);
fields.neq  = makeField('NumEQ',       LPH-244,  45);
fields.rmax = makeField('Rmax (km)',   LPH-276, 120);
fields.rmin = makeField('Rmin (km)',   LPH-308,  40);
fields.mu   = makeField('Mu (upper M)',LPH-340, 6.5);

makeSec('Model parameters',      LPH-364);
makeField('a-value', LPH-394, 3.429, true);
makeField('b-value', LPH-426, 0.810, true);

% Attenuation model label + dropdown
uicontrol('Parent',LP,'Style','text','Units','pixels', ...
    'Position',[4 LPH-452 120 18], ...
    'String','Att. model:', ...
    'FontSize',9,'HorizontalAlignment','left','BackgroundColor',BG);
fields.att = uicontrol('Parent',LP,'Style','popupmenu','Units','pixels', ...
    'Position',[4 LPH-478 290 26], ...
    'String',{'Raghukanth & Iyengar (2008)', ...
               'Hwang & Huo', ...
               'NDMA (2010)', ...
               'Toro'}, ...
    'FontSize',8.5,'Value',1);

% City presets
makeSec('Quick city presets', LPH-504);
cities = {'Ahmedabad',72.587,23.033; 'Surat',72.831,21.170; ...
          'Bharuch',72.980,21.706;   'Vadodara',73.200,22.307; ...
          'Rajkot',70.802,22.303;    'Bhuj',69.669,23.253; ...
          'Gandhinagar',72.636,23.216;'Anand',72.928,22.556};
BW2=70; BH2=26;
for c = 1:size(cities,1)
    col = mod(c-1,4); row = floor((c-1)/4);
    btn = uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
        'Position',[2+col*(BW2+3), LPH-536-row*(BH2+5), BW2, BH2], ...
        'String',cities{c,1},'FontSize',7.5);
    set(btn,'UserData',struct('lon',cities{c,2},'lat',cities{c,3}), ...
        'Callback',@(s,~) cityCallback(s,fields));
end

% Save Screenshot button
uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 140 300 34], ...
    'String','Save Screenshot', ...
    'FontSize',10,'FontWeight','bold', ...
    'BackgroundColor',[0.20 0.45 0.20],'ForegroundColor','white', ...
    'Callback',@(~,~) saveScreenshot(fig));

% Reset button
uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 100 300 34],'String','Reset','FontSize',10, ...
    'Callback',@(~,~) resetFields(fields));

% Predict button
uicontrol('Parent',LP,'Style','pushbutton','Units','pixels', ...
    'Position',[0 6 300 88],'String','PREDICT PGA', ...
    'FontSize',15,'FontWeight','bold', ...
    'BackgroundColor',DARK,'ForegroundColor','white', ...
    'Callback',@(~,~) cbPredict(fig,DT,fields,outLabels,zones));

%% ---- Status text & scale bar ----------------------------------------
status_txt = uicontrol('Style','text','Units','pixels', ...
    'Position',[314 58 780 22], ...
    'String','Enter parameters and click PREDICT PGA', ...
    'FontSize',8.5,'HorizontalAlignment','center', ...
    'BackgroundColor',BG,'ForegroundColor',[0.45 0.45 0.45]);

scale_ax = axes('Units','pixels','Position',[314 6 780 48],'Color',BG);
drawScaleBar(scale_ax);

%% ---- 4 Gauge panels -------------------------------------------------
RX=314; RY=84; RW=FW-RX-6; RH=FH-52-RY-4;
GW = floor((RW-8)/2);
GH = floor((RH-8)/2);

gpx = @(c) RX + (c-1)*(GW+8);
gpy = @(r) RY + (r-1)*(GH+8);

panel_pos = {[gpx(1),gpy(2),GW,GH],[gpx(2),gpy(2),GW,GH], ...
             [gpx(1),gpy(1),GW,GH],[gpx(2),gpy(1),GW,GH]};

gauge_ax  = cell(4,1);
val_txt   = cell(4,1);
badge_txt = cell(4,1);

TITLE_H = 34;
BOT_H   = 78;

for k = 1:4
    pp = panel_pos{k};
    px=pp(1); py=pp(2); pw=pp(3); ph=pp(4);

    gp = uipanel('Units','pixels','Position',[px py pw ph], ...
        'BackgroundColor','white','BorderType','line', ...
        'HighlightColor',[0.75 0.75 0.75]);

    % Title strip
    uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[0 ph-TITLE_H pw TITLE_H], ...
        'String',outLabels{k},'FontSize',11,'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'BackgroundColor',DARK,'ForegroundColor','white');

    % Gauge axes — key fix: remove DataAspectRatio here, set it inside drawGauge
    gauge_ax{k} = axes('Parent',gp,'Units','pixels', ...
        'Position',[4 BOT_H pw-8 ph-TITLE_H-BOT_H], ...
        'Color','white', ...
        'XColor','none','YColor','none');
    drawGauge(gauge_ax{k}, NaN, zones);

    % Value display
    val_txt{k} = uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[0 36 pw 34], ...
        'String','—','FontSize',21,'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'BackgroundColor','white','ForegroundColor',[0.12 0.12 0.12]);

    uicontrol('Parent',gp,'Style','text','Units','pixels', ...
        'Position',[pw-30 40 24 20], ...
        'String','g','FontSize',9,'BackgroundColor','white', ...
        'ForegroundColor',[0.55 0.55 0.55]);

    % Hazard badge
    badge_txt{k} = uicontrol('Parent',gp,'Style','text','Units','pixels', ...
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
fprintf('[DT GUI] Ready.\n');
end


%% ======================================================================
function cityCallback(btn,fields)
    ud = get(btn,'UserData');
    set(fields.lon,'String',num2str(ud.lon,'%.4f'));
    set(fields.lat,'String',num2str(ud.lat,'%.4f'));
end


%% ======================================================================
function resetFields(fields)
    set(fields.lon,'String','72.98');
    set(fields.lat,'String','21.71');
    set(fields.nf, 'String','8');
    set(fields.fl, 'String','85');
    set(fields.neq,'String','45');
    set(fields.rmax,'String','120');
    set(fields.rmin,'String','40');
    set(fields.mu, 'String','6.5');
    set(fields.att,'Value',1);
end


%% ======================================================================
function cbPredict(fig,DT,fields,outLabels,zones)
    lon =str2double(get(fields.lon, 'String'));
    lat =str2double(get(fields.lat, 'String'));
    nf  =str2double(get(fields.nf,  'String'));
    fl  =str2double(get(fields.fl,  'String'));
    neq =str2double(get(fields.neq, 'String'));
    rmax=str2double(get(fields.rmax,'String'));
    rmin=str2double(get(fields.rmin,'String'));
    mu  =str2double(get(fields.mu,  'String'));

    % Dropdown pos 1-4 maps to ANN training codes 1,2,3,5
    attMap = [1, 2, 3, 5];
    att    = attMap(get(fields.att,'Value'));

    attNames = {'Raghukanth & Iyengar (2008)', ...
                'Hwang & Huo', ...
                'NDMA (2010)', ...
                'Toro'};
    attName = attNames{get(fields.att,'Value')};

    st = getappdata(fig,'status_txt');

    if any(isnan([lon lat nf fl neq rmax rmin mu]))
        set(st,'String','Invalid input — check all fields.', ...
            'ForegroundColor',[0.7 0.1 0.1]); return;
    end

    % --- Base inputs ---
    Mmin    = 4.0;                      % fixed minimum magnitude
    a_val   = 3.429;                    % fixed a-value
    b_val   = 0.810;                    % fixed b-value
    faultID = att;                      % NameOfFault (same code as att model)

    % --- 5 Derived / engineered features ---
    Rratio     = rmin / rmax;           % feature 12
    Mrange     = mu - Mmin;            % feature 13
    logRmax    = log(rmax);            % feature 14
    logRmin    = log(rmin);            % feature 15
    logFaultLen= log(fl);              % feature 16
    DistMag    = rmax / mu;            % feature 17

    % --- Full 17-feature vector (must match DT.featureNames order) ---
    x_raw = [nf, fl, neq, rmax, rmin, Mmin, mu, a_val, b_val, ...
             faultID, att, Rratio, Mrange, logRmax, logRmin, ...
             logFaultLen, DistMag];
    try
        tic;
        pga = DT_predict_REVISED(DT,x_raw);
        tms = toc*1000;
        pga = pga(:)';
    catch ME
        set(st,'String',['Error: ' ME.message], ...
            'ForegroundColor',[0.7 0.1 0.1]);
        fprintf('[DT ERROR] %s\n', ME.message);
        fprintf('[DT ERROR] %s\n', ME.getReport());
        return;
    end

    ga = getappdata(fig,'gauge_ax');
    vt = getappdata(fig,'val_txt');
    bt = getappdata(fig,'badge_txt');

    for k = 1:4
        drawGauge(ga{k}, pga(k), zones);
        set(vt{k},'String',sprintf('%.5f',pga(k)));
        z = getZone(pga(k),zones);
        set(bt{k},'String',z{2}, ...
            'BackgroundColor',z{4}, ...
            'ForegroundColor',z{3}*0.60);
    end

    mx = max(pga);
    z  = getZone(mx,zones);
    set(st,'String', ...
        sprintf('(%.3fE, %.3fN)  |  %s  |  %.2f ms  |  Max PGA = %.4f g  |  %s', ...
        lon, lat, attName, tms, mx, z{2}), ...
        'ForegroundColor',z{3}*0.7);

    fprintf('[DT] Att: %s\n', attName);
    for k=1:4
        fprintf('     %s = %.5f g\n', outLabels{k}, pga(k));
    end
end


%% ======================================================================
function saveScreenshot(fig)
    [fname, fpath] = uiputfile( ...
        {'*.png','PNG Image (*.png)'; ...
         '*.pdf','PDF Document (*.pdf)'}, ...
        'Save Digital Twin Screenshot', ...
        'PSHA_DigitalTwin_Result');

    if isequal(fname,0); return; end

    fullpath = fullfile(fpath,fname);
    [~,~,ext] = fileparts(fname);

    % Ensure full render before capture
    drawnow; pause(0.20);

    % Use print() — captures the COMPLETE figure window including
    % all panels, gauges, uicontrols and the scale bar at the bottom
    switch lower(ext)
        case '.png'
            print(fig, fullpath, '-dpng', '-r200');
        case '.pdf'
            set(fig, 'PaperPositionMode','auto');
            print(fig, fullpath, '-dpdf', '-r150');
        otherwise
            print(fig, fullpath, '-dpng', '-r200');
    end

    msgbox(sprintf('Saved successfully:\n%s', fullpath), ...
        'Save Complete','help');
    fprintf('[DT] Saved: %s\n', fullpath);
end


%% ======================================================================
%  drawGauge — COMPLETELY REWRITTEN needle section
%  Root cause of missing needle: axis limits were set BEFORE needle patches,
%  then hold(off) reset them. Now limits are locked with axis manual FIRST.
%% ======================================================================
function drawGauge(ax, value, zones)

    %% --- Step 1: hard-reset the axes cleanly --------------------------
    cla(ax, 'reset');
    axes(ax);                          % make ax the current axes
    hold(ax, 'on');

    %% --- constants ----------------------------------------------------
    MAX_PGA = 0.50;
    R_out   = 1.00;
    R_in    = 0.55;
    p2a     = @(p) pi*(1 - p/MAX_PGA);   % PGA value → angle (pi..0)

    %% --- Step 2: SET AXIS LIMITS AND LOCK THEM FIRST ------------------
    %  This is the critical fix — limits must be set before any drawing
    %  so that subsequent patches/plots cannot auto-expand them.
    set(ax, 'XLim', [-1.55 1.55], 'YLim', [-0.30 1.55]);
    set(ax, 'XLimMode','manual', 'YLimMode','manual');
    set(ax, 'DataAspectRatio',[1 1 1], 'DataAspectRatioMode','manual');
    set(ax, 'PlotBoxAspectRatioMode','auto');
    set(ax, 'Color','white','XColor','none','YColor','none','Visible','off');

    %% --- Step 3: Coloured arc segments --------------------------------
    segPGA    = [0.05, 0.10, 0.20, 0.35, MAX_PGA];
    segColors = [0.45 0.68 0.18;
                 0.67 0.82 0.38;
                 0.96 0.76 0.22;
                 0.88 0.38 0.18;
                 0.85 0.22 0.22];
    p_prev = 0;
    for s = 1:numel(segPGA)
        a1 = p2a(p_prev);
        a2 = p2a(segPGA(s));
        th = linspace(a1, a2, 80);
        xv = [R_out*cos(th),  R_in*cos(flip(th))];
        yv = [R_out*sin(th),  R_in*sin(flip(th))];
        patch(ax, xv, yv, segColors(s,:), 'EdgeColor','none');
        p_prev = segPGA(s);
    end

    %% --- Step 4: White centre fill (semicircle) -----------------------
    th_semi = linspace(pi, 0, 200);
    xw = [R_in*cos(th_semi), 0];
    yw = [R_in*sin(th_semi), 0];
    patch(ax, xw, yw, 'white', 'EdgeColor','none');

    %% --- Step 5: Arc borders & baseline -------------------------------
    plot(ax, R_out*cos(th_semi), R_out*sin(th_semi), ...
        'Color',[0.40 0.40 0.40], 'LineWidth',1.2);
    plot(ax, R_in*cos(th_semi),  R_in*sin(th_semi), ...
        'Color',[0.65 0.65 0.65], 'LineWidth',0.8);
    plot(ax, [-R_out, R_out], [0, 0], ...
        'Color',[0.40 0.40 0.40], 'LineWidth',0.9);

    %% --- Step 6: Major tick marks and labels --------------------------
    tick_pga = [0, 0.10, 0.20, 0.30, 0.40, 0.50];
    tick_lbl = {'0','0.1','0.2','0.3','0.4','0.5'};
    for t = 1:numel(tick_pga)
        a  = p2a(tick_pga(t));
        ca = cos(a); sa = sin(a);
        plot(ax, [R_out*ca, (R_out+0.13)*ca], ...
                 [R_out*sa, (R_out+0.13)*sa], ...
            'Color',[0.15 0.15 0.15], 'LineWidth',1.8);
        text(ax, (R_out+0.32)*ca, (R_out+0.32)*sa, tick_lbl{t}, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',8, 'FontWeight','bold', ...
            'Color',[0.10 0.10 0.10]);
    end

    %% --- Step 7: Minor tick marks -------------------------------------
    for mp = 0.05:0.05:MAX_PGA-0.005
        a = p2a(mp);
        plot(ax, [R_out*cos(a), (R_out+0.07)*cos(a)], ...
                 [R_out*sin(a), (R_out+0.07)*sin(a)], ...
            'Color',[0.55 0.55 0.55], 'LineWidth',0.8);
    end

    %% --- Step 8: NEEDLE (drawn absolutely last) -----------------------
    if ~isnan(value)
        cl  = min(max(value, 0), MAX_PGA);
        ang = p2a(cl);                      % angle for this PGA value

        z   = getZone(value, zones);
        nc  = z{3};                         % zone colour [R G B]

        % Needle geometry
        NL   = 0.87;                        % needle length (fraction of R_out)
        tipX = NL * cos(ang);
        tipY = NL * sin(ang);

        perp = ang + pi/2;                  % perpendicular direction
        bw   = 0.048;                       % half-width at base

        % Left and right base corners
        Lx =  bw*cos(perp);  Ly =  bw*sin(perp);
        Rx = -bw*cos(perp);  Ry = -bw*sin(perp);

        % --- Dark shadow (slightly bigger, drawn first) ---
        bwS  = bw + 0.014;
        SLx  =  bwS*cos(perp); SLy =  bwS*sin(perp);
        SRx  = -bwS*cos(perp); SRy = -bwS*sin(perp);
        patch(ax, [SLx SRx tipX], [SLy SRy tipY], ...
            [0.05 0.05 0.05], 'EdgeColor','none');

        % --- Coloured needle body ---
        patch(ax, [Lx Rx tipX], [Ly Ry tipY], ...
            nc, 'EdgeColor',[0.10 0.10 0.10], 'LineWidth',0.8);

        % --- Bright centre spine line (always visible on any background) ---
        plot(ax, [0, tipX*0.80], [0, tipY*0.80], ...
            'w-', 'LineWidth', 1.4);

        % --- Rear counterweight stub ---
        stubL = 0.22;
        bwR   = 0.028;
        sX    = -stubL * cos(ang);
        sY    = -stubL * sin(ang);
        SbLx  =  bwR*cos(perp); SbLy =  bwR*sin(perp);
        SbRx  = -bwR*cos(perp); SbRy = -bwR*sin(perp);
        patch(ax, [SbLx SbRx sX], [SbLy SbRy sY], ...
            [0.18 0.18 0.18], 'EdgeColor','none');

        % --- Centre pivot hub (dark ring + bright inner dot) ---
        th_c = linspace(0, 2*pi, 80);
        patch(ax, 0.11*cos(th_c), 0.11*sin(th_c), ...
            [0.12 0.12 0.12], 'EdgeColor','white', 'LineWidth',1.5);
        patch(ax, 0.052*cos(th_c), 0.052*sin(th_c), ...
            [0.92 0.92 0.92], 'EdgeColor','none');
    end

    %% --- Step 9: Re-apply limits after all drawing (safety lock) -----
    set(ax, 'XLim', [-1.55 1.55], 'YLim', [-0.30 1.55]);
    set(ax, 'XLimMode','manual', 'YLimMode','manual');
    set(ax, 'DataAspectRatio',[1 1 1], 'DataAspectRatioMode','manual');
    set(ax, 'Color','white', 'XColor','none','YColor','none','Visible','off');
    hold(ax, 'off');
end


%% ======================================================================
function drawScaleBar(ax)
    cla(ax); hold(ax,'on');
    segs = [0, 0.05, 0.10, 0.20, 0.35, 0.50];
    lbls = {'Very low','Low','Moderate','High','Very high'};
    cols = [0.45 0.68 0.18; 0.67 0.82 0.38; 0.96 0.76 0.22;
            0.88 0.38 0.18; 0.85 0.22 0.22];
    for s = 1:5
        x0=segs(s)/0.50; x1=segs(s+1)/0.50;
        patch('XData',[x0 x1 x1 x0],'YData',[0 0 1 1], ...
            'FaceColor',cols(s,:),'EdgeColor','none','Parent',ax);
        text((x0+x1)/2, 0.50, lbls{s}, ...
            'FontSize',8,'FontWeight','bold', ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'Color','white','Parent',ax);
    end
    for b = 1:numel(segs)
        text(segs(b)/0.50, -0.40, sprintf('%.2f',segs(b)), ...
            'FontSize',7.5,'HorizontalAlignment','center', ...
            'Color',[0.30 0.30 0.30],'Parent',ax);
    end
    set(ax,'XLim',[0 1],'YLim',[-0.65 1.3],'Visible','off');
    hold(ax,'off');
end


%% ======================================================================
function z = getZone(value,zones)
    z = zones(end,:);
    for k = 1:size(zones,1)
        if value <= zones{k,1}; z=zones(k,:); return; end
    end
end
