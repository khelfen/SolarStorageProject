%% Projekt Solarspeicher mit Einbindung in VPP Cloud
clear variables
close all

%% 1 Lastprofile
%% 1.1 PV
% Quelle: Moodle - Weninger

load('A04_Daten.mat');

LProf.ppvs = ppvs;

clear Pl ppvs

%% 1.2 Hausverbrauch - Last
% Quelle: https://pvspeicher.htw-berlin.de/wp-content/uploads/2017/05/
% HTW-BERLIN-2015-Repr%C3%A4sentative-elektrische-Lastprofile-f%C3%BCr-Wohngeb%C3%A4ude
% -in-Deutschland-auf-1-sek%C3%BCndiger-Datenbasis.pdf
% bzw.
% https://fs-cloud.f1.htw-berlin.de/s/wZZQKdupnJd8wmH - aus der Datei
% PL1.csv - Lastgang Nr. 3 - 1-minütige Auflösung

T_l = readtable('P_H.csv');
A_l = table2array(T_l);
LProf.pl = A_l(:,2);

clear T_l A_l

%% 1.3 VPP
% Quelle: Mit freundlicher Unterstützung durch Markus Jaschinsky
% https://www.netzfrequenz.info/

T_VPP = readtable('P_VPP.csv');
A_VPP = table2array(T_VPP);
LProf.pvpp = A_VPP(:,3);

clear T_VPP A_VPP

%% 2 Parameters
%% 2.1 PV - System PV + Bat
% Daten der sonnenBatterie aus Stromspeicherinspektion 2019 
% und https://sonnenbatterie.de/sites/default/files/datenblatt_sonnenbatterie_eco_8.0_dach_1.pdf
% Edit: Simulation nur Speichern mit einer Leistung von 3,3 kW

PV.P_AC2BAT_in = 3.3;   % Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
PV.P_BAT2AC_out = 3.3;  % Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
PV.eta_ac2bat = 0.944;  % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb 
PV.eta_bat2ac = 0.945;  % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
PV.eta_bat = 0.938;     % Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 
PV.dt = 1/60;           % Simulationszeitschrittweite in h

%% 2.2 H - Household
% Eigenständige Ermittlung

H.PStartMax = 7355;     % Maximale Leistungsabgabe des Referenzlastgang in W
H.EStart = 2348;        % Energieverbrauch des Referenzlastgang in kWh

%% 2.3 VPP - Virtual Power Plant
% Eigene Annahmen:

VPP.P_PQ = 1;                                   % Präqualifizierte Leistung des VPP in MW
VPP.P_pq = VPP.P_PQ * 1000;                     % Präqualifizierte Leistung des VPP in kW
VPP.n_Bat = 600;                                % Anzahl der Batterien des VPP
VPP.P_max_pos = VPP.n_Bat * PV.P_BAT2AC_out;    % Theoretische maximale positive Leistung des VPP in kW
VPP.P_max_neg = VPP.n_Bat * PV.P_AC2BAT_in;     % Theoretische maximale negative Leistung des VPP in kW
VPP.f_P_VPP_pos = VPP.P_pq / VPP.P_max_pos;     % Leistungsfaktor Positiv
VPP.f_P_VPP_neg = VPP.P_pq / VPP.P_max_neg;     % Leistungsfaktor Negativ

clear VPP.P_PQ

%% 3 Auswertung
%% 3.1 Feste Parameter

% Eigene Annahmen:

ERG.Load = [10000 8000];                            % Matrix Hausverbrauch in kWh
ERG.BatCap = [8 16];                                  % Matrix Batteriekapazität in kWh
ERG.PVSize = [5.5 10];                              % Matrix PV-Generatorleistung in kWp 
ERG.C_var = (0.25:0.01:0.32);                           % Matrix Strombezugskosten Arbeitspreis in €/kWh
ERG.C_fix = (5:1:12);                                   % Matrix Strombezugskosten Grundpreis in €/Monat
ERG.C_Flat = [0.23 0.259];                              % Überziehungsstromkosten sonnenFlat in €/kWh
ERG.sonnenBonus = 0.0025;                               % sonnenBonus in €/kWh

