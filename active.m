function [vppactive, socactive] = active(num_active)
% Generation zufälliger I/O-Vektoren zur Simulation eines Einsatzplans
% eines virtuellen Kraftwerks
    % socactive:
        % 1: Maximale und Minimale SOC-Grenzen aktiv
        % Annahme: 80% und 20%
        % 0: SOC-Grenzen inaktiv
    % vppactive:
        % 1: Leistungserbringung durch das virtuelle Kraftwerk ist
        % eingeschaltet
        % 0: Eigenverbrauchsoptimierung

rng default;                    % Random Seed standardisieren

active = rand(365,1);           % Vektor der Tage des Jahres
active(1) = 1.1;                % erster Tag im Jahr --> nie Regelleistung

active = active <= num_active;  % Zufällige Verteilung entscheided ob 1 oder 0

socactive = zeros(365*24*60,1); % Minutenvektoren SOC-aktiv
vppactive = zeros(365*24*60,1); % Minutenvektoren VPP-aktiv

n = 1;                          % Startwert

num_soc_start = 12;             % Stunden vor Beginn der VPP Erbringung an denen SOC Grenzen aktiv sein sollen
                                % Annahme: 12 Stunden

% Erstellung der Minutenvektoren aus dem Tagesvektor

for i = 1:length(active)

    if active(i) == 0            
        socactive(n:n+(24*60)-1) = 0;
        vppactive(n:n+(24*60)-1) = 0;
    else
        socactive(n-(num_soc_start*60):n+(24*60)-1) = 1;
        vppactive(n:n+(24*60)-1) = 1;
    end
    
    n = n + 24*60; 
end

end

