function [PbsVPP, PbsNoVPP, FCR] = bssimVPP(PV, LProf, BAT, Pd)
%bssimVPP Berechnung der Batterieleistung je Zeitschritt mit Anbindung in
%das VPP

%% 1 Uebergabe der Systemparameter

E_BAT = PV.E_BAT;                   % Nutzbare Speicherkapazität in kWh
dt = PV.dt;                         % Simulationszeitschrittweite in h
P_AC2BAT_in = PV.P_AC2BAT_in;       % Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
P_BAT2AC_out = PV.P_BAT2AC_out;     % Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
eta_ac2bat = PV.eta_ac2bat;         % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb 
eta_bat2ac = PV.eta_bat2ac;         % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
eta_bat = PV.eta_bat;               % Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 
pvpp = LProf.pvpp;                  % VPP Leistung in %
soc_lower = BAT.lower_SOC;          % Untere SOC Grenze je Zeitschritt in %
soc_upper = BAT.upper_SOC;          % Obere SOC Grenze je Zeitschritt in %
vppactive = BAT.vppactive;          % FCR-Erbringung der Batterie aktiv

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd));              % Ladezustand
Ebat = zeros(size(Pd));             % Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd));           % Batterieladeleistung in W
Pbatout = zeros(size(Pd));          % Batterieentladeleistung in W
PbatinVPP = zeros(size(Pd));        % Batterieladeleistung hervorgerufen durch VPP in W
PbatoutVPP = zeros(size(Pd));       % Batterieentladeleistung hervorgerufen durch VPP in W
PbatinTheo = zeros(size(Pd));       % Batterieladeleistung in W, wenn ohne VPP
PbatoutTheo = zeros(size(Pd));      % Batterieladeleistung in W, wenn ohne VPP
PbsVPP = zeros(size(Pd));           % Batteriesystemleistung in W
PbsVPPonly = zeros(size(Pd));       % Batteriesystemleistung nur FCR in W
PbsTheo = zeros(size(Pd));          % Theoretische Batteriesystemleistung in W

%% 3 Berechnung der Zeitschritte

tstart = 2;
tend = length(Pd);

for t = tstart:tend
    
	if vppactive(t) == 0

        if (Pd(t) > 0)              % Batterieladung, sofern die Differenzleistung groesser null ist.

            Pbatin(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;                                    % Batterieladeleistung auf max. DC WR-Leistung begrenzen
 
            Pbatin(t) = min(Pbatin(t), E_BAT * 1000 * max(0, (soc_upper(t)-soc(t-1))) / dt / eta_bat);  % Batterieladeleistung durch SOC begrenzen
            
        elseif (Pd(t) < 0)          % Batterieentladung, sofern die Differenzleistung kleiner null ist.
            
            Pbatout(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;                                 % Batterieentladeleistung auf max. DC WR-Leistung begrenzen

            Pbatout(t) = -min(-Pbatout(t), E_BAT * 1000 * max(0, soc(t-1) - soc_lower(t)) / dt);        % Batterieentladeleistung durch SOC begrenzen

        end
        
    else
       
        if pvpp(t) < 0              % Batterie laden, wenn FCR negativ
            
            PbatinVPP(t) = min(P_AC2BAT_in * 1000 * eta_ac2bat, E_BAT * 1000 * (1 - soc(t-1)) / dt / eta_bat);  % Batterieladeleistung durch SOC bzw. max. DC WR-Leistung begrenzen
            Pbatin(t) = PbatinVPP(t);
            
            
        elseif pvpp(t) > 0          % Batterie entladen, wenn FCR positiv
            
            PbatoutVPP(t) = max(-P_BAT2AC_out * 1000 / eta_bat2ac, -E_BAT * 1000 * soc(t-1) / dt);      % Batterieentladeleistung durch SOC bzw. max. DC WR-Leistung begrenzen
            Pbatout(t) = PbatoutVPP(t);
            
        end
        
        % Vergleich mit AP ohne VPP, um FCR-Leistung zu berechnen
        
        if (Pd(t) > 0)              % Batterieladung, sofern die Differenzleistung groesser null ist.

            PbatinTheo(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;                                        % Batterieladeleistung auf max. DC WR-Leistung begrenzen
 
            PbatinTheo(t) = min(PbatinTheo(t), E_BAT * 1000 * max(0, (soc_upper(t)-soc(t-1))) / dt / eta_bat);  % Batterieladeleistung durch SOC begrenzen

        elseif (Pd(t) < 0)          % Batterieentladung, sofern die Differenzleistung kleiner null ist.
            
            PbatoutTheo(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;                                     % Batterieentladeleistung auf max. DC WR-Leistung begrenzen

            PbatoutTheo(t) = -min(-PbatoutTheo(t), E_BAT * 1000 * max(0, soc(t-1) - soc_lower(t)) / dt);        % Batterieentladeleistung durch SOC begrenzen

        end
        
    end

    Ebat(t) = Ebat(t-1) + (Pbatin(t) * eta_bat + Pbatout(t)) / 1000 * dt;       % Anpassung des Energieinhalts des Batteriespeichers in kWh

    soc(t) = Ebat(t) / E_BAT;                                                   % Ladezustand berechnen

end

PbsVPP = Pbatin / eta_ac2bat + Pbatout * eta_bat2ac;               % Batteriesystemleistung bestimmen in W

PbsVPPonly = PbatinVPP / eta_ac2bat + PbatoutVPP * eta_bat2ac;     % Batterieleistung, nur durch FCR ausgelöst in W

PbsTheo = PbatinTheo / eta_ac2bat + PbatoutTheo * eta_bat2ac;      % Theoretische Batteriesystemleistung bestimmen in W

PbsNoVPP = PbsVPP - PbsVPPonly + PbsTheo;                          % Batterieleistung mit FCR in W

FCR.Pbs = PbsVPP;                       % Batteriesystemleistung in W
FCR.VPP = PbsVPPonly;                   % Batterieleistung durch FCR ausgel�st in W
FCR.soc = soc;                          % SOC der Batterie
FCR.PFCR = PbsVPPonly - PbsTheo;        % Lastgang der FCR in W

% Batterievollzyklen berechnen

FCR.VZ = sum(abs(diff(soc))) / 2;       % Anzahl der Vollzyklen ( 0% -> 100% -> 0%) in 1/a

end