% Quelle: https://www.bundesnetzagentur.de/DE/Sachgebiete/ElektrizitaetundGas/Unternehmen_Institutionen/
% ErneuerbareEnergien/ZahlenDatenInformationen/EEG_Registerdaten/ArchivDatenMeldgn/ArchivDatenMeldgn_node.html

ERG.C_EEG = [9.87 9.97...                               % EEG Vergütungssätze in €/kWh
    10.08 10.18 10.33 10.48 10.64 10.79 10.95...
    11.11 11.23 11.35 11.47 11.59 11.71 11.83 11.95 12.08 12.20...
    12.24 12.27 12.30 12.31 12.34 12.37 12.40 12.47 12.50...
    12.53 12.56 12.59 12.62 12.65 12.69 12.75] * 0.01;

% Quelle: https://sonnen.de/haeufig-gestellte-fragen/

ERG.C_AW = ERG.C_EEG + ERG.sonnenBonus;                 % EEG Vergütung + Bonus aus Direktvermarktung in €/kWh

% Zufällige Erstellung des Einsatzplans des virtuellen Kraftwerks

num_active = 1;                                       % Annahme: FCR-Zuschlag an 80% der Tage
[LProf.vppactive, LProf.socactive] = active(num_active);% Ermittlung der I/O-Minutenvektoren

rng default;                                            % Random Seed standardisieren

socactive = LProf.socactive;                            % SOC-Grenzen aktiv
vppactive = LProf.vppactive;                            % Leistungserbringung des virtuellen Kraftwerks aktiv
pvpp_active = LProf.pvpp ~= 0;                          % Frequenzabweichung im Zeitschritt außerhalb des Totbandes

% Approximation, ob eigene Batterie aktiv ist pro Zeitschritt

Pdif = rand(length(pvpp_active),1);                        % Zufallsminutenvektor
b = abs(LProf.pvpp) * VPP.f_P_VPP_pos;                  % Prozentuale Anzahl der aktiven Batterien des virtuellen Kraftwerks
bat_active = Pdif <= b;                                    % Wahrscheinlichkeit das eigene Batterieaktiv ist

VAll = [vppactive, pvpp_active, bat_active];            % Einzelne I/O-Vektoren in Matirx speichern

% Bestimmung des Verhaltens der Batterie
% VPP- oder Eigenverbrauchsverhalten

tstart = 1;                                             % Startwert Zeit in min
tend = length(vppactive);                               % Endwert Zeit in min

BAT.lower_SOC = zeros(length(vppactive),1);             % Vektor der unteren SOC-Grenze
BAT.upper_SOC = zeros(length(vppactive),1);             % Vektor der oberen SOC-Grenze
BAT.vppactive = zeros(length(vppactive),1);             % Vektor der FCR/Eigenverbrauchsunterscheidung

for t = tstart:tend
    if socactive(t) == 0                                % Eigenverbrauchsoptimierung, keine SOC-Grenzen
                                                        % FCR off
        BAT.lower_SOC(t) = 0;
        BAT.upper_SOC(t) = 1;

    else                                                % SOC-Grenzen aktiv
        BAT.lower_SOC(t) = 0.2;
        BAT.upper_SOC(t) = 0.8;

        switch polyval(VAll(t,:), 2)                    % FCR-Erbringung nur im Fall [1 1 1] aktiv
            case 7                                      % Lösung polyval == 7 entspricht [1 1 1]
                                                        % FCR on
                BAT.vppactive(t) = 1;
                
            otherwise
                continue                                % FCR off
                
        end
    end
end

clear a b bat_active num_active pvpp_active socactive t tend tstart VAll vppactive

%% 3.2 Simulation
%% 3.2.1 Simulation ohne VPP

