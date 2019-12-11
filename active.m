function [vppactive, socactive] = active(num_active)
% Generation Random series zero or one with fixed probability
% 1: VPP Active
% 2: Optimisation own consumption

rng default;

% Dayvector rndm
active = rand(365,1);

% Dayvector logical 1 = VPP active
active = active <= num_active;

% Minutes-Vector SOC and VPP active
socactive = zeros(365*24*60,1); % Vector: 1 = SOC boarders active, 0 = no boarders
vppactive = zeros(365*24*60,1); % Vector: 1 = frequency responce active, 0 = no FR active

n = 1;

% Stunden vor Beginn der VPP Erbringung an denen SOC Grenzen aktiv sein
% sollen
num_soc_start = 10;

for i = 1:length(active)
    
    if n == 1 % Anfangswertproblem
        
        if active(i) == 0            
            socactive(n:n+(24*60)-1) = 0;  
            vppactive(n:n+(24*60)-1) = 0;
        else
            socactive(n:n+(24*60)-1) = 1;
            vppactive(n:n+(24*60)-1) = 1;
        end
        
    else % Sonst
        
        if active(i) == 0            
            socactive(n:n+(24*60)-1) = 0;
            vppactive(n:n+(24*60)-1) = 0;
        else
            socactive(n-(num_soc_start*60):n+(24*60)-1) = 1;
            vppactive(n:n+(24*60)-1) = 1;
        end
        
    end
    
    n = n + 24*60; 
end

end

