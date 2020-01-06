function [Pbs] = bssim(s, Pd)

%% 1 Uebergabe der Systemparameter

E_BAT = s.E_BAT;                                % Nutzbare Speicherkapazität in kWh
dt = s.dt;                                      % Simulationszeitschrittweite in h 
P_AC2BAT_in = s.P_AC2BAT_in;                    % Nominale AC-Leistungsaufnahme des Batteriewechselrichters in kW
P_BAT2AC_out = s.P_BAT2AC_out;                  % Nominale AC-Leistungsabgabe des Batteriewechselrichters in kW
eta_ac2bat = s.eta_ac2bat;                      % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Ladebetrieb
eta_bat2ac = s.eta_bat2ac;                      % Mittlerer Umwandlungswirkungsgrad des Batteriewechselrichters im Entladebetrieb 
eta_bat = s.eta_bat;                            % Mittlerer Umwandlungswirkungsgrad des Batteriespeichers 

%% 2 Vorinitialisierung der Variablen

soc = zeros(size(Pd));                          % Vektor Ladezustand
Ebat = zeros(size(Pd));                         % Vektor Energieinhalt des Batteriespeichers in kWh
Pbatin = zeros(size(Pd));                       % Vektor Batterieladeleistung in W
Pbatout = zeros(size(Pd));                      % Vektor Batterieentladeleistung in W
Pbat = zeros(size(Pd));                         % Vektor Batterieleistung in W
Pbs = zeros(size(Pd));                          % Ergebnisvektor Batteriesystemleistung in W


%% 3 Zeitschrittsimulation des Batteriesystems

tstart = 2;                                     % Startwert Zeit in min
tend = length(Pd);                              % Endwert Zeit in min

% Beginn der Zeitschrittsimulation

for t = tstart:tend

    if Pd(t) > 0                                % Batterieladung, sofern die Differenzleistung groesser null ist

        Pbatin(t) = min(Pd(t), P_AC2BAT_in * 1000) * eta_ac2bat;                % Batterieladeleistung auf max. DC WR-Leistung begrenzen

        Pbatin(t) = min(Pbatin(t), E_BAT * 1000 * (1-soc(t-1)) / dt / eta_bat); % Batterieladeleistung durch SOC begrenzen

    elseif Pd(t) < 0                            % Batterieentladung, sofern die Differenzleistung kleiner null ist

        Pbatout(t) = max(Pd(t), -P_BAT2AC_out * 1000) / eta_bat2ac;             % Batterieentladeleistung auf max. DC WR-Leistung begrenzen
        
        Pbatout(t) = -min(-Pbatout(t), E_BAT * 1000 * soc(t-1) / dt);           % Batterieladeleistung durch SOC begrenzen

    end

    Pbat(t) = Pbatin(t) + Pbatout(t);                                           % Batterieleistung bestimmen

    Pbs(t) = Pbatin(t) / eta_ac2bat + Pbatout(t) * eta_bat2ac;                  % Batteriesystemleistung bestimmen

    Ebat(t) = Ebat(t-1) + (Pbatin(t) * eta_bat + Pbatout(t)) / 1000 * dt;       % Anpassung des Energieinhalts des Batteriespeichers

    soc(t) = Ebat(t) / E_BAT;                                                   % Ladezustand berechnen

end

end