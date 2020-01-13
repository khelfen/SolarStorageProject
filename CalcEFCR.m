% Berechnung der theoretischen Energieabgabe des Batteriesystems
% für die Erbringung von FCR

% Nur berechnen, wenn VPP auch aktiv
Pvppactive = LProf.pvpp .* LProf.vppactive;

% Negative Regelleistung - Batterie laden
E_neg = abs(sum(Pvppactive(Pvppactive < 0))) * 1000 / 60 / VPP.n_Bat;

% Positive Regelleistung - Batterie laden
E_pos = sum(Pvppactive(Pvppactive > 0)) * 1000 / 60 / VPP.n_Bat;