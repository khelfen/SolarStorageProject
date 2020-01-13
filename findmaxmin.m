% Finden der minimalen positiven und maximalen negativen FCR

% Positive FCR - Batterie entladen
[minFCRpos,Indmin] = min(ERG.E_Bat_FCR_pos(:));
[Imin1,Imin2,Imin3] = ind2sub(size(ERG.E_Bat_FCR_pos),Indmin);

% Negative FCR - Batterie laden
[maxFCRneg,Indmax] = max(ERG.E_Bat_FCR_neg(:));
[Imax1,Imax2,Imax3] = ind2sub(size(ERG.E_Bat_FCR_pos),Indmax);