ERG.E_G_Consumption = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));      % Ergebnismatrix Eigenverbrauchsoptimierung Netzbezug in kWh
ERG.E_PV_FeedIn = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));          % Ergebnismatrix Eigenverbrauchsoptimierung PV-Netzeinspeisung in kWh
ERG.VZ_EV = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));                % Ergebnismatrix Eigenverbrauchsoptimierung Vollzyklen in 1/a
ERG.E_G_ConsumptionVPP = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));   % Ergebnismatrix FCR Netzbezug in kWh
ERG.E_PV_FeedInVPP = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));       % Ergebnismatrix FCR PV-Netzeinspeisung in kWh
ERG.E_BAT_FeedIn = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));         % Ergebnismatrix FCR BAT-Netzeinspeisung in kWh
ERG.E_BAT_Consumption = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));    % Ergebnismatrix FCR BAT-Netzbezug in kWh
ERG.VZ_FCR = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));               % Ergebnismatrix FCR Vollzyklen in 1/a
ERG.Tarif_FCR = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));            % Berechnung des passenden Cloud-Tarifs in kWh
ERG.Tarif_FCR = ERG.Tarif_FCR + 4250;                                                       % Standard == sonnenFlat 4250
ERG.E_Bat_FCR_neg = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));        % Ergebnismatrix der negativen Regelenergie
ERG.E_Bat_FCR_pos = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));        % Ergebnismatrix der positiven Regelenergie
a = size(LProf.socactive);
SOC = zeros(a(1), length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));
SOCVPP = zeros(a(1), length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));

idk = 1;                                                    % Laufvariable fuer den Hausverbrauch

for H_Load = ERG.Load
    idj = 1;                                                % Laufvariable fuer die Batteriekapazitaet
    PMax = H.PStartMax * H_Load / H.EStart;                 % Neue Lastspitze Hausverbrauch in W
    Pl = LProf.pl * PMax;                                   % Lastgang des Hausverbrauchs in W

    for E_BAT = ERG.BatCap 
        idi = 1;                                            % Laufvariable fuer die PV-Generatorleistung
        PV.E_BAT = E_BAT;                                   % Batteriekapazitaet anpassen in kWh

        for P_PV = ERG.PVSize
            PV.P_PV = P_PV;                                 % PV-Generatorleistung anpassen in kWp
            Ppvs = LProf.ppvs * PV.P_PV * 1000;             % Lastgang der Leistungsabgabe des PV-Systems in W

            Pd = Ppvs - Pl;                                 % Differenzleistung in W

            [Pbs, EV] = bssim(PV, Pd);                      % Simulation der Eigenverbrauchsoptimierten Batteriesystemleistung in W
            
            SOC(:, idi, idj, idk) = EV.soc;

            Pg = Ppvs - Pl - Pbs;                           % Netzleistung in W

            % Energiesummen berechnen:
            
            Eg2ac = sum(abs((min(0, Pg))));     % Netzbezug in kWh
            
            Eac2g = sum(max(0, Pg));            % Netzeinspeisung in kWh

            % Ergebnisse in Matrix speichern:
            
            ERG.E_G_Consumption(idi, idj, idk) = Eg2ac;     % Netzbezug in Wmin
            ERG.E_PV_FeedIn(idi, idj, idk) = Eac2g;         % Netzeinspeisung in Wmin
            ERG.VZ_EV(idi, idj, idk) = EV.VZ;               % Vollzyklen in 1/a
            
