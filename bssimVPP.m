function [Pbs] = bssimVPP(PV, VPP, LProf, Pd)

%% 1 Uebergabe der Systemparameter

rng default;

% Nutzbare Speicherkapazit‰t in kWh
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

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd)); % Ladezustand
Ebat = zeros(size(Pd)); % Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd)); % Batterieladeleistung in W
Pbatout = zeros(size(Pd)); % Batterieentladeleistung in W
Pbat = zeros(size(Pd)); % Batterieleistung in W
Pbs = zeros(size(Pd)); % Batteriesystemleistung in W
Pfcr = zeros(size(Pd)); % Regelleistung in W

%% 3 Zeitschrittsimulation des Batteriesystems

% Erster und letzter Zeitschritt der Zeitschrittsimulation
tstart = 2;
tend = length(Pd);

soc_vpp_on_max = 0.8;
soc_vpp_on_min = 0.2;

soc_vpp_off_max = 1;
soc_vpp_off_min = 0;

% Beginn der Zeitschrittsimulation
for t = tstart:tend
    
    if socactive(t) == 1 % Ladestandsgrenzen aktiv
        
        if vppactive(t) == 1 % VPP aktiv
            
            if pvpp(t) ~= 0 % Frequenz auﬂerhalb Totband
                
                rnd = rand();
                
                probability = abs(pvpp(t) * P_PQ / P_VPP);
                
                if rnd <= probability % VPP Leistungserbringung aktiv
                    
                    if pvpp(t) > 0
                        
                    else
                        
                    end
                    
                else
                    
                end
                    
                    
                
            elseif pvpp(t) < 0 % Frequenz unterhalb 49.99 Hz
                
            else % Frequenz innerhalb des Totbandes 
                
            end
            
        else
            
        end
        
    else
        
    end
    
end

%     if Pd(t) > 0 % Batterieladung, sofern die Differenzleistung groesser null ist.
% 
%         % Batterieladeleistung auf nominale DC-Ladeleistung vom
%         % Batteriewechselrichter begrenzen
%         Pbatin(t) = min(Pd(t),P_AC2BAT_in*1000) * eta_ac2bat;
% 
%         % Batterieladeleistung im aktuellen Zeitschritt ermitteln   
%         Pbatin(t) = min(Pbatin(t), E_BAT*1000 * (1-soc(t-1)) / dt / eta_bat);
% 
%     elseif Pd(t) < 0 % Batterieentladung, sofern die Differenzleistung kleiner null ist.
% 
%         % Batterieentladeleistung auf nominale DC-Entladeleistung vom
%         % Batteriewechselrichter begrenzen
%         Pbatout(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;
% 
%         % Batterieentladeleistung im aktuellen Zeitschritt ermitteln
%         Pbatout(t) = -min(-Pbatout(t), E_BAT * 1000 * soc(t-1) / dt);
% 
%     end
% 
%     % Batterieleistung bestimmen
%     Pbat(t) = Pbatin(t) + Pbatout(t);
% 
%     % Batteriesystemleistung bestimmen
%     Pbs(t) = Pbatin(t) / eta_ac2bat + Pbatout(t) * eta_bat2ac;
% 
%     % Anpassung des Energieinhalts des Batteriespeichers
%     Ebat(t) = Ebat(t-1) + (Pbatin(t) * eta_bat + Pbatout(t)) / 1000 * dt;
% 
%     % Ladezustand berechnen
%     soc(t) = Ebat(t) / E_BAT;
% 
% end
% 
% % Netzleistung %Pg=Pd-Pbs;
% % Pg=Ppvs-Pl-Pbs;
% end