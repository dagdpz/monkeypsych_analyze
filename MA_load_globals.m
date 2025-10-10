function MA_load_globals
global P_par
global MA_STATES

%% Format variables for the plots
P_par.hor_color = [0.2314 0.4431 0.3373];   % for individual plot x eye and hand
P_par.ver_color = [0.7490 0 0.7490];        % for individual plot y eye and hand
P_par.MarkerSize = 10;                      % for individual plots
P_par.FontName = 'Arial';
P_par.FontSize = 13;
P_par.FontWeight = 'normal';
P_par.LineWidth = 1.5;
P_par.xlim_h = [0 0.7];                     % horizontal limit for summary plots hand (s)
P_par.xlim_e = [0 0.7];                     % horizontal limit for summary plots eye (s)
P_par.xlim_fig_2 = [-15 15];                % horizontal limit for summary plots eye (s)
P_par.xlim_fig_3 = [0.5 2.5];               % horizontal limit for summary plots eye (s)
%P_par.xlim_fig_4 = [-20 20];                % horizontal limit for summary plots eye (s)
P_par.ylim_2 = [0 1];
P_par.bins = 0.0125 : 0.025 : 1;            % for histograms in the summary plots
P_par.bins2 = -0.125 : 0.025 : 0.850;       % for histograms in the summary plots
P_par.bins3 = -10 : 10;                     % for histograms in the summary plots
%P_par.bins4 = 0 : 3;                       % for histograms in the summary plots
P_par.bins5 = 0.0125 : 0.01 : 0.3;          % for histograms in the microstim summary plots
P_par.bins6 = -25 : 25;                     % for histograms in the microstim summary plots
%P_par.xlim = [0 20];                        % for individual plots
P_par.ylim = [-40 40];                      % for individual plots
P_par.ylim_states = [-1 51];                % for individual plots
% P_par.screen_h_lim_top=46;
% P_par.screen_h_lim_bot=-46;
P_par.screen_h_deg=50;
P_par.screen_w_deg=60;
P_par.bounds=5;

%% Definition of the states currently implemented in monkeypsych_dev
MA_STATES.INI_TRI = 1; % initialize trial
MA_STATES.FIX_ACQ = 2; % fixation acquisition
MA_STATES.FIX_HOL = 3; % fixation hold
MA_STATES.TAR_ACQ = 4; % target acquisition
MA_STATES.TAR_HOL = 5; % target hold
MA_STATES.CUE_ON  = 6; % cue on
MA_STATES.MEM_PER = 7; % memory period
MA_STATES.DEL_PER = 8; % delay period
MA_STATES.TAR_ACQ_INV = 9; % target acquisition invisible
MA_STATES.TAR_HOL_INV = 10; % target hold invisible
MA_STATES.MAT_ACQ = 11; % target acquisition in sample to match
MA_STATES.MAT_HOL = 12; % target acquisition in sample to match
MA_STATES.MAT_ACQ_MSK = 13; % target acquisition in sample to match
MA_STATES.MAT_HOL_MSK = 14; % target acquisition in sample to match
MA_STATES.SEN_RET     = 15; % return to sensors for poffenberger
MA_STATES.ABORT     = 19;
MA_STATES.SUCCESS   = 20;
MA_STATES.REWARD    = 21;
MA_STATES.ITI       = 50;
MA_STATES.CLOSE     = 99;
MA_STATES.SUCCESS_ABORT =-1;

MA_STATES.ALL               =[MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.DEL_PER MA_STATES.TAR_ACQ_INV  MA_STATES.TAR_HOL_INV...
    MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL MA_STATES.MAT_ACQ MA_STATES.MAT_HOL MA_STATES.MAT_ACQ_MSK MA_STATES.MAT_HOL_MSK MA_STATES.SEN_RET MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
MA_STATES.ALL_NAMES         ={'Trial Initiation', 'Fixation Acquisition', 'Fixation Hold', 'Cue On', 'Memory period', 'Delay period', 'Target Acquisition (invisible)',...
    'Target Hold (invisible)','Target Acquisition', 'Target Hold', 'Match Aquisition', 'Match Hold', 'Match Aquisition (Masked)', 'Match Hold (Masked)', 'Return to Sensors', 'Not aborted', 'Reward', 'ITI'};
MA_STATES.LABELS={'INI','Initial acq.', 'Initial hold', 'Tar acq.', 'Target hold', 'Cue on', 'Memory ', 'Delay', 'Tar inv acq.', 'Tar inv hold', 'Tar acq.', 'Tar hold', 'Tar acq. mask', 'Tar hold', 'Sen Ret', 'Success', 'Reward', 'ITI'};
MA_STATES.ALL_CHANGE_NAMES  ={'Holding sensors(?)', 'fixation', 'fixation brightening', 'cue onset', 'cue offset', 'delay period',...
    'go signal', 'target acquired', 'targets visible', 'targets brightening', 'targets visible', 'targets brightening', 'masked targets visible', 'target revealed', 'Target sensor reached', 'success', 'reward', 'ITI'};


end
