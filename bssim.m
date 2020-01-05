function [Pbs] = bssim(s, Pd)

%% 1 Uebergabe der Systemparameter

% Nutzbare Speicherkapazität in kWh
E_BAT = s.E_BAT; 
% Simulationszeitschrittweite in h
dt = s.dt; 
% Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
P_AC2BAT_in = s.P_AC2BAT_in; 
% Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
P_BAT2AC_out = s.P_BAT2AC_out; 
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb 
eta_ac2bat = s.eta_ac2bat;
% Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
eta_bat2ac = s.eta_bat2ac;
% Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 
eta_bat = s.eta_bat;

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd)); % Ladezustand
Ebat = zeros(size(Pd)); % Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd)); % Batterieladeleistung in W
Pbatout = zeros(size(Pd)); % Batterieentladeleistung in W
Pbat = zeros(size(Pd)); % Batterieleistung in W
Pbs = zeros(size(Pd)); % Batteriesystemleistung in W


%% 3 Zeitschrittsimulation des Batteriesystems

% Nur simulieren, wenn die Kapazitaet groesser null ist
if E_BAT > 0

    % Erster und letzter Zeitschritt der Zeitschrittsimulation
    tstart = 2;
    tend = length(Pd);

    % Beginn der Zeitschrittsimulation
    for t = tstart:tend

        if Pd(t) > 0 % Batterieladung, sofern die Differenzleistung groesser null ist.

            % Batterieladeleistung auf nominale DC-Ladeleistung vom
            % Batteriewechselrichter begrenzen
            Pbatin(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;

            % Batterieladeleistung im aktuellen Zeitschritt ermitteln   
            Pbatin(t) = min(Pbatin(t), E_BAT * 1000 * (1-soc(t-1)) / dt / eta_bat);

        elseif Pd(t) < 0 % Batterieentladung, sofern die Differenzleistung kleiner null ist.

            % Batterieentladeleistung auf nominale DC-Entladeleistung vom
            % Batteriewechselrichter begrenzen
            Pbatout(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;

            % Batterieentladeleistung im aktuellen Zeitschritt ermitteln
            Pbatout(t) = -min(-Pbatout(t), E_BAT * 1000 * soc(t-1) / dt);

        end
 
        % Batterieleistung bestimmen
        Pbat(t) = Pbatin(t) + Pbatout(t);

        % Batteriesystemleistung bestimmen
        Pbs(t) = Pbatin(t) / eta_ac2bat + Pbatout(t) * eta_bat2ac;

        % Anpassung des Energieinhalts des Batteriespeichers
        Ebat(t) = Ebat(t-1) + (Pbatin(t) * eta_bat + Pbatout(t)) / 1000 * dt;

        % Ladezustand berechnen
        soc(t) = Ebat(t) / E_BAT;

    end
end

% Netzleistung %Pg=Pd-Pbs;
% Pg=Ppvs-Pl-Pbs;
end