%% 3.2.2 Simulation mit VPP

            [PbsVPP, PbsNoVPP, FCR] = bssimVPP(PV, LProf, BAT, Pd);     % Simulation der FCR-optimierten Batteriesystemleistung in W
            
            PgVPP = Ppvs - Pl - PbsVPP;                                 % Netzleistung bestimmen, mit VPP in W
            
            PgNoVPP = Ppvs - Pl - PbsNoVPP;                             % Netzleistung bestimmen, Theo. ohne VPP in W
            
            Pdif = PbsVPP - PbsNoVPP;

            % Energiesummen berechnen:
            
            Eg2acVPP = sum(abs((min(0, PgVPP))));                       % Netzbezug mit VPP Gesamt in Wmin
            
            Eg2acNoVPP = sum(abs((min(0, PgNoVPP))));                   % Netzbezug ohne VPP Gesamt in Wmin
            
            Eg2acBat = Eg2acVPP - Eg2acNoVPP;                           % Netzbezug durch die FCR Erbringung der Batterie in Wmin
            
            Eg2acl = Eg2acVPP - Eg2acBat;                               % Netzbezug durch den Hausverbrauch in Wmin
            
            Eac2gVPP = sum(max(0, PgVPP));                              % Netzeinspeisung mit VPP Gesamt in Wmin
            
            Eac2gNoVPP = sum(max(0, PgNoVPP));                          % Netzeinspeisung ohne VPP Gesamt in Wmin
            
            Eac2gBat = Eac2gVPP - Eac2gNoVPP;                           % Netzeinspeisung durch die FCR Erbringung der Batterie in Wmin
            
            Eac2gPV = Eac2gVPP - Eac2gBat;                              % Netzeinspeisung der PV-Anlage in Wmin

            % Ergebnisse in Matrix speichern:
            
            ERG.E_G_ConsumptionVPP(idi, idj, idk) = Eg2acl;     % Netzbezug durch den Hausverbrauch in Wmin
            ERG.E_PV_FeedInVPP(idi, idj, idk) = Eac2gPV;        % Netzeinspeisung der PV-Anlage in Wmin
            ERG.E_BAT_FeedIn(idi, idj, idk) = Eac2gBat;         % Netzeinspeisung durch die FCR Erbringung der Batterie in Wmin
            ERG.E_BAT_Consumption(idi, idj, idk) = Eg2acBat;    % Netzbezug durch die FCR Erbringung der Batterie in Wmin
            ERG.VZ_FCR(idi, idj, idk) = FCR.VZ;                 % Vollzyklen in 1/a
            ERG.E_Bat_FCR_neg(idi, idj, idk) = sum(Pdif(Pdif>0));       % Negative Regelenergie in Wmin
            ERG.E_Bat_FCR_pos(idi, idj, idk) = abs(sum(Pdif(Pdif<0)));  % Positive Regelenergie in Wmin
            SOCVPP(:, idi, idj, idk) = FCR.soc;
            
            % Vorbereitung für die Kostenrechnung des Cloud-Tarifes
            % Quelle: https://static1.squarespace.com/static/59af54ba15d5db05ecec047b/t/5ccbd6b41905f4aafa87d4a5/1556862685075/
            % 2.7+Kundenbrosch%C3%BCre+sonnen+GmbH+DE.pdf
            
                                                                        % sonnenFlat 4250 == keine Änderung
            
            if P_PV >= 7.5
                                                                        % sonnenFlat 4250 == keine Änderung
                                                                    
                if E_BAT >= 10
                    
                    if P_PV < 9.5                    
                        ERG.Tarif_FCR(idi, idj, idk) = 5500;            % sonnenFlat 5500
                    
                    else
                        if E_BAT < 12.5                        
                            ERG.Tarif_FCR(idi, idj, idk) = 6750;        % sonnenFlat 6750

                        else
                            if H_Load < 7272                            
                                ERG.Tarif_FCR(idi, idj, idk) = 6750;    % sonnenFlat 6750

                            else                            
                                ERG.Tarif_FCR(idi, idj, idk) = 8000;    % sonnenFlat 8000

                            end
                        end
                    end
                end
            end
            
            idi = idi+1;                                        % Laufvariable fuer die PV-Generatorleistung um eins erhoehen
        end
        idj = idj+1;                                            % Laufvariable fuer die Batteriekapazitaet um eins erhoehen
    end
    idk = idk+1;                                                % Laufvariable fuer den Hausverbrauch um eins erhoehen
end

% Umrechnung in kWh

f = 1 / 60 / 1000;

ERG.E_G_Consumption = ERG.E_G_Consumption * f;                  % Netzbezug in kWh
ERG.E_PV_FeedIn = ERG.E_PV_FeedIn * f;                          % Netzeinspeisung in kWh
ERG.E_G_ConsumptionVPP = ERG.E_G_ConsumptionVPP * f;            % Netzbezug durch den Hausverbrauch in kWh
ERG.E_PV_FeedInVPP = ERG.E_PV_FeedInVPP * f;                    % Netzeinspeisung der PV-Anlage in kWh
ERG.E_BAT_FeedIn = ERG.E_BAT_FeedIn * f;                        % Netzeinspeisung durch die FCR Erbringung der Batterie in kWh
ERG.E_BAT_Consumption = ERG.E_BAT_Consumption * f;              % Netzbezug durch die FCR Erbringung der Batterie in kWh
ERG.E_Bat_FCR_neg = ERG.E_Bat_FCR_neg * f;                      % Negative Regelenergie in kWh
ERG.E_Bat_FCR_pos = ERG.E_Bat_FCR_pos * f;                      % Positive Regelenergie in kWh

