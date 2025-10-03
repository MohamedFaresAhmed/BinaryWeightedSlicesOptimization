clc;clear;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  *********************************                      %
%                  *   __  __   ______   _____     *                      %
%                  *  |  \/  | |  ____| |  __ \    *                      %
%                  *  | \  / | | |____  | |__| |   *                      %
%                  *  | |\/| | |  ____| |  __  |   *                      %
%                  *  | |  | | | |      | |  | |   *                      %
%                  *  |_|  |_| |_|      |_|  |_|   *                      %
%                  *                               *                      %
%                  *********************************                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% MATLAB code for designing binary-weighted resistor networks.
% It searches for the minimum number of slices that meet a target error,
% computes optimal slice resistance, and analyzes error under PVT variations.





% Parameters
Rtarget = 500;                          % Target resistance (Ohms)
N = 6;                                  % (Can be sweeped) Number of binary-weighted slices "Control Signals"
Target_Error = 7;                       % Target Error (%)


PVT_Range = [0.4 1.6];      % PVT variation range
PVT_Var = linspace(PVT_Range(1), PVT_Range(2), 1000);
Rslice_values = PVT_Var*Rtarget;

% Preallocate
Errors = zeros(size(PVT_Var));
Rtotal_values = zeros(size(PVT_Var));
Error_N = zeros(size(N));
Optimum_Rslice_Values = zeros(3,length(N));

for m = 1:length(N)
    
    K = 0.2:0.2:round(2^N(m));            % Factor between Slice and Target Resistance
    
    %%%% Rule of thumb: Rslice = ((2^N - 1)*Rtarget)/PVT_max    "Works for N <= 10"
    
    Error_K = zeros(size(K));
    
    for j = 1:length(K)
        for i = 1:length(PVT_Var)
            Rslice = K(j)*PVT_Var(i)*Rtarget;
            
            % Calculate required sum of weights to achieve Rtarget
            sum_weights = Rslice / Rtarget;
            
            % Round to nearest integer and clamp to [1, 2^N - 1]
            sum_weights_rounded = round(sum_weights);
            sum_weights_rounded = max(1, min(2^N(m) - 1, sum_weights_rounded));
            
            
            % Calculate Rtotal
            Rtotal = Rslice / sum_weights_rounded;
            % Store results
            Errors(i) = (Rtotal - Rtarget) / Rtarget * 100;
        end
        Error_K(j) = max(abs(Errors));
    end
    
    [min_Error_value,Indx] = min(Error_K);
    
    Error_N(m) = min_Error_value;
    
    Rslice_Rule_of_thumb = ((2^N(m) - 1)*Rtarget)/PVT_Range(2);
    
    Optimum_Rslice_Values(:,m) = [N(m), round(K(Indx)*Rtarget), min_Error_value];
    
    % Define row names
    rowNames = {'N', 'Rslice', 'Worst Case Error'};
    
    Optimum_Values = array2table(Optimum_Rslice_Values, 'RowNames', rowNames);
end



if length(N) == 1
    
    Used =zeros(1,2^N -1);
    
    for i = 1:length(PVT_Var)
        Rslice = K(Indx)*PVT_Var(i)*Rtarget;
        
        % Calculate required sum of weights to achieve Rtarget
        sum_weights = Rslice / Rtarget;
        
        % Round to nearest integer and clamp to [1, 2^N - 1]
        sum_weights_rounded = round(sum_weights);
        sum_weights_rounded = max(1, min(2^N(m) - 1, sum_weights_rounded));
        
        
        % Calculate Rtotal
        Rtotal = Rslice / sum_weights_rounded;
        Rtotal_values(i) = Rtotal;
        
        Errors(i) = (Rtotal - Rtarget) / Rtarget * 100;
        
        % Round to nearest integer and clamp to [1, 2^N - 1]
        sum_weights_rounded = round(sum_weights);
        sum_weights_rounded = max(1, min(2^N - 1, sum_weights_rounded));
        Used(sum_weights_rounded) = 1;
        
    end
end

Font_Size = 22;
Line_width = 2.2;

%Ratio = K(Indx)/(2^N - 1);
if length(N) ~= 1
    % Plot results
    figure;
    bar(N,Error_N);
    yline(Target_Error, 'r--', 'LineWidth', Line_width);  % Draw line without label
    
    % Add the label manually with custom font size
    ylimits = ylim;  % Get current y-axis limits
    text(N(end)-2, Target_Error, ' Acceptable Error', 'Color', 'r', 'FontSize', Font_Size, ...
        'VerticalAlignment', 'top');
    xlabel('Number of Binary-Weighted Slices');
    ylabel('Worst Case Error');
    title('Worst Case Error');
    grid on;
    set(gca,'FontName', 'Helvetica', 'FontSize', Font_Size); % Apply font settings
else
    
    figure;
    plot(K*Rtarget/1000,Error_K, 'LineWidth', Line_width);
    hold on;
    plot(K(Indx)*Rtarget/1000,min_Error_value, 'ro', 'MarkerSize', 14, 'LineWidth', Line_width);
    xlabel('Rslice (kΩ)');
    ylabel('Worst Case Error');
    title('Error vs Rslice');
    legend('Error Profile', 'Optimal Rslice')
    grid on;
    set(gca,'FontName', 'Helvetica', 'FontSize', Font_Size); % Apply font settings
    
    figure;
    plot(PVT_Var, Rtotal_values, 'b', 'LineWidth', Line_width);
    xlabel('PVT Variation (%)'); ylabel('Rtotal (Ω)');
    yline( Rtarget, 'r--', 'LineWidth', Line_width);
    legend('Rtotal', 'Rtarget', 'Location', 'best');
    title('Rtotal vs PVT Variation'); grid on;
    set(gca,'FontName', 'Helvetica', 'FontSize', Font_Size); % Apply font settings

    
    figure;
    plot(PVT_Var, Errors, 'k', 'LineWidth', Line_width);
    yline(Target_Error, 'r--', 'LineWidth', Line_width);
    yline(-Target_Error, 'r--', 'LineWidth', Line_width);
    xlabel('PVT Variation (%)'); ylabel('Error (%)');
    title('Error vs PVT Variation'); grid on;
    set(gca,'FontName', 'Helvetica', 'FontSize', Font_Size); % Apply font settings

    
    fprintf('Worst Case Error %.3f%% at Rslice = %.0f Ω\n', min_Error_value, K(Indx)*Rtarget);
    fprintf('Rule of thumb Rslice = %.0f Ω\n', Rslice_Rule_of_thumb);
    
end