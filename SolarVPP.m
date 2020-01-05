%% Projekt Solarspeicher mit Einbindung in VPP Cloud
clear variables
close all

%% 1 Load Profiles
%% 1.1 PV

load('A04_Daten.mat');

LProf.ppvs = ppvs;

clear Pl ppvs

%% 1.2 Household

T_l = readtable('P_H.csv');
A_l = table2array(T_l);
LProf.pl = A_l(:,2);

clear T_l A_l

%% 1.3 VPP

T_VPP = readtable('P_VPP.csv');
A_VPP = table2array(T_VPP);
LProf.pvpp = A_VPP(:,3);

clear T_VPP A_VPP

%% 2 Parameters
%% 2.1 s - System PV + Bat

% Daten der sonnenBatterie aus Stromspeicherinspektion 2019
% Eventuell mit rein nehmen Standbyleistungsaufnahme 10 W

% Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
PV.P_AC2BAT_in = 3.3; % kW
% Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
PV.P_BAT2AC_out = 3.3; % kW
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb 
PV.eta_ac2bat = 0.944;
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
PV.eta_bat2ac = 0.945;
% Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 
PV.eta_bat = 0.93;
% Simulationszeitschrittweite in h
PV.dt = 1/60;

%% 2.2 H - Household

% Ausgangsparameter
% Maximale Leistungsabgabe des Referenzlastgang
H.PStartMax = 7355; % W
% Energieverbrauch des Referenzlastgang
H.EStart = 2348; % kWh

%% 2.3 V - Virtual Power Plant

% Präqualifizierte Leistung des VPP
VPP.P_PQ = 1; % MW
VPP.P_pq = VPP.P_PQ * 1000; % kW
% Anzahl der Batterien des VPP
VPP.n_Bat = 600;
% Theoretische maximale positive Leistung des VPP
VPP.P_max_pos = VPP.n_Bat * PV.P_BAT2AC_out; % kW
% Theoretische maximale negative Leistung des VPP
VPP.P_max_neg = VPP.n_Bat * PV.P_AC2BAT_in;  % kW
% Leistungsfaktor
VPP.f_P_VPP_pos = VPP.P_pq / VPP.P_max_pos;
VPP.f_P_VPP_neg = VPP.P_pq / VPP.P_max_neg;

clear VPP.P_PQ

%% 3 Auswertung
%% 3.1 Fixed Parameters

rng default;
% Matrix Hausverbrauch
ERG.Load = (2000:1000:10000); % kWh
% Matrix Batteriekapazität
ERG.BatCap = (8:2:16); % kWh
% Matrix PV-Generatorleistung
ERG.PVSize = (5:1:10); % kWp
% Matrix Strombezugskosten Arbeitspreis 
ERG.C_var = (0.25:0.01:0.32);
% Matrix Strombezugskosten Grundpreis
ERG.C_fix = (5:1:12);
% EEG Vergütungssätze
ERG.C_EEG = [9.87 9.97 10.08 10.18 10.33 10.48 10.64 10.79 10.95...
    11.11 11.23 11.35 11.47 11.59 11.71 11.83 11.95 12.08 12.20...
    12.24 12.27 12.30] * 0.01;
% VPP aktiv an dem Tag: Zuschlag an 80% der Tage
num_active = 0.8;
[LProf.vppactive, LProf.socactive] = active(num_active);
clear num_active

% SOC-Grenzen aktiv
socactive = LProf.socactive;
% Teilnahme am PRL-Markt im Zeitschritt
vppactive = LProf.vppactive;
% Frequenzabweichung im Zeitschritt außerhalb des Totbandes
pvpp_active = LProf.pvpp ~= 0;
% Approximation, ob eigene Batterie aktiv ist in diesem Zeitschritt
a = rand(length(pvpp_active),1);
b = abs(LProf.pvpp) * VPP.P_pq / VPP.P_max_pos;
bat_active = a <= b;
% In Matrix speichern
VAll = [vppactive, pvpp_active, bat_active];
% VPP activ und SOC Grenzen
tstart = 1;
tend = length(vppactive);

BAT.lower_SOC = zeros(length(vppactive),1);
BAT.upper_SOC = zeros(length(vppactive),1);
BAT.vppactive = zeros(length(vppactive),1);

for t = tstart:tend
    if socactive(t) == 0
        % SOC-Grenzen setzen
        BAT.lower_SOC(t) = 0;
        BAT.upper_SOC(t) = 1;

        % FCR off
    else
        % SOC-Grenzen setzen
        BAT.lower_SOC(t) = 0.2;
        BAT.upper_SOC(t) = 0.8;

        switch polyval(VAll(t,:), 2) % -> solving p(x) = p1*x^2 + p2*x + p3 with x = 2 and pn = vector element
            case 7 % vppactive = 1, pvpp_active = 1, c = 1
                % FCR on
                BAT.vppactive(t) = 1;
            otherwise
                % FCR off
                continue
        end
    end
