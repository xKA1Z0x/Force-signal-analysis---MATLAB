clear all
close all

% Allows you to open a .mat file exported from Spike2
% Filters the data
% Finds the steadiest 10s of the trial (lowest CV for force)
% Calculates mean force, standard deviation of force, and CV for force
% Calculates a time "index"  to allow a researcher to match the 10s steadiness window 
        % to EMG data (reports the # of seconds before relaxation, where 10s window starts)

%% Load file
dataname = uigetfile;
load(dataname);
%enter the name of the force channel in your file in the first and time
%event channel in the second line
stringname = strcat('your force channel name','.values');
rawtime = eval(strcat('your time channel name','.times'));
rawforce = eval(stringname);
%% Filter
fc = 20;         % Filter cutoff = 20 Hz
sf = 100;           % Sampling frequency (rate) = 1000 Hz
[filt2, filt1] = butter(4,fc/sf/2);      % Apply Butterworth filter
force = filtfilt(filt2, filt1, rawforce);
%% Plot original force trace
forcefig = figure(1);
forceplot = plot(force,'LineWidth',2,'Color',[0.4 0.4 0.4]);
set(forcefig, 'Position', [50, 200, 1200, 400]);
ylabel('\fontsize{12}Force (Volts)');
xlabel('\fontsize{12}Time');
title(['\fontsize{16} Force Steadiness'])
hold on
xline(rawtime(end)*100,'r')
%% User graphical input for shrinking the length of the force trace
%splits
[splitx] = ginput(2);
force1 = force(1:floor(splitx(1,1)),:);
force2 = force(floor(splitx(1,1)):floor(splitx(2,1)),:);
force3 = force(floor(splitx(2,1)):end,:);
%% User graphical input for selecting the baseline and beginning of the contract           
           % Trial 2
            forcefig2 = figure(2);
            forceplot2 = plot(force2,'LineWidth',2,'Color',[0 0.8 1]);
            set(forcefig2, 'Position', [50, 200, 1200, 400])
            ylabel('\fontsize{12}Force (Volts)');
            xlabel('\fontsize{12}Time');
            title(['\fontsize{16} Trial 2: \color{red}Please click right before the start and right after the end of the steadiness trial and then 2 points where the force is at baseline:'])
                % User Input - Select start & end of trial
                [start2] = ginput(1);
                [end2] = ginput(1);
                [baseline2a] = ginput(1);
                [baseline2b] = ginput (1);
                % Error check - Is selection longer than 10s?
                chunk2 = end2-start2;
                if chunk2<(20*100)
                    errorbox = errordlg('Invalid Selction: Longer force steadiness window required.','Error');
                    % Pause until error message is closed
                    waitfor(errorbox)
                    % User Input - Select new start & end of trial
                    [start2] = ginput(1);
                    [end2] = ginput(1);
                end
            close(forcefig2)
            % Set selection parameters & preallocate matrices used in for loop
            % Adjust start & end points to be integers
                start2 = floor(start2(1,1));
                end2 = floor(end2(1,1));
                                                                                                                                                                                                    
            %% Steadiest window parameters
            time = 10;      % Number of seconds desired for window (10s)
            window = time*sf; % Convert time to # data points
            jump = sf/10;   % How far apart each 10s window should be (0.1s)
                                                
            % Preallocate vectors
            mean2 = zeros(10000,1);
            sd2 = zeros(10000,1);
            cv2 = zeros(10000,1);
            % Variables in for loop
            r2 = 1; % Counter
            section2 = force2(start2:start2+window-1); % Vector with first 10s window
            sweeps2 = floor(((end2-start2)-window)/jump); % Number of loops needed
            
            %define baseline
            baseline2=force2(floor(baseline2a(1,1)):floor(baseline2b(1,1)));

            % For Loop to scan for steadiest 10s window
            for j = 1:sweeps2
                tempmean2 = mean(section2)-mean(baseline2);
                mean2(r2,1) = tempmean2;
                tempsd2 = std(section2);
                sd2(r2,1) = tempsd2;
                cv2(r2,1) = coefvar(tempmean2,tempsd2);
                r2 = r2 + 1;
                section2 = force2(start2+(jump*j):start2+(jump*j)+window-1);
            end
            % Find lowest SD & CV
                % Trim zeros off end of vectors
                trimsd2 = find(sd2,1,'last');
                sd2 = sd2(1:trimsd2);
                trimcv2 = find(cv2,1,'last');
                cv2 = cv2(1:trimcv2);
               % Minimums  (SN = sweep number)   
               [minsd2,SNsd2] = min(sd2);
               [mincv2,SNcv2] = min(cv2);
            % Plot results
               % Selected portion of force trace with minimum sd and cv
                    % Should pretty much always be the same!
               sdIndex2 = (start2+SNsd2*jump);
               selectedsd2 = force2(sdIndex2:sdIndex2+window-1);
               cvIndex2 = (start2+SNcv2*jump);
               selectedcv2 = force2(cvIndex2:cvIndex2+window-1);
                    % Align selected portion to x-axis
                    align2sd = (sdIndex2:sdIndex2+window-1)';
                    plot2sd = horzcat(align2sd,selectedsd2);
                    % Align selected portion to x-axis
                    align2cv = (cvIndex2:cvIndex2+window-1)';
                    plot2cv = horzcat(align2cv,selectedcv2);
               % Mean force during this window
               minmean2 = mean2(SNsd2);
               % Plot
               forcefig2 = figure(2);
               forceplot2 = plot(force2,'LineWidth',2,'Color',[0 0.8 1]);  % Original
               hold on
               plot(plot2cv(:,1),plot2cv(:,2),'LineWidth',2,'Color',[0 0.4 1])
               xlim([start2-200,end2+200])
               y2 = get(gca,'ylim');
               plot([cvIndex2, cvIndex2],y2,'LineWidth',0.5,'Color',[0.6 0.6 0.6],'LineStyle','--')
               plot([cvIndex2+window-1, cvIndex2+window-1],y2,'LineWidth',0.5,'Color',[0.6 0.6 0.6],'LineStyle','--')
               title(['\fontsize{14}Force Steadiness Trial 2'])
               hold off             
               % Wait until figure is closed
               waitfor(forcefig2)
               if rawtime(end)*100 < splitx(1,1)
                   starttime = cvIndex2 + (splitx(1,1)-(rawtime(end)*100));
               else
                   starttime = cvIndex2 - ((rawtime(end)*100)-splitx(1,1));
               end             
               endtime = starttime + 1000;
               starttime = starttime / 100;
               endtime = endtime / 100;
        

%% Saving the force parameters in the file
               Variables = [mincv2,starttime,endtime];
               save FoceSteadiness.dat Variables -ascii -append
               
               % Save Values & Write to CSV file
                    % Add information about data
                    subject = strtok(dataname,'_');
                    
                    % Does spreadsheet already exist?
                    if ~exist('Force_Steadiness_Data.txt', 'file') == 1
                        % Prep spreadsheet
                        fid = fopen('Force_Steadiness_Data.txt','w');
                        fprintf(fid,'Subject,Time,Mean1,SD1,CV1,Index1,Mean2,SD2,CV2,Index2');
                    end
                    % Save data or not?
                    choice = questdlg('Would you like to save this data?','Save','Yes','No','Yes');
                    switch choice
                        case 'Yes'
                        fid = fopen('Force_Steadiness_Data.txt','a');
                        fprintf(fid,'\n%s,%s,%s,%f,%f,%f,%f',subject,minmean2,minsd2,mincv2);
                        case 'No'
                    end       