clear E_BAT Eac2g Eac2gBat Eac2gNoVPP Eac2gPV Eac2gVPP Eg2acBat Eg2acl Eg2acNoVPP f...
    Eg2acVPP Eg2ac H_Load idi idj idk Pbs PbsNoVPP PbsVPP Pd Pg PgNoVPP PgVPP Pl Ppvs P_PV PMax

%% 3.2.3 EEG Vergütung und Stromkosten ohne VPP
% Berechnung der Kosten

C_var = reshape(ERG.C_var,1,1,1,[]);                            % Vektor des Arbeitspreises in 4D-Matrix umwandeln in €/kWh

C_Consumption_var = ERG.E_G_Consumption .* C_var;               % Berechnung der Arbeitspreiskosten in €

ERG.C_Consumption = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load), length(ERG.C_var), length(ERG.C_fix));  % 5D-Ergebnismatrix Gesamtkosten

% Hinzufügen der Grundkosten in €:

for idxi=1:length(ERG.C_fix)
    ERG.C_Consumption(:,:,:,:,idxi) = C_Consumption_var(:,:,:,:) + 12 * ERG.C_fix(idxi);
end

% Berechnung der Erlöse

ERG.C_FeedIn = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load), length(ERG.C_EEG));                          % 4D-Ergebnismatrix Einspeisevergütung in €

C_EEG = reshape(ERG.C_EEG,1,1,1,[]);                            % Vektor der EEG-Einspeisevergütung in 4D-Matrix umwandeln in €/kWh

ERG.C_FeedIn = ERG.E_PV_FeedIn .* C_EEG;                        % Berechnung der EEG-Vergütung in €

clear idxi C_Consumption_var C_var C_EEG

%% 3.2.4 EEG Vergütung und Stromkosten mit VPP

% Berechnung der Kosten:

C_FixFlat = ERG.Tarif_FCR;                                      % Fixkosten
C_FixFlat(C_FixFlat < 8000) = 19.99 * 12;                       % sonnenFlat 6750 und kleiner Fix-Kosten in €/a
C_FixFlat(C_FixFlat >= 8000) = 29.99 * 12;                      % sonnenFlat 8000 Fix-Kosten in €/a

C_VarFlat = ones(size(C_FixFlat));                              % Gesamtstromverbrauch, Hausverbrauch zählt komplett 

for idxi=1:length(ERG.Load)
    C_VarFlat(:,:,idxi) = C_VarFlat(:,:,idxi) .* ERG.Load(idxi);
end

C_VarFlat = C_VarFlat - ERG.Tarif_FCR;                          % Freistrommengenüberziehung in kWh
C_VarFlat(C_VarFlat < 0) = 0;                                   % Unterschreitung führt zu keiner Vergütung
C_VarFlat(C_VarFlat < 2000) = C_VarFlat(C_VarFlat < 2000) * ERG.C_Flat(1);                                      % < 2000 kWh mit Arbeitspreis 23 ct/kWh in €
C_VarFlat(C_VarFlat >= 2000) = 2000 * ERG.C_Flat(1) + (C_VarFlat(C_VarFlat >= 2000) - 2000) * ERG.C_Flat(2);    % > 2000 kWh mit Arbeitspreis 23 (bis 2000) und 25,9 ct/kWh in €

ERG.C_ConsumptionFlat = C_FixFlat + C_VarFlat;                  % Gesamtkosten

% Berechnung der Erlöse:

ERG.C_FeedInFlat = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load), length(ERG.C_AW));   % 4D-Ergebnismatrix Einspeisevergütung in €

C_AW = reshape(ERG.C_AW,1,1,1,[]);                              % Vektor der EEG-Einspeisevergütung in 4D-Matrix umwandeln in €/kWh

ERG.C_FeedInFlat = ERG.E_PV_FeedInVPP .* C_AW;                  % Berechnung der EEG-Vergütung in €

clear C_AW C_FixFlat C_VarFlat idxi