end

%% 3.2 Simulation without VPP
%% 3.2.1 Variation des Hausverbrauchs, Batteriekapazitaet und PV-Generatorleistung

% Index der zur Ergebnisspeicherung erforderlich ist.
ERG.E_G_Consumption = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));
ERG.E_PV_FeedIn = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));
ERG.E_G_ConsumptionVPP = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));
ERG.E_PV_FeedInVPP = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load));

% Laufvariable fuer die Batteriekapazitaet
idk = 1;

for H_Load = ERG.Load
    % Laufvariable fuer den Hausverbrauch (Spaltennr. der Ergebnismatrix)
    idj = 1;
    % Hausverbrauch anpassen
    H.EIst = H_Load; % kWh

    for E_BAT = ERG.BatCap 
        % Laufvariable fuer die PV-Generatorleistung (Zeilennr. der Ergebnismatrix)
        idi = 1;
        % Batteriekapazitaet anpassen
        PV.E_BAT = E_BAT; % kWh

        for P_PV = ERG.PVSize
            % PV-Generatorleistung anpassen
            PV.P_PV = P_PV; % kWp
            % Ausgangsleistung des PV-Systems in W aus der spezifischen
            % AC-Leistungsabgabe des PV-Systems und der nominalen PV-Generatorleistung
            Ppvs = LProf.ppvs * PV.P_PV * 1000; % W
            % Neue Lastspitze Hausverbrauch
            PMax = H.PStartMax * H.EIst / H.EStart; % W
            % Lastprofil bei Ist-Energieverbrauch
            Pl = LProf.pl * PMax; % W

            % Differenzleistung in W
            Pd = Ppvs - Pl; % W

            % Aufruf des Simulationsmodells
            [Pbs] = bssim(PV, Pd);

            % Netzleistung bestimmen
            Pg = Ppvs - Pl - Pbs;

            % Energiesummen
            % Netzbezug in kWh
            Eg2ac = sum(abs((min(0, Pg)))) / 60 / 1000;
            % Netzeinspeisung in kWh
            Eac2g = sum(max(0, Pg)) / 60 / 1000;            

            % Ergebnisse in Matrix speichern
            ERG.E_G_Consumption(idi, idj, idk) = Eg2ac;
            
            ERG.E_PV_FeedIn(idi, idj, idk) = Eac2g;
            
%% Simulation mit VPP

            [PbsVPP, FCR] = bssimVPP(PV, LProf, BAT, Pd);
            
            % Netzleistung bestimmen
            PgVPP = Ppvs - Pl - PbsVPP;

            % Energiesummen
            % Netzbezug in kWh
            Eg2acVPP = sum(abs((min(0, PgVPP)))) / 60 / 1000;
            % Netzeinspeisung in kWh
            Eac2gVPP = sum(max(0, PgVPP)) / 60 / 1000;            

            % Ergebnisse in Matrix speichern
            ERG.E_G_ConsumptionVPP(idi, idj, idk) = Eg2acVPP;
            
            ERG.E_PV_FeedInVPP(idi, idj, idk) = Eac2gVPP;
                        
            % Laufvariable fuer die PV-Generatorleistung um eins erhoehen
            idi = idi+1;
        end
        % Laufvariable fuer die Batteriekapazitaet um eins erhoehen
        idj = idj+1;
    end
    % Laufvariable fuer den Hausverbrauch um eins erhoehen
    idk = idk+1;
end

clear t a b bat_active check pvpp_active socactive tend tstart VAll vppactive...
    idk idj idi E_BAT H_Load P_PV Pbat Eg2acVPP Eac2gVPP Pbs PbsVPP Pl PMax...
    Ppvs Pg Eg2ac Eac2g Pd PgVPP

%% 3.2.2 Feed in tariffs and electricity costs

C_var = reshape(ERG.C_var,1,1,1,[]);

% OPEX
C_Consumption_var = ERG.E_G_Consumption .* C_var;

% Ergebnismatrix Gesamtkosten
ERG.C_Consumption = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load), length(ERG.C_var), length(ERG.C_fix));

% CAPEX
for idxi=1:length(ERG.C_fix)
    ERG.C_Consumption(:,:,:,:,idxi) = C_Consumption_var(:,:,:,:) + 12 * ERG.C_fix(idxi);
end

% Ergebnismatrix Gesamtkosten
ERG.C_FeedIn = zeros(length(ERG.PVSize), length(ERG.BatCap), length(ERG.Load), length(ERG.C_EEG));

% EEG FeedIn compensation
C_EEG = reshape(ERG.C_EEG,1,1,1,[]);

ERG.C_FeedIn = ERG.E_PV_FeedIn .* C_EEG;

clear idxi C_Consumption_var C_var C_EEG

