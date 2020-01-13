close all
% Plot-Data
Data = [SOC(:, Imin1, Imin2, Imin3) SOCVPP(:, Imin1, Imin2, Imin3) SOC(:, Imax1, Imax2, Imax3) SOCVPP(:, Imax1, Imax2, Imax3)];
Data_percent = Data * 100;

Dim = size(Data_percent);

% Create figure window
h_fig_soc = figure('Name','Verlauf des Ladestandes','NumberTitle','off');

% Figure size
x0=0;
y0=0;
width=1200;
height=800;
set(h_fig_soc,'position',[x0,y0,width,height]);

purple = [138 43 226] * 1/256;

%h_ax_soc = axes;

i = 1;
j = 1;

for i=1:Dim(2)
    
    h_ax_soc = subplot(2, 2, i);

    A_plot_data = Data_percent(:, i);

    len = length(A_plot_data);

    x_Data = (1:len); 

    % Create plot soc
    h_plt_soc = plot(h_ax_soc, x_Data, A_plot_data, 'color', purple);
    
    % Titel
    titles = [{'Fall A:', 'Ohne Regelleistungserbringung'} {'Fall A:', 'Mit Regelleistungserbringung'}...
        {'Fall B:', 'Ohne Regelleistungserbringung'} {'Fall B:', 'Mit Regelleistungserbringung'}];
    h_title = title(titles(j:j+1),'FontSize',16);

    % Legende
    %h_lgd = legend(h_plt_soc, 'Ladestand in %');

    % x-Labels
    labels = (1:12);
    set(h_ax_soc, 'xtick', 0+len/24:len/12:len+len/24, 'xticklabel', labels);
    a = get(h_ax_soc,'XTickLabel');
    set(h_ax_soc,'XTickLabel',a,'fontsize',12);
    
    % Properties
    %ylim(h_ax_soc, [-6 6]);
    xlim(h_ax_soc, [0 len]);
    h_xlabel = xlabel(h_ax_soc, 'Monat','FontSize',16);
    h_ylabel = ylabel(h_ax_soc, 'Ladestand in %','FontSize',16);

    % Background white
    set(h_fig_soc, 'Color', 'w');

    % Grid off
    grid(h_ax_soc, 'off');
    
    % xticks off
    set(h_ax_soc,'TickLength',[0 0])
    
    i = i+1;
    j = j+2;
end

%set(findall(h_fig_soc,'-property','FontSize'),'FontSize',18)

% Save Figure
saveas(h_fig_soc, 'Battery_SOC_extreme.svg', 'svg')