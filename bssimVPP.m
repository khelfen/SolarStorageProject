function [PbsVPP, FCR] = bssimVPP(PV, LProf, BAT, Pd)
%bssimVPP Berechnung der Batterieleistung je Zeitschritt mit Anbindung in
%das VPP

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
% VPP power
pvpp = LProf.pvpp;
% lower SOC border
soc_lower = BAT.lower_SOC;
% upper SOC border
soc_upper = BAT.upper_SOC;
% VPP aktiv
vppactive = BAT.vppactive;

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd)); % Ladezustand
Ebat = zeros(size(Pd)); % Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd)); % Batterieladeleistung in W
Pbatout = zeros(size(Pd)); % Batterieentladeleistung in W
PbatinVPP = zeros(size(Pd)); % Batterieladeleistung hervorgerufen durch VPP in W
PbatoutVPP = zeros(size(Pd)); % Batterieentladeleistung hervorgerufen durch VPP in W
PbatinTheo = zeros(size(Pd)); % Batterieladeleistung in W, wenn ohne VPP
PbatoutTheo = zeros(size(Pd)); % Batterieladeleistung in W, wenn ohne VPP
Pbat = zeros(size(Pd)); % Batterieleistung in W
PbsVPP = zeros(size(Pd)); % Batteriesystemleistung in W
PbsVPPonly = zeros(size(Pd)); % Batteriesystemleistung nur FCR in W
PbsTheo = zeros(size(Pd)); % Theoretische Batteriesystemleistung in W
FCR.in = zeros(size(Pd)); % Negative Regelleistung in W
FCR.out = zeros(size(Pd)); % Positive Regelleistung in W

%% 3 Berechnung der Zeitschritte

tstart = 2;
tend = length(Pd);

for t = tstart:tend
    
	if vppactive(t) == 0

        if (Pd(t) > 0) && (soc(t) < soc_upper(t))   % Batterieladung, sofern die Differenzleistung groesser null ist.

            % Batterieladeleistung auf nominale DC-Ladeleistung vom
            % Batteriewechselrichter begrenzen
            Pbatin(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;

            % Batterieladeleistung im aktuellen Zeitschritt ermitteln   
            Pbatin(t) = min(Pbatin(t), E_BAT * 1000 * max(0, (soc_upper(t)-soc(t-1))) / dt / eta_bat);

        elseif (Pd(t) < 0) && (soc(t) > soc_lower(t))   % Batterieentladung, sofern die Differenzleistung kleiner null ist.

            % Batterieentladeleistung auf nominale DC-Entladeleistung vom
            % Batteriewechselrichter begrenzen
            Pbatout(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;

            % Batterieentladeleistung im aktuellen Zeitschritt ermitteln
            Pbatout(t) = max(-Pbatout(t), -E_BAT * 1000 * (soc(t-1) - soc_lower(t)) / dt);

        end
        
    else
       
        if pvpp(t) < 0 % Batterie laden, wenn FCR negativ
            
            PbatinVPP(t) = min(P_AC2BAT_in * 1000 * eta_ac2bat, E_BAT * 1000 * (1 - soc(t-1)) / dt / eta_bat);
            Pbatin(t) = PbatinVPP(t);
            
        elseif pvpp(t) > 0 % Batterie entladen, wenn FCR positiv
            
            PbatoutVPP(t) = max(-P_BAT2AC_out * 1000 / eta_bat2ac, -E_BAT * 1000 * soc(t-1) / dt);
            Pbatout(t) = PbatoutVPP(t);
            
        end
        
        % Vergleich mit AP ohne VPP, um FCR-Leistung zu berechnen
        
        if (Pd(t) > 0) && (soc(t) < soc_upper(t))   % Batterieladung, sofern die Differenzleistung groesser null ist.

            % Batterieladeleistung auf nominale DC-Ladeleistung vom
            % Batteriewechselrichter begrenzen
            PbatinTheo(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;

            % Batterieladeleistung im aktuellen Zeitschritt ermitteln   
            PbatinTheo(t) = min(PbatinTheo(t), E_BAT * 1000 * max(0, (soc_upper(t)-soc(t-1))) / dt / eta_bat);

        elseif (Pd(t) < 0) && (soc(t) > soc_lower(t))   % Batterieentladung, sofern die Differenzleistung kleiner null ist.

            % Batterieentladeleistung auf nominale DC-Entladeleistung vom
            % Batteriewechselrichter begrenzen
            PbatoutTheo(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;

            % Batterieentladeleistung im aktuellen Zeitschritt ermitteln
            PbatoutTheo(t) = max(-PbatoutTheo(t), -E_BAT * 1000 * (soc(t-1) - soc_lower(t)) / dt);

        end
        
    end

    % Batterieleistung bestimmen
    Pbat(t) = Pbatin(t) + Pbatout(t);

    % Batteriesystemleistung bestimmen
    PbsVPP(t) = Pbatin(t) / eta_ac2bat + Pbatout(t) * eta_bat2ac;
    
    % durch FCR ausgelöst
    PbsVPPonly(t) = PbatinVPP(t) / eta_ac2bat + PbatoutVPP(t) * eta_bat2ac;
    
    % Theoretische Batteriesystemleistung bestimmen
    PbsTheo(t) = PbatinTheo(t) / eta_ac2bat + PbatoutTheo(t) * eta_bat2ac;

    % Anpassung des Energieinhalts des Batteriespeichers
    Ebat(t) = Ebat(t-1) + (Pbatin(t) * eta_bat + Pbatout(t)) / 1000 * dt;

    % Ladezustand berechnen
    soc(t) = Ebat(t) / E_BAT;

end

FCR.PFCR = PbsVPPonly - PbsTheo ;

FCR.PbatoutVPP = PbatoutVPP;

FCR.PbatoutTheo = PbatoutTheo;
FCR.soc = soc;

end

