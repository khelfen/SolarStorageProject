function [Pbs] = bssimVPP(PV, VPP, LProf, SOC, Pd)

%% 1 Uebergabe der Systemparameter

% Nutzbare Speicherkapazität in kWh
E_BAT = PV.E_BAT; 
% Simulationszeitschrittweite in h
dt = PV.dt; 
% Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
P_AC2BAT_in = PV.P_AC2BAT_in; 
% Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
P_BAT2AC_out = PV.P_BAT2AC_out; 
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb 
eta_ac2bat = PV.eta_ac2bat;
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
eta_bat2ac = PV.eta_bat2ac;
% Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 
eta_bat = PV.eta_bat;
% VPP active
vppactive = LProf.vppactive;
% SOC boarders active
socactive = LProf.socactive;
% VPP power
pvpp = LProf.pvpp;
% PQ power
P_PQ = VPP.P_pq;
% VPP max power
P_VPP = VPP.P_max_pos;
% lower SOC boarder
soc_lower = SOC.lower;
% upper SOC boarder
soc_upper = SOC.lower;

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd)); % Ladezustand
Ebat = zeros(size(Pd)); % Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd)); % Batterieladeleistung in W
Pbatout = zeros(size(Pd)); % Batterieentladeleistung in W
Pbat = zeros(size(Pd)); % Batterieleistung in W
Pbs = zeros(size(Pd)); % Batteriesystemleistung in W
Pfcr = zeros(size(Pd)); % Regelleistung in W

%% 3 Zeitschrittsimulation des Batteriesystems

if 

