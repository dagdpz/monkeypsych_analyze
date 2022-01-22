function [out_comp, variable_to_test, counter]= monkeypsych_analyze_working(varargin)
% Ulises Vargas, Lukas Schneider, Igor Kagan.
% [out_comp variable_to_test counter]= monkeypsych_analyze_working({'Y:\Data\Curius_microstim_with_parameters\20140211',2},{'nsacc_max',10,'summary',0,'success',1,'display',1,'saccade_1bo',1,'sac_ini_t',30,'sac_end_t',15,'sac_min_dur',0.01,'only_voluntary_saccades',1})
% [out_comp variable_to_test counter]= monkeypsych_analyze_working({'Y:\Data\Curius_microstim_with_parameters\20140211',2},{'summary',1,'display',1,'choice',1,'trial_history_mode',1,'microstim',1,'observed_structure','binary','current_history_parameter','eyetar_l','observed_value',1,'past_parameter','microstim','past_value',1,'consecutive_trials',1,'n_trials_past',5,'past_keys',{'choice',NaN,'microstim',NaN}})
% [out_comp variable_to_test counter]= monkeypsych_analyze_working({'Y:\Data\Curius\setup2_microstim\20140211',2},{'summary',1,'display',1})

%% Basic algorithm information

% Subfunction stucturing:
%
% The main function organizes batch compilation, key assignment, and inferential statistics (comparing batches)
% monkeypsych_analyze_runs_preprocessing controls for computation mode (f.e. evoked saccades mode or trial history mode)
% and deals with inexistent files (or runs where no single trial fulfills the selection criteria).
% monkeypsych_analyze_calculation is the main computation function and is applied to each run seperately.
% Summary plotting functions can be used with the output, meaning independently from the computation.

% Trial selection
%
% Before any computation, trials can be excluded according to specified selection criteria (-> see keys). They will not be processed any further.
% In this part, in order to make selection criteria work, some parameters that are essential for the algorithm are set:

% Observed state (state_obs) = State in which saccade/reach is required (this depends on the task type!)
%                           type 1      -> FIX_HOL
%                           type 2      -> TAR_ACQ
%                           type 2.5    -> TAR_ACQ
%                           type 3      -> TAR_ACQ_INV
%                           type 4      -> TAR_ACQ
%                           type 5      -> MAT_ACQ
%                           type 6      -> MAT_ACQ_MSK

% Information state (state_inf) = State in which the information about targets is available
%                           type 1      -> FIX_ACQ
%                           type 2      -> TAR_ACQ
%                           type 2.5    -> CUE_ON
%                           type 3      -> CUE_ON
%                           type 4      -> CUE_ON
%                           type 5      -> CUE_ON
%                           type 6      -> CUE_ON

% Intended target (Note that this is different from chosen targets in the raw data)
%
% All intended eye targets (a_i_t_e) and all intended hand targets (a_i_t_h) are defined for current trial :
% According to target_selected, if this value is valid. Note that a target is selected once it is acquired (except for Match to sample so far)
% If target_selected is not defined, but the trial was not aborted before state_inf or state_obs, for instructed and choice respectively,
%   a_i_t_e and a_i_t_h equal 1 for instructed trials,
%   a_i_t_e and a_i_t_h will be defined by the median(!) eye/hand  position (for saccades/reaches) in the aborted state (!) for choice trials,
% Else, a_i_t_e and a_i_t_h are NaN
% If it was a fixation task (type==1), a_i_t_e and a_i_t_h are NaN regardless of choice/instructed
% Not intended targets (a_n_t_e and a_n_t_h) are defined for current trial only if there was choice and an intended target, else they are NaN


% Saccade detection and selection
%
% Recorded eye traces are interpolated to a temporal resolution of 1 kHz, velocities are computed, and saccades are detected for different states independently,
% (i.e the 2 states before the observed state up to 1 state after the observed state), if a the saccade initiation velocity threshold (sac_ini_t -> see keys) is reached.
% Saccade duration is defined as the time from saccade initiation until the time when velocity drops below the saccade end threshold (sac_end_t -> see keys).
% If this duration is lower than a minimum duration (sac_min_dur -> see keys), this saccade is treated as noise and therefore omitted.
% Since all other saccades will be detected and information about them will be stored in the output, as long as the total number of saccades per
% state does not exceed the maximum of saccades detected (nsacc_max -> see keys), these criterions are the most critical (sac_ini_t, sac_end_t, sac_min_dur, nsacc_max)
% Furthermore, out of these detected saccades, one saccade per trial is selected depending on the saccade state (-> see keys) and saccade definition (-> see keys)

% Reach detection and selection
%
% Reaching is initiated whenever the touchscreen is not touched any more
% (except for fixation trials (type 1), where releasing the sensor initiates the reaching - this information is stored seperately for other types)
% Reaction time (reaches.ini) is the time from onset of the corresponding state to the reach initiation
% Reach end and reach endpositions are determined for three different
% definitions: The first position touched, the first position touched inside the target



%% Input/output format
% -------------------------------------------------------Input---------------------------------------------
% [out_comp variable_to_test counter] = monkeypsych_analyze_20140910(ALL_files,batch_1_conditions,{},batch_2_conditions);
% [out_comp variable_to_test counter] = monkeypsych_analyze_20140910(batch_1_files,batch_1_conditions,batch_2_files,batch_2_conditions);
% files format: {'D:\Data\Bacchus\20130813',[1,2,3,4,...];'D:\Data\Bacchus\20130814',[1,2,3,4,...];...}
% conditions format: {'Keyword 1',Key_value 1,'Keyword 2',Key_value 2,...}
% Full example:
% [out_comp variable_to_test counter] = monkeypsych_analyze_20140910({'D:\Data\Bacchus\20130813',[1,2,3,4];'D:\Data\Bacchus\20130814',[1,2,3,4]},{'condition1',value1,'condition2',value2},...
%               {'D:\Data\Bacchus\20130813',[1,2,3,4]},{'condition1',value1,'condition2',value2},{'D:\Data\Bacchus\20130813',[1,2,3,4]},{'condition1',value1,'condition2',value2});
%
% -------------------------------------------------------Output---------------------------------------------
% out_comp: Cell array with one row for each batch (and one column for each trial history condition, if trial history mode is on (-> see keys)),
% each of the elements out_comp{n-Batch} is a structure array containing several fields:
% Note that every single entry is first pre-allocated with NaNs (in the corresponding format), and later eventually overwritten with available information

% task(n_trial) information is directly taken from the trial structure for storage of task details

% type                      The task type
% effector                  The used effector
% abort_code                String storing reasons for aborting
% reward_modulation         If it was a reward modulation trial
% reward_selected           Selected reward
% reward_time               Reward size for that trial
% stim_start                Start of microstimulation relative to start of microstim state (in sec)
% stim_end                  End of microstimulation relative to start of microstim state (in sec)
% stim_state                State in which microstimulation was applied
% ini_mis                   Start of microstimulation relative to start of trial (in sec)
% stim_to_state_end         Start of microstimulation relative to end of microstim state (in sec)
% current_strength          Current applied (in uA)
% train_duration_ms         Train duration of microstimulation (in ms)
% electrode_depth           Depth of the microstim electrode (in mm)
% impedance_end_kilo_ohms   Electrode impedance right after microstimulation experiment (in kOhm)
%
% timing(n_trial) information is directly taken from the trial structure for storage of task details
%
% fix_time_to_acquire_hnd
% tar_time_to_acquire_hnd
% tar_inv_time_to_acquire_hnd
% fix_time_to_acquire_eye
% tar_inv_time_to_acquire_eye
% tar_time_to_acquire_eye
% fix_time_hold
% fix_time_hold_var
% cue_time_hold
% cue_time_hold_var
% mem_time_hold
% mem_time_hold_var
% del_time_hold
% del_time_hold_var
% tar_inv_time_hold
% tar_inv_time_hold_var
% tar_time_hold
% tar_time_hold_var
%

% states(n_trial) stores information about relevant states (dependent on task)

% all_states                A List of all states in this trial in chronological order (depends on task type)
% state_obs                 Observed state = State in which saccade/reach is required (this depends on the task type!)
%                           type 1      -> FIX_HOL
%                           type 2      -> TAR_ACQ
%                           type 2.5    -> TAR_ACQ
%                           type 3      -> TAR_ACQ_INV
%                           type 4      -> TAR_ACQ
%                           type 5      -> MAT_ACQ
%                           type 6      -> MAT_ACQ_MSK
% state_2bo                 The state 2 states before observed state (this depends on the task type!)
% state_1bo                 The state 1 state before observed state  (this depends on the task type!)
% state_1ao                 The state 1 state after observed state   (this depends on the task type and success!)
% state_abo                 The state in which the trial was aborted

% saccades(n_trial) and reaches(n_trial) contain saccade and reach related data.
% several fields are present in both structures:
% Selected saccade depends on the saccade definition (-> see keys!), as default the saccade that ended up closest to the target and happened during observed state is taken
% Reach duration and endposition depends on reach definition (-> see keys!), as default the first touching inside the target radius is taken)

% lat                       Latency of selected saccade/reach (relative to start of state)
% dur                       Duration of selected saccade/reach
% velocity                  Peak velocity of selected saccade/reach
% startpos                  Start position of selected saccade/reach                                                        complex values ! (x=real, y=imag)
% endpos                    End position of selected saccade/reach                                                          complex values ! (x=real, y=imag)
% accuracy_xy               End position of selected saccade/reach (relative to target), in euclidean coordinates           complex values ! (x=real, y=imag)
% accuracy_rad              End position of selected saccade/reach (relative to target),
%                           Real part parallel to the target (pos= overshoot, neg= undershoot),
%                           Imaginary part perpendicular to the target (pos= counterclockwise, neg= clockwise)              complex values ! (x=real, y=imag)
% fix_pos                   The eye/hand fixation position (in deg)                                                         complex values ! (x=real, y=imag)
% tar_pos                   The (chosen) eye/hand target position (in deg)                                                  complex values ! (x=real, y=imag)
% nct_pos                   The (not chosen) eye/hand target position (in deg)                                              complex values ! (x=real, y=imag)
% fix_rad                   The eye/hand fixation window size (in deg)
% tar_rad                   The eye/hand target window size (in deg)

% saccades(n_trial) contains saccade related processed data
% There are two types of fields:

% One type containing vectors (for all saccades detected, one type containing only one value for the selected
% saccade (according to calculation keys and algorithm)

% 1) Vector value fields
% Here, information about all detecteted saccades (according to detection thresholds and up to a given maximum of nsacc_max -> see keys)
% is stored, out of which the saccade is later selected

% ini_2bo                   Initiation timepoints (relative to trial start) of saccades starting in state_2bo
% ini_1bo                   Initiation timepoints (relative to trial start) of saccades starting in state_1bo
% ini_obs                   Initiation timepoints (relative to trial start) of saccades starting in state_obs
% ini_1ao                   Initiation timepoints (relative to trial start) of saccades starting in state_1ao
% ini_evo                   Initiation timepoints (relative to trial start) of evoked saccade
% end_2bo                   End timepoints (relative to trial start) of saccades starting in state_2bo
% end_1bo                   End timepoints (relative to trial start) of saccades starting in state_1bo
% end_obs                   End timepoints (relative to trial start) of saccades starting in state_obs
% end_1ao                   End timepoints (relative to trial start) of saccades starting in state_1ao
% startpos_2bo              Start positions of saccades starting in state_2bo                                       complex values ! (x=real, y=imag)
% startpos_1bo              Start positions of saccades starting in state_1bo                                       complex values ! (x=real, y=imag)
% startpos_obs              Start positions of saccades starting in state_obs                                       complex values ! (x=real, y=imag)
% startpos_1ao              Start positions of saccades starting in state_1ao                                       complex values ! (x=real, y=imag)
% endpos_2bo                End positions of saccades starting in state_2bo                                         complex values ! (x=real, y=imag)
% endpos_1bo                End positions of saccades starting in state_1bo                                         complex values ! (x=real, y=imag)
% endpos_obs                End positions of saccades starting in state_obs                                         complex values ! (x=real, y=imag)
% endpos_1ao                End positions of saccades starting in state_1ao                                         complex values ! (x=real, y=imag)
% vel_2bo                   Peak velocities of saccades starting in state_2bo
% vel_1bo                   Peak velocities of saccades starting in state_1bo
% vel_obs                   Peak velocities of saccades starting in state_obs
% vel_1ao                   Peak velocities of saccades starting in state_1ao
% amplitudes_2bo            Amplitudes of saccades starting in state_2bo
% amplitudes_1bo            Amplitudes of saccades starting in state_1bo
% amplitudes_obs            Amplitudes of saccades starting in state_obs
% amplitudes_1ao            Amplitudes of saccades starting in state_1ao

% 2) Scalar value fields

% num_sac                   Position of selected saccade (meaning if it was the first, second, etc., in the corresponding state!)
% velocity                  Peak velocity of selected saccade
% evoked                    Flags, if there was an evoked saccade (1) or not (0), according to the used definitions (see keys: )

% reaches

% demanded_hand             The hand the monkey was asked to use (note that this can also be 3 (=hand selection), and does not necessarily mean that the monkey used that hand
% reach_hand                The hand the monkey used (according to sensors, only if both sensors were used !)
% ini                       time between onset of observed state and not touching the screen any more
%                           for fixation trials (type 1), the time between fixation target onset and lifting the hand from the sensors
% end_stat                  time between onset of observed state and the end of the observed state
% ini_fix                   time between fixation target onset and lifting the hand from the sensors
% dur_fix                   time between lifting the hand from the sensors and touching the screen
% precision_pos_l_fix
% precision_pos_r_fix
% precision_dis_l_fix
% precision_dis_r_fix
% pos_first_fix
% pos_first                 the first touched position after lifting the hand from the screen
% pos_inside                the first touched position (inside the target) after lifting the hand from the screen
% pos_last                  the last touched position in the state after observed state (hold state)

% binary

% success                   If it was a successful trial 1= success, 0=error
% completed                 If it was a completed trial (identical to success for all types except match to sample so far)
% choice                    If it was a choice or instructed trial
% abort_in_acq              !!??
% targets_visible           If cues/targets have already been visible
% reward_modulation         If it was a reward modulation trial
% reward_selected_small     If small  reward was selected
% reward_selected_normal    If medium reward was selected
% reward_selected_large     If large  reward was selected
% rest_sensor_1             If rest sensor 1 (left) was used
% rest_sensor_2             If rest sensor 2 (right) was used
% rest_sensors_on           If both sensors were used
% temp_reach_hnd_1
% temp_reach_hnd_2
% reach_hnd_1
% reach_hnd_2
% nosaccade                 If there was no saccade detected that fits the definition (but requested)
% noreach                   If there was no reach  detected that fits the definition (but requested)
% right_hand
% left_hand
% eyetar_l                  If there was an eye target on the left
% eyetar_r                  If there was an eye target on the right
% hndtar_l                  If there was a hand target on the left
% hndtar_r                  If there was a hand target on the right
% sac_within_distance_l
% sac_within_distance_r
% rea_within_distance_l
% rea_within_distance_r
% sac_us_l
% sac_os_l
% sac_us_r
% sac_os_r
% rea_us_l
% rea_os_l
% rea_us_r
% rea_os_r
% microstim                 If it was a microstim trial
% sac_inprecise
% sac_doesntgo
% sac_nottotarget
% rea_inprecise
% rea_doesntgo
% rea_nottotarget
% saccade_expected          If there was a saccade required
% reach_expected            If there was a reach  required
%
%
%% The Keys !!!
% Keyword---------------------------Description-----------------------------------------------------Useful Key_values
%
% Mode Keys-------------------------Very general keys modifying principle functionality
%
% 'evoked_saccades_mode'            Mode that allows indicating evoked saccades                     1 (on - automatically on, if 'evoked' is not NaN), 0 (off)
% 'trial_history_mode'              Mode for looking at trial history                               1 (on - look for trial history options), 0 (off)
% 'error_analysis_mode'             Mode that adjusts other keys to investigate error sources       1 (on), 0 (off)
% 'evoked'                          for looking at trials that show evoked saccades                 1 (with evoked saccades), 0 (without evoked saccades), NaN (both)
% 'evaluate_evoked'                 for looking at the "evoked" saccades                            1 (on), 0 (off)
%
% Selective Keys--------------------Keys to select only trials that fit the selection criterions, if a key is NaN (=default), all trials fit the selection criterion
% Simple selective Keys-------------Parameters correspond to fields in the trial or trial.task structure (identical names !) and can be simply added (don't forget the default value)
%
% 'type'                            task type selector                                              so far: 1,2,3,4
% 'effector'                        task effector selector                                          0 (eye), 1 (hand) ,2 (combined), 3 (reach with fixation),4 (saccades with central reach)
% 'choice'                          choice\instructed selector                                      1 (choice), 0 (instructed)
% 'reach_hand'                      reaching hand selector (CHOSEN hand - trial.reach_hand)         1 (left), 2 (right)
% 'success'                         success trial selector 1 (success), 0 (error), no specificiation gives successfull & error trials 
% 'reward_modulation'
% 'reward_selected'
% 'abort_code'
% 'microstim'                       microstim selector                                              1 (stimulation on), 0 (stimulation off)
% 'microstim_state'                 State in which stimulation occured selector                     potentially all states (see global STATES)
% 'microstim_start'                 Stimulation start after state change                            time in seconds
% 'stim_to_state_end'               Stimulation start before (!) next state change                  time in seconds (only possible if microstim_start is negative)
% 'current_strength'
% 'train_duration_ms'
% 'pulse_duration_micro_ms'
% 'electrode_depth'
% 'impedance_start_kilo_ohms'
% 'impedance_end_kilo_ohms'
% 'impedance_after_cleaning_kilo_ohms'
% 'electrode_used'                  to select trials where a particular electrode was used          electrode ID according to Lot/Box number
% 'current_polarity'                for selecting used stimulation current polarity                 'pos_first' or 'neg_first'


% Complex selective Keys------------Parameters don't correspond to fields in the trial or trial.task structure, so selectors need to be defined in the computation level
%
% 'pos_x'                           target position selector(selection has to match 'pos_y' too)    [pos_x 1, pos_x 2, ...] in degrees
% 'pos_y'                           target position selector(selection has to match 'pos_x' too)    [pos_y 1, pos_y 2, ...] in degrees
% 'max_radius'                      maximum fixation and target radius selector                     maximum radius in degrees
% 'aborted_state'                   selects all trials aborted AFTER specified state                potentially all states (see global STATES), -1 for successful
% 'trial_set'                       select a set of combined (!) trials                             [trial 1, trial 2, ...]
% 'demanded_hand'                   reaching hand selector (REQUIRED hand - trial.taskreach_hand)   0 (stay), 1 (left), 2 (right), 3 (hand choice)

% Calculational Keys----------------Keys to select calculational option for reaches / saccades
%
% 'runs_as_batches'
% 'saccade_definition'              there are several definitions available for selecting saccades  1: saccade, that ended up closest to the target and was big enough
%                                   shouldn't make any difference if there was only 1 saccade...    2: biggest saccade that ended up close enough
%                                                                                                   3: last saccade in the state
%                                                                                                   4: first saccade in the state
% 'reach_1st_pos'                   reach end == 1st touch after release                            1 (compute), 0 (don't compute)
% 'reach_1st_pos_in'                reach end == 1st touch in target window                         1 (compute), 0 (don't compute)
% 'reach_pos_at_state_change'       reach end == state change                                       1 (compute), 0 (don't compute)
%                                   reach selection follows a priority rule:
%                                   reach_1st_pos_in (if computed) > reach_1st_pos (if computed) > reach_1st_pos_in (if computed)
% 'saccade_2bo'                     calculate saccades during state 2 before observed state         1 (compute), 0 (don't compute)
% 'saccade_1bo'                     calculate saccades during state 1 before observed state         1 (compute), 0 (don't compute)
% 'saccade_obs'                     calculate saccades during observed state                        1 (compute), 0 (don't compute)
%                                   saccade selection follows a priority rule:
%                                   saccade_obs (if computed) > saccade_1bo (if computed) > saccade_2bo (if computed)
% 'nsacc_max'                       maximum number of saccades calculated for one state             integer values >=1
% 'sac_ini_t'                       initiation velocity threshold for saccades (in degrees/sec)     defines saccade detection, be careful
% 'sac_end_t'                       end velocity threshold for saccades (in degrees/sec)            defines saccade detection, be careful
% 'sac_min_dur'                     Minimum saccade duration (in sec) for saccade detection         defines saccade detection, be careful
% 'min_sac_amplitude'               Minimum saccade amplitude (in deg) for saccade detection        defines the minimum amplitude for selected saccades in saccade_definition for closest saccades (1)
% 'max_sac_dist'                    maximum distance from target for saccades                       [max_dist_x max_dist_y] defines if a miss is still taken as intended to go to that target position
%                                                                                                   which is crucial for choice trials to define the desired target location
%                                                                                                   also defines maximum distance to the target for selected saccades in saccade_definition for biggest saccades (2)
% 'max_rea_dist'                    maximum distance from target for reaches                        [max_dist_x max_dist_y] defines if a miss is still taken as intended to go to that target position
%                                                                                                   which is crucial for choice trials to define the desired target location
% 'correct_offset'                  center median eye postion in target acquisition                 1 (on), 0 (off)
% 'lat_after_micstim'               saccade latencies are taken as latencies after microstim_start  1 (on), 0 (off)


% Plotoption Keys-------------------Keys to select plotoptions
%
% 'display'                         Displays batch-by-batch summary plots                           1 (on), 0 (off)
% 'summary'                         Select what to plot                                             0 (trial by trial), 1 (only first...) 2 (first two...) 3(all three...)  6 (Danials plot - target positions)...summary plots per batch                                                                                                   
% 'show_run_ends'                   Draws vertical lines where Runs end                             1 (on), 0 (off)
% 'show_only_one_sac_per_trial'     Plotting only one or several saccades per trial                 1 (one), 0 (several)
% 'show_trace'                      Connecting start and endpoints of all saccades per trial        1 (on), 0 (off)
% 'show_trial_number'               If trial numbers should be shown in the positions subplot       1 (on), 0 (off)
% 'show_sliding'                    If hand sliding should be shown in the positions subplot        1 (on), 0 (off)
% 'additional_description'          Additional description for summary plots                        'description_in plot'
% 'marker_parameter'                Parameter that is encoded by different markers in summary plot  'parameter_to_look_at'
% 'fill_parameter'                  Parameter that is encoded by filled markers in summary plot     'parameter_to_look_at'
% 'fill_value'                      Value that be encoded by filled markers in summary plot         fill_parameter == fill_value will be filled

% Inferential keys------------------Keys to select inferential options

% 'inferential_on'                  To switch inferental on or off                                  1 (on), 0 (off)
% 'boxplot_on'                      To switch boxplots on or off                                    1 (on), 0 (off)
% 'multicomparison'                 To switch multicomparison on or off                             1 (on), 0 (off)
% 'inf_structure'                   Specifies structure to do comparisons on                        'saccades', 'reaches'
% 'inf_field'                       specifies field of 'inf_structure' to do comparisons on         all the output fields (see output structure), f.e. 'lat' (default)
% 'counting_field'                  field of outputstructure 'counts' used as output counter        all fields of 'output_comb.counts, f.e. 'left_chosen_successful' (default)

% Evoked----------------------------Keys to specify evoked saccade definition (only in microstim mode)

% 'evoked_ini_velocity'             initiation velocity threshold for evoked saccades               defines evoked saccades, be careful
% 'evoked_end_velocity'             end velocity threshold for evoked saccades                      defines evoked saccades, be careful
% 'evoked_stimlocked_latency_min'   after stimulation start latency criterion                       minimum saccade latency after stim_start to count as evoked
% 'evoked_stimlocked_latency_max'   after stimulation start latency criterion                       maximum saccade latency after stim_start to count as evoked
% 'evoked_amplitude_min'            amplitude criterion                                             minimum saccade amplitude to count as evoked
% 'evoked_min_duration'             duration criterion                                              maximum saccade duration to count as evoked
% 'consecutive_saccade'             consecutive saccade criterion                                   1 (on - only saccades that are followed by corrective saccades are taken as evoked), 0 (off)
% 'simulate_evoked'                 for checking "evoked" saccades in baseline with assumptions:    1 (on), 0 (off)
% 'sim_stimstart'                   assumed microstim start                                         defines control "evoked" saccades in baseline
% 'sim_stimstate'                   assumed microstim state                                         defines control "evoked" saccades in baseline
% 'sim_stim_to_state_end'           assumed time from stimulation onset to state end                defines control "evoked" saccades in baseline
% 'sim_stimdur'                     assumed microstim duration                                      defines control "evoked" saccades in baseline


% Trial history options-------------Keys to trial history calculation

% 'current_parameter'
% 'current_value'
% 'past_parameter'
% 'past_value'
% 'n_trials_past'
% default.history_values={'aborted_state',NaN,'aborted_state',-1,1};


%%%Start_keys
keys.mode={'standard','error_analysis_mode','trial_history_mode','evaluate_evoked','without_evoked_saccades','after_evoked_saccades'};
default_key_values.mode=[{1} repmat({0},1,numel(keys.mode)-1)];

keys.complex_selective={'fix_range_x','fix_range_y','cue_range_x','cue_range_y','tar_range_x','tar_range_y','max_radius','aborted_state','demanded_hand','trial_set'};
default_key_values.complex_selective=repmat({NaN},1,numel(keys.complex_selective));

keys.simple_selective={'type','effector','choice','target_selected','success','microstim',...
    'microstim_state','microstim_start','stim_to_state_end','current_strength','train_duration_ms','pulse_duration_micro_ms',...
    'electrode_depth','impedance_start_kilo_ohms','impedance_end_kilo_ohms','impedance_after_cleaning_kilo_ohms','electrode_used','current_polarity',...
    'abort_code','reward_modulation','reward_selected','reach_hand','difficulty','n_targets','n_nondistractors','n_distractors','stay_condition','stimuli_in_2hemifields'};
default_key_values.simple_selective=repmat({NaN},1,numel(keys.simple_selective));

keys.calcoptions={'runs_as_batches','keep_raw_data','saccade_definition','reach_definition','reach_1st_pos','reach_1st_pos_in','reach_pos_at_state_change',...
    'nsacc_max','sac_ini_t','sac_end_t','sac_min_dur','sac_int_xy','rea_int_xy','correct_offset',...
    'lat_after_micstim','sac_min_amp','sac_max_off','closest_target_radius','downsampling','eyetracker_sample_rate','smoothing_samples','i_sample_rate','correlation_conditions','parameters_to_correlate','correlation_mode','remove_outliers', ...
    'passfilter','difficulty_colors'};
default_key_values.calcoptions={0,0,1,0,0,1,0,5,200,50,0.03,[50 50],[100 100],1,0,2,50,NaN,0,220,12,1000,{'success'},{'lat','dur'},'pearson',0,{},[128 0 0; 120 22 0; 60 60 0; 60 60 60]};

keys.history={'current_structure','current_parameter','current_value','past_structure','past_parameter','past_value','past_keys','n_trials_past','consecutive_trials'};
default_key_values.history={'trial','aborted_state',NaN,'trial','aborted_state',NaN,{},1,0};

keys.plotoptions={'display','summary','create_pdf','append_pdfs', 'close_figures_after_saving','show_trial_ini','show_run_ends','show_trial_number','show_only_one_sac_per_trial','show_trace','show_sliding',...
    'show_sac_2bo','show_sac_1bo','show_sac_obs','show_sac_1ao','additional_description','marker_parameter','fill_parameter','fill_value','folder_to_save'};
default_key_values.plotoptions={1,1,0,1,0,0,0,0,1,0,0,0,0,1,1,'','type','choice',1,''};

keys.evoked={'evoked_ini_velocity','evoked_end_velocity','evoked_stimlocked_latency_min','evoked_stimlocked_latency_max','evoked_amplitude_min','evoked_min_duration',...
    'simulate_evoked', 'sim_stimstart', 'sim_stimdur', 'sim_stimstate', 'sim_stim_to_state_end','consecutive_saccade'};
default_key_values.evoked={30,15,0.03,0.15,2,0.01,0,NaN,NaN,NaN,NaN,1};

keys.inferential={'inferential_on','boxplot_on','multicomparison','scatter_on','inf_structure','inf_field','counting_field'};
default_key_values.inferential={1,0,0,0,'saccades','lat','left_chosen_successful'};
%%%End_keys



all_key_names_cell=struct2cell(keys);
all_key_names=cellstr([all_key_names_cell{:}]);
%% Main loop

temp_cells = varargin;
number_of_batches = numel(temp_cells)/2;
for idx_batch = 1:number_of_batches
    
    % Key assignment for each batch seperately
    % look for subfunction "process_varargin" for more details of how this is achieved
    selected_key_values=[temp_cells{idx_batch*2}];
    fprintf('Batch #%d \n',idx_batch);
    
    %checking the keys
    selected_key_names=selected_key_values((1:round(numel(selected_key_values)/2))*2-1);
    is_valid_key=ismember(cellstr(selected_key_names),all_key_names);
    if ~all(is_valid_key)
        invalid_keynames=selected_key_names(~is_valid_key);
        fprintf('Warning: %s is not a valid keyword \n',invalid_keynames{:});
    end
    
    [keys.mode_val]   = process_varargin(keys.mode,                 default_key_values.mode,        selected_key_values);
    [keys.csel_val]   = process_varargin(keys.complex_selective,    default_key_values.complex_selective,     selected_key_values);
    [keys.ssel_val]   = process_varargin(keys.simple_selective,     default_key_values.simple_selective,     selected_key_values);
    [keys.calc_val]   = process_varargin(keys.calcoptions,          default_key_values.calcoptions,        selected_key_values);
    [keys.hist_val]   = process_varargin(keys.history,              default_key_values.history,     selected_key_values);
    [keys.plot_val]   = process_varargin(keys.plotoptions,          default_key_values.plotoptions,        selected_key_values);
    [keys.evok_val]   = process_varargin(keys.evoked,               default_key_values.evoked,        selected_key_values);
    [keys.infe_val]   = process_varargin(keys.inferential,          default_key_values.inferential, selected_key_values);
    
    if keys.mode_val.error_analysis_mode==1
        keys.ssel_val.success=NaN;
        keys.calc_val.reach_1st_pos=1;
        keys.calc_val.saccade_2bo=1;
        keys.calc_val.saccade_1bo=1;
        keys.calc_val.saccade_obs=1;
        keys.calc_val.correct_offset=0;
        keys.plot_val.show_trial_number=1;
        keys.plot_val.show_trace=1;
        keys.plot_val.show_sliding=1;
    end
    
    % for empty datasets in this batch, take the first dataset (to simplify input)
    if ~isempty(temp_cells{idx_batch*2-1}) && size(temp_cells{idx_batch*2-1},2)>1
        batch_filenames=format_filelist(temp_cells{idx_batch*2-1});
    elseif ~isempty(temp_cells{idx_batch*2-1}) 
        batch_filenames=temp_cells{idx_batch*2-1};
    else
        batch_filenames=format_filelist({'',[]});%format_filelist(temp_cells{1});
    end
    % Main computation is done in this subfunction:
    % "monkeypsych_analyze_runs_preprocessing ->
    if keys.calc_val.runs_as_batches
        out_comp = num2cell(monkeypsych_analyze_runs_preprocessing(batch_filenames,keys));
    else
        out_comp(idx_batch,:) = num2cell(monkeypsych_analyze_runs_preprocessing(batch_filenames,keys));
    end
    if numel(out_comp)==idx_batch && all([out_comp{idx_batch}.emptyflag]==1)
        fprintf('Batch #%d is empty! \n',idx_batch);
    end
    % plot batch summary with plotting function "MA_plot_summary"
    if ~all(keys.plot_val.summary)==0 && keys.plot_val.display==1 %&& numel(out_comp)==idx_batch && ~isempty(out_comp{idx_batch,k}.emptyflag)???
        if ~isnan(keys.mode_val.trial_history_mode) && ~keys.mode_val.trial_history_mode==0
            hist_val=keys.hist_val;
            for k=1:keys.hist_val.n_trials_past
                if ~isempty(out_comp{idx_batch,k}.emptyflag)
                    hist_val.n_trials_past=k;
                    MA_plot_summary([out_comp{idx_batch,k}],keys.plot_val)
                    monkeypsych_plot_trial_history([out_comp{idx_batch,k}.selected.current_hist_values]',[out_comp{idx_batch,k}.selected.past_hist_values]',hist_val,out_comp{idx_batch,k}.rundescriptions);
                end
            end
        elseif ~isempty(out_comp{idx_batch}.emptyflag) && ~keys.calc_val.runs_as_batches %&& numel(out_comp)==idx_batch
            MA_plot_summary([out_comp{idx_batch}],keys.plot_val)
        elseif ~isempty(out_comp{idx_batch}.emptyflag) && keys.calc_val.runs_as_batches %&& numel(out_comp)==idx_batch
            for idx_batch_runs_as_batches=1:numel(out_comp)
                MA_plot_summary([out_comp{idx_batch_runs_as_batches}],keys.plot_val)
            end
        end
    elseif all(keys.plot_val.summary)==0 && keys.plot_val.display==1
        % Missing trial by trial plot... NOT possible !!??
    end
end



%% Inferential part
% boxplot, anova and multicomparison of the variable_to_test(:,idx_batch), which
% contains the values of the fields [out_comp{idx_batch}.inf_structure.inf_field] for
% all batches according to idx_batch.
% Simple scatter plot for the scalar value specified by "counting_field" for each bach
% All plots are selected by corresponding keys (see above)

if keys.infe_val.inferential_on==1
    % defining maximum trials per batch (struct_maxs)
    struct_maxs=zeros(1,number_of_batches);
    for idx_batch = 1:number_of_batches;
        if isfield(out_comp{idx_batch},'task')
            struct_maxs(idx_batch) = numel(out_comp{idx_batch}.task);
        else
            struct_maxs(idx_batch) = 0;
        end
    end
    struct_max = max(struct_maxs);
    
    % defining the variable to test
    variable_to_test=NaN(struct_max,number_of_batches);
    for idx_batch = 1:number_of_batches
        if isfield(out_comp{idx_batch},keys.infe_val.inf_structure)
            structure_to_test=(out_comp{idx_batch}.(keys.infe_val.inf_structure));
            variable_to_test(1:numel(structure_to_test),idx_batch) = [structure_to_test.(keys.infe_val.inf_field)]';
        else
            variable_to_test(:,idx_batch) = NaN;
        end
    end
    if keys.infe_val.boxplot_on==1
        figure
        boxplot(variable_to_test)
    end
    counter=NaN(1,number_of_batches);
    
    for idx_batch = 1:number_of_batches
        if isfield(out_comp{idx_batch},'counts') && isfield(out_comp{idx_batch}.counts, keys.infe_val.counting_field)
            counter(idx_batch) = out_comp{idx_batch}.counts.(keys.infe_val.counting_field);
        else
            counter(idx_batch) = 0;
        end
    end
    if keys.infe_val.scatter_on==1
        figure
        plot(counter,'o');
    end
    if number_of_batches > 1
        if keys.infe_val.multicomparison==1
            [p,t,st] = anova1(variable_to_test,[],'on');
            [c,m,h,nms] = multcompare(st,'display','on');
        end
    end
else
    variable_to_test=NaN;
    counter=NaN;
end

end

function out = monkeypsych_analyze_runs_preprocessing(batch_filenames,keys)
%% Preprocessing
if keys.mode_val.trial_history_mode==1
    n_columns=keys.hist_val.n_trials_past;
else
    n_columns=1;
end

for num_file=1:numel(batch_filenames)
    %t.Startf=GetSecs;
    filename=batch_filenames{num_file};
    disp(filename)
    keys_current=keys;
    keys_current.num_file   = num_file;
    if exist(filename,'file')
        load (filename)
        [trial.runname]=deal(filename(end-19:end-4));
        keys_current.setup=SETTINGS.setup;
        TDT_streams=fieldnames(trial)';        
        TDT_streams=TDT_streams(~cellfun(@isempty,strfind(TDT_streams,'TDT_')) & cellfun(@isempty,strfind(TDT_streams,'samplingrate')));
        TDT_streams=TDT_streams(~ismember(TDT_streams,{'TDT_RWRD','TDT_block','TDT_eNeu_t','TDT_eNeu_w','TDT_run','TDT_senL','TDT_senR','TDT_session',...
                                                       'TDT_stat','TDT_state_onsets','TDT_states','TDT_time','TDT_toxy','TDT_trial'}));
        keys_current.TDT_streams=TDT_streams;
        [trial.TDT_streams_tStart]=deal(0);
        if exist('First_trial_INI','var')
            for FN=TDT_streams
                FNT=FN{1};
                FNF=FNT(5:end);
                if any(ismember(fieldnames(First_trial_INI),FNF))
                trial(1).(FNT)=[First_trial_INI.(FNF) trial(1).(FNT)]; % append before first trial
                trial(1).TDT_streams_tStart = -1*size(First_trial_INI.(FNF),2)/trial(1).([FNT '_samplingrate']);
                end
            end
        end
    else
        disp('File does not exist')
        filename='                    ';
        [trial.runname]=deal(filename(end-19:end-4));
        keys_current.setup=NaN;
        trial=[];
    end
    keys_current.session    = str2double([filename(end-16:end-13),filename(end-11:end-10),filename(end-8:end-7)]);
    keys_current.run        = str2double(filename(end-5:end-4));
    
    if any([keys_current.mode_val.evaluate_evoked, keys_current.mode_val.after_evoked_saccades, keys_current.mode_val.without_evoked_saccades])
        % If any of the evoked mode flags is on, calculate evoked saccades
        with_or_without_evoked=any(keys_current.mode_val.evaluate_evoked, keys_current.mode_val.after_evoked_saccades);
        keys_evoked=keys_current;
        keys_evoked.calc_val.sac_ini_t=keys_current.evok_val.evoked_ini_velocity;
        keys_evoked.calc_val.sac_end_t=keys_current.evok_val.evoked_end_velocity;
        keys_evoked.calc_val.sac_min_dur=keys_evoked.evok_val.evoked_min_duration;
        keys_evoked.calc_val.lat_after_micstim=1;
        [out_a,~] = monkeypsych_analyze_calculation(trial,keys_evoked);
        if out_a.emptyflag==0
            sac=out_a.saccades;
            bin=out_a.binary;
            trialset=[out_a.selected([sac.evoked]==with_or_without_evoked | [bin.microstim]==0).trials];
            type_key=keys_current.ssel_val.type;
        else %??
            trialset=NaN;
            type_key=0;
        end
        clear out_a;
        if keys_current.mode_val.evaluate_evoked==1
            keys_current=keys_evoked;
            keys_current.plot_val.additional_description=' evoked saccades';
        elseif keys_current.mode_val.after_evoked_saccades
            keys_current.plot_val.additional_description=' after evoked saccades';
        elseif keys_current.mode_val.without_evoked_saccades
            keys_current.plot_val.additional_description=' without evoked saccades';
        end
        keys_current.ssel_val.type=type_key;
        keys_current.csel_val.trial_set=trialset;
    end
    [out_file(num_file,1),selected_trials] = monkeypsych_analyze_calculation(trial,keys_current);
    if keys_current.plot_val.display==1 && keys_current.plot_val.summary==0 && out_file(num_file,1).emptyflag==0;
        keys_current.plot_val.sac_ini_t=keys_current.calc_val.sac_ini_t;
        keys_current.plot_val.sac_end_t=keys_current.calc_val.sac_end_t;
        keys_current.plot_val.filename=batch_filenames{num_file}(end-19:end-4);
        monkeypsych_plot_trial(out_file(num_file,1),selected_trials,keys_current.plot_val,filename)
    end
    if ~isnan(keys_current.mode_val.trial_history_mode) && ~keys_current.mode_val.trial_history_mode==0 %%% in progress
        
        keys_bo=keys_current;
        [keys_bo.mode_val]   = process_varargin(keys.mode,                 struct2cell(keys_current.mode_val),   keys_current.hist_val.past_keys);
        [keys_bo.csel_val]   = process_varargin(keys.complex_selective,    struct2cell(keys_current.csel_val),   keys_current.hist_val.past_keys);
        [keys_bo.ssel_val]   = process_varargin(keys.simple_selective,     struct2cell(keys_current.ssel_val),   keys_current.hist_val.past_keys);
        [keys_bo.calc_val]   = process_varargin(keys.calcoptions,          struct2cell(keys_current.calc_val),   keys_current.hist_val.past_keys);
        [keys_bo.hist_val]   = process_varargin(keys.history,              struct2cell(keys_current.hist_val),   keys_current.hist_val.past_keys);
        [keys_bo.plot_val]   = process_varargin(keys.plotoptions,          struct2cell(keys_current.plot_val),   keys_current.hist_val.past_keys);
        [keys_bo.evok_val]   = process_varargin(keys.evoked,               struct2cell(keys_current.evok_val),   keys_current.hist_val.past_keys);
        [keys_bo.infe_val]   = process_varargin(keys.inferential,          struct2cell(keys_current.infe_val),   keys_current.hist_val.past_keys);
        
        out_current = out_file(num_file,1);
        out_past    = monkeypsych_analyze_calculation(trial,keys_bo);
        all_past_selected_trials    = [out_past.selected.trials];
        all_current_selected_trials = [out_current.selected.trials];
        
        for k=1:n_columns
            
            if ~keys_current.hist_val.consecutive_trials || k==1
                selected_past_trials{k}    = intersect(all_past_selected_trials,all_current_selected_trials -k);
                selected_current_trials{k} = intersect(all_current_selected_trials,selected_past_trials{k} +k);
            elseif keys_current.hist_val.consecutive_trials && k>1
                selected_past_trials{k}    = intersect(all_past_selected_trials,selected_past_trials{k-1}-1);
                selected_current_trials{k} = intersect(all_current_selected_trials,selected_past_trials{k} +k);
            end
            
            selected_past_trials_bin{k}     = ismember(all_past_selected_trials,selected_past_trials{k});
            selected_current_trials_bin{k}  = ismember(all_current_selected_trials,selected_current_trials{k});
            
            %Go through all substructures...
            
            out_file(num_file,k).emptyflag  = out_current.emptyflag;
            out_file(num_file,k).binary     = out_current.binary    (selected_current_trials_bin{k});
            out_file(num_file,k).reaches    = out_current.reaches   (selected_current_trials_bin{k});
            out_file(num_file,k).saccades   = out_current.saccades  (selected_current_trials_bin{k});
            out_file(num_file,k).physiology = out_current.physiology(selected_current_trials_bin{k});
            out_file(num_file,k).task       = out_current.task      (selected_current_trials_bin{k});
            out_file(num_file,k).states     = out_current.states    (selected_current_trials_bin{k});
            out_file(num_file,k).timing     = out_current.timing    (selected_current_trials_bin{k});
            out_file(num_file,k).raw        = out_current.raw       (selected_current_trials_bin{k});
            
            
            out_file(num_file,k).correlation= out_current.correlation;
            out_file(num_file,k).statistic  = out_current.statistic;
            out_file(num_file,k).selected   = out_current.selected(selected_current_trials_bin{k});
            if ~isempty(out_file(num_file,k).selected)
                [out_file(num_file,k).selected.past_hist_values]       = out_past.selected(selected_past_trials_bin{k}).past_hist_values_tmp;
            end
            if keys_current.plot_val.display==1 && keys_current.plot_val.summary==0
                %monkeypsych_plot_trial_history([out_file(num_file,k).selected.current_hist_values]',[out_file(num_file,k).selected.past_hist_values]',keys_current.hist_val);
            end
        end
    end
    for k=1:n_columns
        
        out_file(num_file,k).rundescriptions.runname    = filename(end-19:end-4);
        out_file(num_file,k).rundescriptions.monkeyname = filename(end-19:end-17);
        out_file(num_file,k).rundescriptions.session    = keys_current.session;
        out_file(num_file,k).rundescriptions.run        = keys_current.run;
        
        out_file(num_file,k).rundescriptions.new_run    = num_file;
        if ~isfield(out_file(num_file,k),'task')
            out_file(num_file,k).task=[];
        end
        if num_file == 1
            out_file(num_file,k).rundescriptions.run_ends           = numel(out_file(num_file,k).task);
        else
            out_file(num_file,k).rundescriptions.run_ends           = numel(out_file(num_file,k).task) + out_file(num_file-1,k).rundescriptions.run_ends;
        end
        if num_file > 1 && strcmp (out_file(num_file,k).rundescriptions.monkeyname,out_file(num_file-1,k).rundescriptions.monkeyname)~=1
            out_file(num_file,k).rundescriptions.monkey_ends        = out_file(num_file-1,k).rundescriptions.run_ends;
        else
            out_file(num_file,k).rundescriptions.monkey_ends        = NaN;
        end
        if num_file > 1 && strcmp (out_file(num_file,k).rundescriptions.session,out_file(num_file-1,k).rundescriptions.session)~=1
            out_file(num_file,k).rundescriptions.session_ends       = out_file(num_file-1,k).rundescriptions.run_ends;
        else
            out_file(num_file,k).rundescriptions.session_ends       = NaN;
        end
        if keys.calc_val.runs_as_batches
            counts = counting_binary(out_file(num_file,k).binary);
            out_file(num_file,k).counts=counts;
            out_file(num_file,k).keys=keys;
        end
    end
end

if keys.calc_val.runs_as_batches
    out=out_file;
else
    out_file=rmfield(out_file,{'statistic','correlation'});
    out=concetenate_structure_array(out_file);
    [out.statistic, out.correlation] = saccade_reach_correlation(keys,out.reaches,out.saccades,out.task,out.selected,out.binary);
    if all([out.emptyflag]==1)
        return
    end
    for k=1:n_columns
        counts = counting_binary(out(k).binary);
        out(k).counts= counts;
    end
    [out.keys]=deal(keys);
end
end

function [out,trial] = monkeypsych_analyze_calculation(trial,keys)

%% Key renaming for better handling
selsimp_keys  = keys.simple_selective;
selcomp       = keys.csel_val;
selsimp       = keys.ssel_val;
calcoptions   = keys.calc_val;
n_s_sel_keys  = numel(fieldnames(selsimp));
n_c_sel_keys  = numel(fieldnames(selcomp));

%% New function for global MA_STATES and Plot_parameter settings MA_load_globals
global MA_STATES
MA_load_globals

if numel(trial)==0
    disp('no trials in this file')
elseif isempty(trial(end).aborted_state)
    disp('last trial is empty, consider running MPA_clean_data');
end

%% Preallocation part one (for discrimination part)
State_counter           =1:numel(MA_STATES.ALL);
total_number_of_trials  =numel(trial);
all_trials              = 1:total_number_of_trials;
idx.selection           =false(total_number_of_trials,1);   %the logical trial selector
effector_sr             =NaN(total_number_of_trials,2);     %stores information about expected saccades/reaches in this trial due to effector
effector_fix_eh         =NaN(total_number_of_trials,2);     %stores information about expected hand/eye fixation in this trial due to effector
a_i_t_e                 =NaN(total_number_of_trials,1);     %stores information about all intended eye  targets as calculated,     later s_i_t_e (selected intended target eye)
a_i_t_h                 =NaN(total_number_of_trials,1);     %stores information about all intended hand targets as calculated,     later s_i_t_h (selected intended target hand)
a_n_t_e                 =NaN(total_number_of_trials,1);     %stores information about all NOT indended eye  targets as calculated, later n_i_t_e (not intended target eye)
a_n_t_h                 =NaN(total_number_of_trials,1);     %stores information about all NOT intended hand targets as calculated, later n_i_t_h (not intended target hand)
disc_var_s              =NaN(1,n_s_sel_keys);               %for discriminating trial selection due to selection keys
disc_var_c              =NaN(1,n_c_sel_keys-1);               %for discriminating trial selection due to complex keys
empty_cell              =repmat({''},1,total_number_of_trials);

states=struct('all_states', empty_cell, 'state_2bo', empty_cell, 'state_1bo', empty_cell, 'state_obs', empty_cell, 'state_1ao', empty_cell, 'state_abo', empty_cell,...
    'state_sac', empty_cell, 'state_inf', empty_cell,'start_2bo', empty_cell,'start_1bo', empty_cell,'start_obs', empty_cell,'start_mis', empty_cell,'start_sac', empty_cell,'start_1ao', empty_cell,'start_end', empty_cell,...
    'MP_states', empty_cell,'MP_states_onset', empty_cell,'TDT_states', empty_cell,'TDT_state_onsets', empty_cell,'run_onset_time',empty_cell,'trial_onset_time', empty_cell,'state2_onset_time', empty_cell);

%% Microstim parameter definitions
% stim_to_state_end redefinition from trial (instead of task !)
if isfield(trial,'microstim')
    stim_to_state_end=[trial.microstim_end]-[trial.microstim_start];
    stim_to_state_end_cell=num2cell(round(stim_to_state_end.*100)./100);
    [trial.stim_to_state_end]=stim_to_state_end_cell{:};
end

% simulate_microstim (for nostim only)
%[trial.stim_to_state_end]=deal(NaN); %% ??
if  keys.evok_val.simulate_evoked == 1 %% && isfield(trial(1),'microstim')
    logidx_nostim=~[trial.microstim];
    
    if any(([trial(~logidx_nostim).microstim_start]==keys.evok_val.sim_stimstart | isnan(keys.evok_val.sim_stimstart))...
            & ([trial(~logidx_nostim).microstim_state]==keys.evok_val.sim_stimstate | isnan(keys.evok_val.sim_stimstate))...
            & ([trial(~logidx_nostim).stim_to_state_end]==keys.evok_val.sim_stim_to_state_end | isnan(keys.evok_val.sim_stim_to_state_end)))
        [trial(logidx_nostim).stim_to_state_end]=deal(keys.evok_val.sim_stim_to_state_end);
        [trial(logidx_nostim).microstim_state]=deal(keys.evok_val.sim_stimstate);
        [trial(logidx_nostim).microstim_start]=deal(keys.evok_val.sim_stimstart);
        [trial(logidx_nostim).train_duration_ms]=deal(keys.evok_val.sim_stimdur);
    end
end



%% Index Selection loop (!)
% Use selection keys (and complex keys) to select trial indexes with the
% logical vector idx.selection to use for analysis. Observed state (for
% reaches and saccades definition) and chosen target calculation implemented
% (taking means of positions in observed state in doubtful cases)

for inu = 1:total_number_of_trials
    
    %% adding non-existent fields (guaranteeing backward compatibility)
    if ~isfield(trial(inu).task,'correct_choice_target')
        [trial(inu).task.correct_choice_target]=1;
    end
    
    %% Task effector regulations
    % defining effector_sr (if saccade/reach is required), and
    % effector_fix_eh (if eye/hand fixation is required) depending on the task effector,
    
    switch trial(inu).effector
        case 0
            effector_sr(inu,:)        = [1 0];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [1 0];      % [eye fixation, hand fixation]
        case 1
            effector_sr(inu,:)        = [0 1];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [0 1];      % [eye fixation, hand fixation]
        case 2
            effector_sr(inu,:)        = [1 1];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [1 1];      % [eye fixation, hand fixation]
        case 3
            effector_sr(inu,:)        = [1 0];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [1 1];      % [eye fixation, hand fixation]
        case 4
            effector_sr(inu,:)        = [0 1];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [1 1];      % [eye fixation, hand fixation]
        case 6
            effector_sr(inu,:)        = [0 1];      % [saccade, reach]
            effector_fix_eh(inu,:)    = [1 1];      % [eye fixation, hand fixation]
    end
    
    %% Task type regulations
    % states.state_obs  (State in which reaches and saccades are observed)
    % and states before/after (_2bo/_1bo/_1ao) are defined depending on the task type
    % states.all_states (appearence of states) is defined depending on the task type
    
    switch trial(inu).type
        case 1 %fixation only
            % Note that the initial 0 is not an error , it is necessary to track back two states from the observed (FIX_HOL)!
            states(inu).all_states    = [0 MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.FIX_HOL;
            states(inu).state_inf     = MA_STATES.FIX_ACQ;
        case 2 % direct movement
            states(inu).all_states    = [MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL  MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.TAR_ACQ;
            states(inu).state_inf     = MA_STATES.TAR_ACQ;
        case 2.5 % direct movement with dimmed targets (same states as in memory!)
            states(inu).all_states    = [MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.TAR_ACQ;
            states(inu).state_inf     = MA_STATES.CUE_ON;
        case 3 % memory tasks
            states(inu).all_states    = [MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.TAR_ACQ_INV  MA_STATES.TAR_HOL_INV MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.TAR_ACQ_INV;
            states(inu).state_inf     = MA_STATES.CUE_ON;
        case 4 % delay response
            states(inu).all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.DEL_PER  MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL  MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.TAR_ACQ;
            states(inu).state_inf     = MA_STATES.CUE_ON;
        case 5 % Match-to-sample task
            states(inu).all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.MAT_ACQ  MA_STATES.MAT_HOL  MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.MAT_ACQ;
            states(inu).state_inf     = MA_STATES.CUE_ON;
        case 6 % Match-to-sample task with masked targets
            states(inu).all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER MA_STATES.MAT_ACQ_MSK  MA_STATES.MAT_HOL_MSK  MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.MAT_ACQ_MSK;
            states(inu).state_inf     = MA_STATES.CUE_ON;
       case 9 % Match-to-sample task (difference in rotation) & masked sample
            states(inu).all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MSK_HOL  MA_STATES.MEM_PER...
            MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL  MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
            states(inu).state_obs     = MA_STATES.TAR_ACQ;
            states(inu).state_inf     = MA_STATES.TAR_ACQ;
    end
    
    State_counter_obs        = State_counter(states(inu).all_states==states(inu).state_obs);   % The position of observed state in trial
    states(inu).state_2bo    = states(inu).all_states(State_counter_obs-2);                  % state 2 states before observed
    states(inu).state_1bo    = states(inu).all_states(State_counter_obs-1);                  % state 1 state  before observed
    states(inu).state_1ao    = states(inu).all_states(State_counter_obs+1);                  % state 1 state  after  observed (if not aborted in observed state)
    
    
    
    % stim_to_state_end redefinition from trial (instead of task !)
    
    %     if isfield(trial(inu),'microstim') && trial(inu).microstim==1
    %         trial(inu).time_axis  = trial(inu).tSample_from_time_start - trial(inu).tSample_from_time_start(1);
    %         logidx_microstim=trial(inu).state==trial(inu).microstim_state;
    %         state_microstim_times_from_start=[trial(inu).time_axis(logidx_microstim); NaN; NaN; NaN];
    %         time_diff=state_microstim_times_from_start(2)-state_microstim_times_from_start(3);
    %
    %         microstim_state_dur=max(state_microstim_times_from_start)-min(state_microstim_times_from_start)
    %
    %         stim_to_state_end=round(double((microstim_state_dur-trial(inu).microstim_start)*100))/100
    % %         suc=trial(inu).success
    % %         sta=trial(inu).microstim_state
    % %         trial(inu).microstim_end
    % %         trial(inu).microstim_end-trial(inu).microstim_start
    % %         trial(inu).stim_to_state_end=stim_to_state_end;
    %     else
    %         trial(inu).stim_to_state_end=NaN;
    %     end
    
    %% Chosen target calculation
    % a_i_t_e and a_i_t_h are defined for current trial :
    % According to target_selected, if this value is valid. Note that a target is selected once it is acquired (except for Match to sample so far)
    % If target_selected is not defined, but the trial was not aborted before the state when the position information was available (state_inf) or the observed state (state_obs), for instructed and choice respectively,
    %   a_i_t_e and a_i_t_h equal 1 for instructed trials,
    %   a_i_t_e and a_i_t_h will be defined by the median(!) eye/hand  position (for saccades/reaches) in the aborted state (!) for choice trials,
    % Else, a_i_t_e and a_i_t_h are NaN
    % If it was a fixation task (type==1), a_i_t_e and a_i_t_h are NaN regardless of choice/instructed
    % a_n_t_e and a_n_t_h are defined for current trial only if there was choice and a chosen target, else they are NaN
    
    
    if isempty(trial(inu).target_selected) || sum(trial(inu).target_selected == [0 0]);%???
        trial(inu).target_selected=[NaN NaN];
    end
    a_i_t_e(inu)=trial(inu).target_selected(1);
    a_i_t_h(inu)=trial(inu).target_selected(2);
    if trial(inu).aborted_state==MA_STATES.FIX_ACQ % debugging monkeypsych output, because rial(inu).target_selected is not NaN if aborted in acquisition.
        a_i_t_e(inu)=NaN;
        a_i_t_h(inu)=NaN;
    end
    
    if any(isnan(trial(inu).target_selected)) && trial(inu).aborted_state > MA_STATES.FIX_HOL   && ...% !!!
            ~isempty(State_counter(states(inu).all_states==trial(inu).aborted_state)) && ...
            State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==states(inu).state_inf)
        if isnan(trial(inu).target_selected(1)) && effector_sr(inu,1)
            if ~trial(inu).choice %&& State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==states(inu).state_inf)
                a_i_t_e(inu)=1;
            elseif trial(inu).choice %&& ~isempty(State_counter(states(inu).all_states==trial(inu).aborted_state)) && State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==states(inu).state_obs)
                median_x        = nanmedian(trial(inu).x_eye(trial(inu).state==trial(inu).aborted_state));
                median_y        = nanmedian(trial(inu).y_eye(trial(inu).state==trial(inu).aborted_state));
                target_pos      = {trial(inu).eye.tar.pos};
                choice_window   = sqrt(sum(calcoptions.sac_int_xy.^2));
                median_dist=NaN(size(target_pos));
                for tar=1:numel(target_pos)
                    median_dist(tar)=sqrt(sum((target_pos{tar}(1:2)-[median_x median_y]).^2)) - choice_window;
                end
                if any(median_dist<0)
                    a_i_t_e(inu)=find(median_dist==min(median_dist),1);
                end
                %                 if sum((target_pos{2}(1:2)-[median_x median_y]).^2) >= sum((target_pos{1}(1:2)-[median_x median_y]).^2) && all(target_pos{1}(1:2)-[median_x median_y] < choice_window)
                %                     a_i_t_e(inu)=1;
                %                 elseif sum((target_pos{2}(1:2)-[median_x median_y]).^2) <= sum((target_pos{1}(1:2)-[median_x median_y]).^2) && all(target_pos{2}(1:2)-[median_x median_y] < choice_window)
                %                     a_i_t_e(inu)=2;
                %                 end
            end
        end
        if isnan(trial(inu).target_selected(2)) && effector_sr(inu,2)
            if ~trial(inu).choice %&& State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==states(inu).state_inf)
                a_i_t_h(inu)=1;
            elseif trial(inu).choice %&& ~isempty(State_counter(states(inu).all_states==trial(inu).aborted_state)) && State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==states(inu).state_obs)
                median_x        = nanmedian(trial(inu).x_hnd(trial(inu).state==trial(inu).aborted_state));
                median_y        = nanmedian(trial(inu).y_hnd(trial(inu).state==trial(inu).aborted_state));
                target_pos      = {trial(inu).hnd.tar.pos};
                choice_window   = sqrt(sum(calcoptions.rea_int_xy.^2));
                median_dist=NaN(size(target_pos));
                for tar=1:numel(target_pos)
                    median_dist(tar)=sqrt(sum((target_pos{tar}(1:2)-[median_x median_y]).^2)) - choice_window;
                end
                if any(median_dist<0)
                    a_i_t_h(inu)=find(median_dist==min(median_dist),1);
                end
            end
        end
    end
    if trial(inu).type==1   %because a_i_t_e is really only used for targets, it would cause strange outputs for fixation trials, where targets are not task relevant
        a_i_t_e(inu)=NaN;
        a_i_t_h(inu)=NaN;
    end
    if trial(inu).choice   %so far, a_n_t_e only makes sense for two targets!
        a_n_t_e(inu) = mod(a_i_t_e(inu),2)+1;
        a_n_t_h(inu) = mod(a_i_t_h(inu),2)+1;
    end
    
    %% Definition of new outputs for multiple distractors
    if effector_sr(inu,1)
      effector_field='eye';
    else
      effector_field='hnd';
    end
    
    % difficulty
    stimulus_colors=vertcat(trial(inu).task.(effector_field).tar.color_dim);
    clear diff_idx
    for sc=1:size(stimulus_colors,1)
        [~,diff_idx(sc)]=min(sum(abs(bsxfun(@minus, calcoptions.difficulty_colors,stimulus_colors(sc,:))),2));
    end
    if any(diff_idx~=1 & diff_idx<=size(calcoptions.difficulty_colors,1)/2)
        trial(inu).difficulty=2;
    elseif any(diff_idx~=size(calcoptions.difficulty_colors,1) & diff_idx>size(calcoptions.difficulty_colors,1)/2)
        trial(inu).difficulty=1;
    else
        trial(inu).difficulty=0;
    end
    
    % stimulus type
    tarpos=vertcat(trial(inu).(effector_field).tar.pos);
    fixpos=trial(inu).(effector_field).fix(1).pos;
    
    trial(inu).n_targets=numel(trial(inu).(effector_field).tar);
    trial(inu).stay_condition=any(ismember(trial(inu).task.correct_choice_target,find(sum(abs(bsxfun(@minus, tarpos(:,1:2),fixpos(:,1:2))),2)==0)));
    trial(inu).n_nondistractors=numel(trial(inu).task.correct_choice_target)-trial(inu).stay_condition;
    trial(inu).n_distractors=trial(inu).n_targets-trial(inu).n_nondistractors;
    
    % 1 vs 2 hemifields 
     trial(inu).stimuli_in_2hemifields = any(tarpos(:,1)-fixpos(:,1)>0) && any(tarpos(:,1)-fixpos(:,1)<0);
    
    
    %% Selection of trials according to selection keys
    % Selection keys are compared to the current trial's task conditions,
    % discrimination variable vector for current trial indexed by key_ind is
    % set to true/false for all selection keys according to matching/not matching
    % If corresponding selection key is empty or NaN, discrimination variable
    % is defined as true, even if the condition is not specified for
    % current trial, i.e. the selected field does not exist (!).
    % If the field does not exist, but the corresponding selection key is
    % specified, the discrimination variable is defined as false (!).
    for key_ind=1:n_s_sel_keys
        if isnan (selsimp.(selsimp_keys{key_ind}))
            disc_var_s(key_ind)=true;
        elseif isfield(trial(inu),selsimp_keys{key_ind}) && ~ischar(trial(inu).(selsimp_keys{key_ind}))
            disc_var_s(key_ind)=selsimp.(selsimp_keys{key_ind})==trial(inu).(selsimp_keys{key_ind});
        elseif isfield(trial(inu),selsimp_keys{key_ind}) && ischar(trial(inu).(selsimp_keys{key_ind}))
            disc_var_s(key_ind)=strcmp(selsimp.(selsimp_keys{key_ind}),trial(inu).(selsimp_keys{key_ind}));
            %         elseif isfield(trial(inu).task,selsimp_keys{key_ind}) && ~isstruct(trial(inu).task.(selsimp_keys{key_ind}))
            %             disc_var_s(key_ind)=selsimp.(selsimp_keys{key_ind})==trial(inu).task.(selsimp_keys{key_ind});
        elseif ~isfield(trial(inu),selsimp_keys{key_ind}) && selsimp.(selsimp_keys{key_ind}) %%% for not existing fields, but corresponding keys
            disc_var_s(key_ind)=false;
        end
    end
    
    
    %% tricky bug avoiding part !!!
    if isfield(trial,'task') && isfield(trial(inu).task,'reach_hand') && numel(trial(inu).task.reach_hand) ~= numel(trial(inu).reach_hand)
        trial(inu).reach_hand=NaN;
    end
    
    %% Complex selection keys
    % So far, position, aborted_state, and reach_hand selection need more complex discrimination
    % Position selection:
    % Fixation and target positions can be selected seperately
    % for targets and fixation targets (fix_x/pos_x f.e.), multiple position selections
    % by using vectors for pos_x/pos_y are allowed. If both are not NaN or
    % empty, only positions matching in X AND Y are selected. Trials for
    % which there is no chosen target defined (f.e. choice trials aborted
    % before observed state) are excluded with position selection (!)
    
    disc_var_c(1)=true;
    if ~isnan(selcomp.fix_range_x(1)) && effector_sr(inu,1) && ~isnan(a_i_t_e(inu))
        target_distance_x=trial(inu).eye.fix.pos(1);
        target_distance_y=trial(inu).eye.fix.pos(2);
        disc_var_c(1)= disc_var_c(1) && any(target_distance_x>=selcomp.fix_range_x(:,1) & target_distance_x<=selcomp.fix_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.fix_range_y(:,1) & target_distance_y<=selcomp.fix_range_y(:,2));
    elseif ~isnan(selcomp.fix_range_x(1)) && effector_sr(inu,1) && isnan(a_i_t_e(inu))
        disc_var_c(1)=false;
    end
    if ~isnan(selcomp.fix_range_x(1)) && effector_sr(inu,2) && ~isnan(a_i_t_h(inu))
        target_distance_x=trial(inu).hnd.fix.pos(1);
        target_distance_y=trial(inu).hnd.fix.pos(2);
        disc_var_c(1)= disc_var_c(1) && any(target_distance_x>=selcomp.fix_range_x(:,1) & target_distance_x<=selcomp.fix_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.fix_range_y(:,1) & target_distance_y<=selcomp.fix_range_y(:,2));
    elseif ~isnan(selcomp.fix_range_x(1)) && effector_sr(inu,2) && isnan(a_i_t_h(inu))
        disc_var_c(1)=false;
    end
    disc_var_c(2)=disc_var_c(1);
    
    disc_var_c(3)=true;
    if ~isnan(selcomp.cue_range_x(1)) && effector_sr(inu,1) && ~isnan(a_i_t_e(inu))
        target_distance_x=trial(inu).eye.cue(a_i_t_e(inu)).pos(1)-trial(inu).eye.fix.pos(1);
        target_distance_y=trial(inu).eye.cue(a_i_t_e(inu)).pos(2)-trial(inu).eye.fix.pos(2);
        disc_var_c(3)= disc_var_c(3) && any(target_distance_x>=selcomp.cue_range_x(:,1) & target_distance_x<=selcomp.cue_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.cue_range_y(:,1) & target_distance_y<=selcomp.cue_range_y(:,2));
    elseif ~isnan(selcomp.cue_range_x(1)) && effector_sr(inu,1) && isnan(a_i_t_e(inu))
        disc_var_c(3)=false;
    end
    if ~isnan(selcomp.cue_range_x(1)) && effector_sr(inu,2) && ~isnan(a_i_t_h(inu))
        target_distance_x=trial(inu).hnd.cue(a_i_t_h(inu)).pos(1)-trial(inu).hnd.fix.pos(1);
        target_distance_y=trial(inu).hnd.cue(a_i_t_h(inu)).pos(2)-trial(inu).hnd.fix.pos(2);
        disc_var_c(3)= disc_var_c(3) && any(target_distance_x>=selcomp.cue_range_x(:,1) & target_distance_x<=selcomp.cue_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.cue_range_y(:,1) & target_distance_y<=selcomp.cue_range_y(:,2));
    elseif ~isnan(selcomp.cue_range_x(1)) && effector_sr(inu,2) && isnan(a_i_t_h(inu))
        disc_var_c(3)=false;
    end
    disc_var_c(4)=disc_var_c(3);
    
    disc_var_c(5)=true;
    if ~isnan(selcomp.tar_range_x(1)) && effector_sr(inu,1) && ~isnan(a_i_t_e(inu))
        target_distance_x=trial(inu).eye.tar(a_i_t_e(inu)).pos(1)-trial(inu).eye.fix.pos(1);
        target_distance_y=trial(inu).eye.tar(a_i_t_e(inu)).pos(2)-trial(inu).eye.fix.pos(2);
        disc_var_c(5)= disc_var_c(5) && any(target_distance_x>=selcomp.tar_range_x(:,1) & target_distance_x<=selcomp.tar_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.tar_range_y(:,1) & target_distance_y<=selcomp.tar_range_y(:,2));
    elseif ~isnan(selcomp.tar_range_x(1)) && effector_sr(inu,1) && isnan(a_i_t_e(inu))
        disc_var_c(5)=false;
    end
    if ~isnan(selcomp.tar_range_x(1)) && effector_sr(inu,2) && ~isnan(a_i_t_h(inu))
        target_distance_x=trial(inu).hnd.tar(a_i_t_h(inu)).pos(1)-trial(inu).hnd.fix.pos(1);
        target_distance_y=trial(inu).hnd.tar(a_i_t_h(inu)).pos(2)-trial(inu).hnd.fix.pos(2);
        disc_var_c(5)= disc_var_c(5) && any(target_distance_x>=selcomp.tar_range_x(:,1) & target_distance_x<=selcomp.tar_range_x(:,2)) && ...
            any(target_distance_y>=selcomp.tar_range_y(:,1) & target_distance_y<=selcomp.tar_range_y(:,2));
    elseif ~isnan(selcomp.tar_range_x(1)) && effector_sr(inu,2) && isnan(a_i_t_h(inu))
        disc_var_c(5)=false;
    end
    disc_var_c(6)=disc_var_c(5);
    
    
    % Aborted state selection:
    % If the keyvalue for aborted_state equals -1, only successful trials are
    % selected, if it is positive, all trials that are aborted AFTER this state
    % are selected
    
    if isempty (selcomp.aborted_state) || isnan (selcomp.aborted_state)
        disc_var_c(7)=true;
    elseif selcomp.aborted_state==-1
        disc_var_c(7)=trial(inu).aborted_state==selcomp.aborted_state;
    elseif selcomp.aborted_state>=0
        disc_var_c(7)=State_counter(states(inu).all_states==trial(inu).aborted_state) >= State_counter(states(inu).all_states==selcomp.aborted_state);
        %disc_var_c(7)=trial(inu).aborted_state>=selcomp.aborted_state;
    end
    
    % demanded hand selection
    % Trial.reach_hand defines the chosen hand, not the demanded hand, so
    % for hand choice (task.reach_hand==3) you would always have to use the
    % demanded hand option
    if isempty (selcomp.demanded_hand) || isnan (selcomp.demanded_hand)
        disc_var_c(8)=true;
    elseif isfield(trial(inu).task,'reach_hand')
        disc_var_c(8)=selcomp.demanded_hand==trial(inu).task.reach_hand;
    end
    
    % maximum radius selection (for excluding calibration trials)
    if isempty(selcomp.max_radius) || isnan(selcomp.max_radius)
        disc_var_c(9)=true;
    else
        if effector_fix_eh(inu,1)
            disc_var_c(9)    =      trial(inu).eye.fix.pos(4)<=selcomp.max_radius && trial(inu).eye.tar(1).pos(4)<=selcomp.max_radius;
        elseif effector_fix_eh(inu,2)
            disc_var_c(9)    =      trial(inu).hnd.fix.pos(4)<=selcomp.max_radius && trial(inu).hnd.tar(1).pos(4)<=selcomp.max_radius;
        elseif effector_fix_eh(inu,1) && effector_fix_eh(inu,2)
            disc_var_c(9)   =      trial(inu).hnd.fix.pos(4)<=selcomp.max_radius && trial(inu).hnd.tar(1).pos(4)<=selcomp.max_radius &&...
                trial(inu).eye.fix.pos(4)<=selcomp.max_radius && trial(inu).eye.tar(1).pos(4)<=selcomp.max_radius;
        else
            disp('max_radius not valid');
        end
    end
    
    % Actual discrimination
    if  all(disc_var_s) && all(disc_var_c) %Check if all discrimination variables are true
        idx.selection(inu)=true;           %If yes, set current logical selection index to true
    end
end

%% Trial set selection and fast exit if no trials selected:
% This last selection step is done outside selection loop and excludes all
% trial indexes that are not selected in trial_set from the previous
% selected trials

if sum(idx.selection)==0 || isempty(selcomp.trial_set) || (~any(isnan(selcomp.trial_set)) && isempty(intersect(all_trials(idx.selection), selcomp.trial_set)))
    disp('This subset does not exist')
    trial=[];
    emptyflag=1;
    trials_cell=cell(1,0);
    selected=struct('trials',trials_cell','past_hist_values_tmp',trials_cell','current_hist_values',trials_cell','past_hist_values',trials_cell','num_file',trials_cell',...
        'session',trials_cell','run',trials_cell','setup',trials_cell','run_start_time',trials_cell','run_end_time',trials_cell');
    states=struct('all_states', trials_cell', 'state_2bo', trials_cell', 'state_1bo', trials_cell', 'state_obs', trials_cell', 'state_1ao', trials_cell', 'state_abo', trials_cell',...
        'state_sac', trials_cell','start_2bo', trials_cell','start_1bo', trials_cell','start_obs', trials_cell','start_mis', trials_cell','start_sac', trials_cell','start_1ao', trials_cell','start_end', trials_cell',...
    'MP_states', trials_cell','MP_states_onset', trials_cell','TDT_states', trials_cell','TDT_state_onsets', trials_cell','run_onset_time',trials_cell','trial_onset_time', trials_cell','state2_onset_time', trials_cell');
else
    if all(~isnan(selcomp.trial_set))
        trials_cell = num2cell(intersect(all_trials(idx.selection), selcomp.trial_set));  % the vector selected.trials contains only the indexes of selected trials !!!
    else
        trials_cell = num2cell(all_trials(idx.selection));
    end
    selected=struct('trials',trials_cell','past_hist_values_tmp',trials_cell','current_hist_values',trials_cell','past_hist_values',trials_cell','num_file',trials_cell',...
        'session',trials_cell','run',trials_cell','setup',trials_cell','run_start_time',trials_cell','run_end_time',trials_cell');
    states                      = states                    ([selected.trials])';
    emptyflag=0;
end

%% Re-indexing relevant variables according to selection
% Note that even the trial structure itself is re-indexed and therefore reduced

amount_of_selected_trials   = numel(selected);
trial_orig                  = trial; % we need this to be able to concatinate all phys data and get proper trial starts
trial                       = trial                     ([selected.trials]);

s_i_t_e                     = a_i_t_e                   ([selected.trials])';
s_i_t_h                     = a_i_t_h                   ([selected.trials])';
n_i_t_e                     = a_n_t_e                   ([selected.trials])';
n_i_t_h                     = a_n_t_h                   ([selected.trials])';
effector_sr                 = effector_sr               ([selected.trials],:);
effector_fix_eh             = effector_fix_eh           ([selected.trials],:);

%% Create NaN vectors that will hold our output structures
% Note that most of them are NaNs with the length of
% amount_of_selected_trials, allowing to overwrite only rows that relate to
% trials where we have plausible data, and still compare and plot the whole
% arrays fur further calculations


nanpar0=repmat({false},amount_of_selected_trials,1);
nanpar1=repmat({NaN},amount_of_selected_trials,1);
nanpar2=repmat({NaN*(1+1i)},amount_of_selected_trials,1);
nanpar3=repmat({NaN(1,calcoptions.nsacc_max)},amount_of_selected_trials,1);
nanpar4=repmat({NaN(1,calcoptions.nsacc_max).*(1+1i)},amount_of_selected_trials,1);
nanpar5=repmat({NaN(1,3)},amount_of_selected_trials,1);
nanpar6=repmat({{NaN}},amount_of_selected_trials,1);
nanpar7=repmat({{NaN(1,30)}},amount_of_selected_trials,1);

saccades=struct('target_selected', nanpar1,'lat', nanpar1, 'dur', nanpar1, 'velocity', nanpar1, 'num_sac', nanpar1, 'sel_n_sac', nanpar1, 'evoked', nanpar1,'ini_evo',nanpar1,...
    'startpos', nanpar2,'endpos', nanpar2,'accuracy_xy', nanpar2,'accuracy_rad',nanpar2,'tar_pos_closest',nanpar2,...
    'ini_obs',nanpar3,'end_obs',nanpar3,'endpos_obs', nanpar4, 'startpos_obs', nanpar4,'vel_obs', nanpar3,'n_obs', nanpar1,...
    'ini_all',nanpar3,'end_all',nanpar3,'endpos_all', nanpar4, 'startpos_all', nanpar4,'vel_all', nanpar3,...
    'tar_pos', nanpar2,'nct_pos', nanpar2, 'tar_rad', nanpar1, 'tar_siz', nanpar1, 'fix_pos', nanpar2, 'fix_rad', nanpar1, 'fix_siz', nanpar1, 'col_dim', nanpar5, 'col_bri', nanpar5, ...
    'amplitudes_2bo',nanpar3,'amplitudes_1bo',nanpar3,'amplitudes_obs',nanpar3,'amplitudes_1ao',nanpar3,...
    'selected_convexity', nanpar1,'selected_convex_sides', nanpar1,'targets_inspected', nanpar1,'cue_pos', nanpar1,'n_targets', nanpar1,...
    'all_convexities', nanpar1,'all_convex_sides', nanpar1,'all_tar_pos',nanpar2,'all_inspection_durations', nanpar1,'all_inspection_intervals',nanpar1,'exploration_time', nanpar1,'data_loss',nanpar0);

reaches=struct('lat', nanpar1, 'dur', nanpar1, 'demanded_hand', nanpar1, 'reach_hand', nanpar1, 'target_selected', nanpar1,'ini',nanpar1,'end_stat',nanpar1,'ini_fix',nanpar1 ,'dur_fix',nanpar1,...
    'startpos', nanpar2,'endpos', nanpar2,'accuracy_xy', nanpar2,'accuracy_xy_fix', nanpar2,'accuracy_rad',nanpar2,'tar_pos_closest',nanpar2,...
    'tar_pos', nanpar2,'nct_pos', nanpar2, 'tar_rad', nanpar1, 'tar_siz', nanpar1, 'fix_pos', nanpar2, 'fix_rad', nanpar1, 'fix_siz', nanpar1, 'col_dim', nanpar5, 'col_bri', nanpar5,...
    'pos_first_fix',nanpar2,'pos_first', nanpar2, 'pos_inside', nanpar2, 'pos_last', nanpar2,...
    'selected_convexity', nanpar1,'selected_convex_sides', nanpar1,'targets_inspected', nanpar1,'cue_pos', nanpar1,'n_targets', nanpar1,...
    'all_convexities', nanpar1,'all_convex_sides', nanpar1,'all_tar_pos',nanpar2,'all_inspection_durations', nanpar1,'all_inspection_intervals',nanpar1,'exploration_time', nanpar1);

task=struct('type', nanpar1, 'effector', nanpar1,'correct_targets',nanpar1,'abort_code', nanpar1,'reward_modulation',nanpar1,'reward_size',nanpar1,'reward_time',nanpar1,...
    'stim_start', nanpar1, 'stim_end', nanpar1, 'stim_state', nanpar1, 'ini_mis', nanpar1,...
    'stim_to_state_end', nanpar1,'current_strength',nanpar1,'train_duration_ms',nanpar1,'electrode_depth',nanpar1,'impedance_end_kilo_ohms',nanpar1, 'demanded_hand', nanpar1, 'reach_hand', nanpar1,...
    'tar_rew_high', nanpar1,'tar_rew_low', nanpar1,'tar_rew_prob_high', nanpar1,'nct_rew_high', nanpar1,'nct_rew_low', nanpar1,'nct_rew_prob_high', nanpar1, 'target_side', nanpar1);

timing=struct('fix_time_to_acquire_hnd', nanpar1, 'tar_time_to_acquire_hnd', nanpar1,'tar_inv_time_to_acquire_hnd', nanpar1,'fix_time_to_acquire_eye', nanpar1,...
    'tar_inv_time_to_acquire_eye', nanpar1,'tar_time_to_acquire_eye', nanpar1,'fix_time_hold', nanpar1,'fix_time_hold_var', nanpar1,'cue_time_hold', nanpar1,...
    'cue_time_hold_var', nanpar1,'mem_time_hold', nanpar1,'mem_time_hold_var', nanpar1,'del_time_hold', nanpar1,'del_time_hold_var', nanpar1,...
    'tar_inv_time_hold', nanpar1,'tar_inv_time_hold_var', nanpar1,'tar_time_hold', nanpar1,'tar_time_hold_var', nanpar1);

binary=struct('microstim',nanpar1,'success',nanpar1,'completed',nanpar1,'choice',nanpar1,'abort_in_obs',nanpar1,'targets_visible',nanpar1,'reward_modulation',nanpar1,'reward_selected_small',nanpar1,...
    'reward_selected_normal',nanpar1,'reward_selected_large',nanpar1,'rest_sensor_1',nanpar1,'rest_sensor_2',nanpar1,'rest_sensors_on',nanpar1,'saccade_expected',nanpar1,'reach_expected',nanpar1,...
    'temp_reach_hnd_1',nanpar1,'temp_reach_hnd_2',nanpar1,'reach_hnd_1',nanpar1,'reach_hnd_2',nanpar1,'nosaccade',nanpar1,'noreach',nanpar1,'right_hand',nanpar1,'left_hand',nanpar1,...
    'eyetar_l',nanpar1,'eyetar_r',nanpar1,'hndtar_l',nanpar1,'hndtar_r',nanpar1,'sac_within_distance_l',nanpar1,'sac_within_distance_r',nanpar1,'rea_within_distance_l',nanpar1,...
    'rea_within_distance_r',nanpar1,'sac_within_closest_target',nanpar1,'rea_within_closest_target',nanpar1,...
    'sac_us_l',nanpar1,'sac_os_l',nanpar1,'sac_us_r',nanpar1,'sac_os_r',nanpar1,'rea_us_l',nanpar1,'rea_os_l',nanpar1,'rea_us_r',nanpar1,'rea_os_r',nanpar1,...
    'sac_doesntgo',nanpar1,'rea_doesntgo',nanpar1,'sac_inprecise',nanpar1,'rea_inprecise',nanpar1,'sac_nottotarget',nanpar1,'rea_nottotarget',nanpar1);

raw=struct('x_eye',nanpar1,'y_eye',nanpar1,'x_hnd',nanpar1,'y_hnd',nanpar1,'states',nanpar1,'time_axis',nanpar1);

physiology=struct('spike_arrival_times',nanpar6,'spike_waveforms',nanpar7);

% empty outputstructure for empty batches]
if emptyflag==1
    [statistic, correlation] = saccade_reach_correlation(keys,reaches,saccades,task,selected);
    out=struct('keys',struct,'selected',selected,'task',task,'timing',timing,'states',states,'saccades',saccades,'reaches',reaches,'physiology',physiology,'binary',binary,'raw',raw,...
        'counts',struct,'statistic',statistic,'correlation',correlation,'rundescriptions',struct,'emptyflag',emptyflag);
    return;
end

%% Storing file information in the output structure 'selected', and trial task conditions in the output structure 'task'
[selected.num_file]         = deal(keys.num_file);
[selected.session]          = deal(keys.session);
[selected.run]              = deal(keys.run);
[selected.setup]            = deal(keys.setup);
[selected.run_start_time]   = deal(trial(1).timestamp(4)   + trial(1).timestamp(5)/100);
[selected.run_end_time]     = deal(trial(end).timestamp(4) + trial(end).timestamp(5)/100);

[states.state_abo]          = trial.aborted_state;
[states.state_sac,states.start_2bo,states.start_1bo,states.start_obs,states.start_mis,states.start_sac,states.start_1ao,states.start_end]=deal(NaN);

[task.type]                 = trial.type;
[task.effector]             = trial.effector;
[task.reward_modulation]    = trial.reward_modulation;
[task.reward_size]          = trial.reward_selected;
[task.reward_time]          = trial.reward_time;

[task.difficulty]               = trial.difficulty;
[task.stay_condition]           = trial.stay_condition;
[task.n_nondistractors]         = trial.n_nondistractors;
[task.n_distractors]            = trial.n_distractors;
[task.stimuli_in_2hemifields]   = trial.stimuli_in_2hemifields;

if isfield(trial(1), 'abort_code')
    [task.abort_code]           = trial.abort_code;
end

if isfield(trial,'task')
    trialtask=[trial.task];
    [task.demanded_hand] = trialtask.reach_hand;
    [reaches.demanded_hand] = trialtask.reach_hand;
end

if isfield(trial(1), 'current_strength')
    [task.current_strength]          = trial.current_strength;
    [task.train_duration_ms]         = trial.train_duration_ms;
    [task.electrode_depth]           = trial.electrode_depth;
    [task.impedance_end_kilo_ohms]   = trial.impedance_end_kilo_ohms;
end
if isfield(trial(1),'microstim') || keys.evok_val.simulate_evoked == 1
    [task.stim_to_state_end]=trial.stim_to_state_end;
    logidx.microstim     =[trial.microstim]==1;
    [task.stim_start]    =trial.microstim_start;
    [task.stim_end]      =trial.microstim_end;
    [task.stim_state]    =trial.microstim_state;
else
    logidx.microstim     =false(size(trial));
end

unique_eye_target_positions = get_unique_positions_of_trial(trial,'eye');
unique_hnd_target_positions = get_unique_positions_of_trial(trial,'hnd');
if ~isnan(calcoptions.closest_target_radius)
    closest_target_radius=calcoptions.closest_target_radius;
end

%% Saccade and reaches calculation part
for n = 1:amount_of_selected_trials
    if isfield(trial,'TDT_eNeu_t'); 
        physiology(n).spike_arrival_times=trial(n).TDT_eNeu_t;
        physiology(n).spike_waveforms=trial(n).TDT_eNeu_w;
        states(n).TDT_states=trial(n).TDT_states';
        states(n).TDT_state_onsets=trial(n).TDT_state_onsets';
        trialendstateindex=states(n).TDT_states==MA_STATES.SUCCESS | states(n).TDT_states==MA_STATES.ABORT;
        if any(trialendstateindex)
            states(n).start_end =states(n).TDT_state_onsets(trialendstateindex);
        end
    end
    if ~isempty(keys.TDT_streams) && keys.calc_val.keep_raw_data
        nn=selected(n).trials;
        physiology(n).streams_tStart=trial(n).TDT_streams_tStart;
        for FN=keys.TDT_streams
        physiology(n).(FN{:})=trial(n).(FN{:});
        physiology(n).([FN{:} '_SR'])=trial(n).([FN{:} '_samplingrate']);
        SR=unique([trial_orig.([FN{:} '_samplingrate'])]);
        physiology(n).([FN{:} '_t0_from_rec_start'])= size([trial_orig(1:nn).(FN{:})],2)/SR-size(trial_orig(nn).(FN{:}),2)/SR - trial(n).TDT_streams_tStart;    
        end 
    end
    states(n).trial_onset_time=trial(n).tSample_from_time_start(1);
    if isnan(calcoptions.closest_target_radius)
        if all(effector_sr(n,:)) && ~isnan(s_i_t_e(n)) && ~isnan(s_i_t_h(n))
            closest_target_radius(n)=max(trial(n).eye.tar(s_i_t_e(n)).pos(4),trial(n).hnd.tar(s_i_t_h(n)).pos(4));
        elseif effector_sr(n,1) && ~isnan(s_i_t_e(n))
            closest_target_radius(n)=trial(n).eye.tar(s_i_t_e(n)).pos(4);
        elseif effector_sr(n,2) && ~isnan(s_i_t_h(n))
            closest_target_radius(n)=trial(n).hnd.tar(s_i_t_h(n)).pos(4);
        else
            closest_target_radius(n)=0;
        end
    end
    
    % reward modulation part
    if effector_sr(n,1) && ~isnan(s_i_t_e(n)) && s_i_t_e(n)<=2
        task(n).tar_rew_high            =trial(n).eye.tar(s_i_t_e(n)).reward_time(1);
        if numel(trial(n).eye.tar(s_i_t_e(n)).reward_time)>1 %% Bacchus 20210903
        task(n).tar_rew_low             =trial(n).eye.tar(s_i_t_e(n)).reward_time(2);
        end
        task(n).tar_rew_prob_high       =trial(n).eye.tar(s_i_t_e(n)).reward_prob;
        if ~isnan(n_i_t_e(n))
            task(n).nct_rew_high        =trial(n).eye.tar(n_i_t_e(n)).reward_time(1);
            if numel(trial(n).eye.tar(n_i_t_e(n)).reward_time)>1 %% Bacchus 20210903
                task(n).nct_rew_low         =trial(n).eye.tar(n_i_t_e(n)).reward_time(2);
            end
            task(n).nct_rew_prob_high   =trial(n).eye.tar(n_i_t_e(n)).reward_prob;
        end
    elseif effector_sr(n,2) && ~isnan(s_i_t_h(n)) && s_i_t_h(n)<=2
        task(n).tar_rew_high            =trial(n).hnd.tar(s_i_t_h(n)).reward_time(1);
        if numel(trial(n).hnd.tar(s_i_t_h(n)).reward_time)>1
        task(n).tar_rew_low             =trial(n).hnd.tar(s_i_t_h(n)).reward_time(2);
        end
        task(n).tar_rew_prob_high       =trial(n).hnd.tar(s_i_t_h(n)).reward_prob;
        if ~isnan(n_i_t_h(n))
            task(n).nct_rew_high        =trial(n).hnd.tar(n_i_t_h(n)).reward_time(1);
            if numel(trial(n).hnd.tar(n_i_t_h(n)).reward_time)>1 %% Bacchus 20210903
                task(n).nct_rew_low         =trial(n).hnd.tar(n_i_t_h(n)).reward_time(2);
            end
            task(n).nct_rew_prob_high   =trial(n).hnd.tar(n_i_t_h(n)).reward_prob;
        end
    end
    
    % correct choice target part
    task(n).correct_targets=trial(n).task.correct_choice_target;   
    saccades(n).target_selected=trial(n).target_selected(1);
    reaches(n).target_selected=trial(n).target_selected(2);
    
    states(n).run_onset_time=trial(1).timestamp(6)+60*trial(1).timestamp(5)+3600*trial(1).timestamp(4);
    if numel(trial(n).state)>=2
        %% General part
        % trial time axis definition and time for relevant state change
        % calculation: Time when reaching observed state, empty if observed
        % state was not reached.
        % Demanded hand (according to task definition) setting
        
        t_state2=trial(n).tSample_from_time_start(trial(n).state==MA_STATES.FIX_ACQ);      

        states(n).state2_onset_time=t_state2(1);
        trial(n).time_axis  = trial(n).tSample_from_time_start - t_state2(1); % tSample_from_time_start = time from beginning of run
        
        if isempty(trial(n).reach_hand) % still unclear how that can happen ?
            trial(n).reach_hand=NaN;
        end
        reaches(n).reach_hand=trial(n).reach_hand;
        task(n).reach_hand=trial(n).reach_hand;
        
        % offset correction: optional re-alignment to fixation spot per trial
        if calcoptions.correct_offset == 1 && max(trial(n).state)>2
            [trial(n).x_eye,  trial(n).y_eye]    = offset_corrected(trial(n).x_eye, trial(n).y_eye, trial(n).state, MA_STATES.FIX_HOL, trial(n).eye.fix.pos(1) , trial(n).eye.fix.pos(2));
        end
        
        % Downsampling to 'real' eye tracking data (monkeypsych samplingrate is 1kHz, so typically higher than eye tracking samplingrate !)
        % And interpolating eye data to (at calcoptions.i_sample_rate) for smoothing eye positions and velocities to detect saccades, affix '_i' refers to interpolated variables
        if calcoptions.downsampling
            repeats_idx                         = [NaN; diff(trial(n).x_eye)]==0 & [NaN; diff(trial(n).y_eye)]==0;
            start_idx                           = [find(~repeats_idx)];
            end_idx                             = [find([~repeats_idx(2:end)]); numel(repeats_idx)];
            times_passed                        = [trial(n).tSample_from_time_start(end_idx)]-[trial(n).tSample_from_time_start(start_idx)];
            saccades(n).data_loss               = any(times_passed>(4/calcoptions.eyetracker_sample_rate));
            real_idx                            = [unique([start_idx ;end_idx(end)]);];
            trial(n).time_axis_i                = ceil(trial(n).time_axis(1)*calcoptions.i_sample_rate)/calcoptions.i_sample_rate : 1/calcoptions.i_sample_rate : trial(n).time_axis(real_idx(end));
            
            %probably this line can go now
            if numel(real_idx)<2
                real_idx=[1,numel(trial(n).x_eye)];
            end
            
            trial(n).x_eye_i                    = interp1(trial(n).time_axis(real_idx), trial(n).x_eye(real_idx), trial(n).time_axis_i, 'linear');
            trial(n).y_eye_i                    = interp1(trial(n).time_axis(real_idx), trial(n).y_eye(real_idx), trial(n).time_axis_i, 'linear');
            
            trial(n).x_eye_i                    = filter_et(trial(n).x_eye_i, calcoptions.smoothing_samples);
            trial(n).y_eye_i                    = filter_et(trial(n).y_eye_i, calcoptions.smoothing_samples);
            trial(n).eye_vel_i                  = [0 sqrt((diff(trial(n).x_eye_i).*calcoptions.i_sample_rate).^2+(diff(trial(n).y_eye_i).*calcoptions.i_sample_rate).^2)];
            trial(n).eye_vel_i                  = filter_et(trial(n).eye_vel_i, calcoptions.smoothing_samples);
                       
        else
            trial(n).time_axis_i                = ceil(trial(n).time_axis(1)*calcoptions.i_sample_rate)/calcoptions.i_sample_rate : 1/calcoptions.i_sample_rate : trial(n).time_axis(end);
            if any(diff(trial(n).time_axis)==0) %% weirdness
                idx_to_remove=diff(trial(n).time_axis)==0;
                disp(['Warning: no time difference between two samples in trial ' num2str(n) ' in state ' num2str(trial(n).state(idx_to_remove))]);
                trial(n).x_eye(idx_to_remove)=[];
                trial(n).y_eye(idx_to_remove)=[];
                trial(n).x_hnd(idx_to_remove)=[];
                trial(n).y_hnd(idx_to_remove)=[];
                trial(n).sen_L(idx_to_remove)=[];
                trial(n).sen_R(idx_to_remove)=[];
                trial(n).time_axis(idx_to_remove)=[];
                trial(n).state(idx_to_remove)=[];
                trial(n).tSample_from_time_start(idx_to_remove)=[];
                trial(n).trial_number(idx_to_remove)=[];
            end
            if all(diff(trial(n).x_eye)==0) || all(diff(trial(n).y_eye)==0) %closed eyes for example !?
                trial(n).x_eye_i                    = repmat(trial(n).x_eye(1),1,numel(trial(n).time_axis_i));
                trial(n).y_eye_i                    = repmat(trial(n).y_eye(1),1,numel(trial(n).time_axis_i));
            else
                trial(n).x_eye_i                    = interp1(trial(n).time_axis, trial(n).x_eye, trial(n).time_axis_i, 'linear');
                trial(n).y_eye_i                    = interp1(trial(n).time_axis, trial(n).y_eye, trial(n).time_axis_i, 'linear');
            end
            trial(n).x_eye_i                    = filter_et(trial(n).x_eye_i, calcoptions.smoothing_samples);
            trial(n).y_eye_i                    = filter_et(trial(n).y_eye_i, calcoptions.smoothing_samples);
            trial(n).eye_vel_i                  = [0 sqrt((diff(trial(n).x_eye_i).*calcoptions.i_sample_rate).^2+(diff(trial(n).y_eye_i).*calcoptions.i_sample_rate).^2)];
            trial(n).eye_vel_i                  = filter_et(trial(n).eye_vel_i, calcoptions.smoothing_samples);
        end

        % identifying times of state changes
        smpidx.total_i                  = 1:numel(trial(n).time_axis_i);
        idx_state_changes               = find([true; diff(trial(n).state)~=0])';        
        idx_before_state_changes        = [1, idx_state_changes(2:end)-1];
        times.state_changed             = [trial(n).time_axis(idx_state_changes); max(trial(n).time_axis_i(end),trial(n).time_axis(end))];        
        times.before_state_changed      = [trial(n).time_axis(idx_before_state_changes); max(trial(n).time_axis_i(end),trial(n).time_axis(end))];
        states_present                  = trial(n).state(idx_state_changes);
        times.state_change_obs          = times.state_changed(states_present==states(n).state_obs);
        times.before_state_change_obs   = times.before_state_changed(states_present==states(n).state_obs);
        times.state_change_1ao          = times.state_changed(states_present==states(n).state_1ao);      
        
        states(n).MP_states=[states_present' MA_STATES.ITI];
        states(n).MP_states_onset=times.state_changed;
        
        %% instead of interpolation, extension of states according to interpolated time scale        
        N_states=numel(states_present);
        trial(n).state_i=zeros(size(trial(n).time_axis_i));
        for state_idx=1:N_states
            current_state=states_present(state_idx);
            current_state_start=floor(times.state_changed(state_idx)*calcoptions.i_sample_rate)/calcoptions.i_sample_rate;
            current_state_end=floor(times.state_changed(state_idx+1)*calcoptions.i_sample_rate)/calcoptions.i_sample_rate;            
            trial(n).state_i(trial(n).time_axis_i>=current_state_start & trial(n).time_axis_i<current_state_end)=current_state;
        end
        
        if calcoptions.keep_raw_data
            raw(n).states       =trial(n).state_i;
            raw(n).time_axis    =trial(n).time_axis_i;
            raw(n).x_eye        =trial(n).x_eye_i;
            raw(n).y_eye        =trial(n).y_eye_i;
            
            warning('off','MATLAB:interp1:NaNinY');
            raw(n).x_hnd        = interp1(trial(n).time_axis, trial(n).x_hnd, trial(n).time_axis_i, 'linear');
            raw(n).y_hnd        = interp1(trial(n).time_axis, trial(n).y_hnd, trial(n).time_axis_i, 'linear');
        end
               
        
        % Sample indexes definition for observed state and state after
        % (used afterwards for reaches definitions) and interpolated indexes for states before observed
        % (used afterwards for saccade definitions)
        % Note that the index for state after observed for trials aborted
        % during observed state is set to the last sample of observed state
        
        smpidx.state_obs             = find(trial(n).state   == states(n).state_obs);
        smpidx.state_2bo_i           = find(trial(n).state_i == states(n).state_2bo);
        smpidx.state_1bo_i           = find(trial(n).state_i == states(n).state_1bo);
        smpidx.state_obs_i           = find(trial(n).state_i == states(n).state_obs);
        smpidx.state_1ao_i           = find(trial(n).state_i == states(n).state_1ao);
        logsmpidx.not_iti             = ~(trial(n).state_i == MA_STATES.INI_TRI | trial(n).state_i == MA_STATES.ITI);
        
        smpidx.state_1ao   =      find(trial(n).state   == states(n).state_1ao);
        if isempty (smpidx.state_1ao) && ~isempty (smpidx.state_obs)
            smpidx.state_1ao   =      numel(trial(n).state);
        end        
        if ~isempty(smpidx.state_1ao_i)
            states(n).start_1ao =trial(n).time_axis_i(smpidx.state_1ao_i(1));
        end
        if ~isempty(smpidx.state_obs_i)
            states(n).start_obs =trial(n).time_axis_i(smpidx.state_obs_i(1));
        end
        if ~isempty(smpidx.state_1bo_i)
            states(n).start_1bo =trial(n).time_axis_i(smpidx.state_1bo_i(1));
        end
        if ~isempty(smpidx.state_2bo_i)
            states(n).start_2bo =trial(n).time_axis_i(smpidx.state_2bo_i(1));
        end
        
        % Selected positions according to selected intended target s_i_t_e/s_i_t_h (!) calculation,
        % Not selected positions (prefix _nct ) according to not chosen target n_i_t_e/n_i_t_h:
        % fixation positions overwriting NaNs if effector is used for fixation,
        % target positions overwriting, if effector is used for targets.
        % For free gaze reachings, hand target positions are taken as eye
        % target positions (!!!)
        
        if effector_sr(n,1) && ~isnan(n_i_t_e(n))
            saccades(n).nct_pos  = complex(trial(n).eye.tar(n_i_t_e(n)).pos(1),trial(n).eye.tar(n_i_t_e(n)).pos(2));
        end
        if effector_sr(n,2) && ~isnan(n_i_t_h(n))
            reaches(n).nct_pos  = complex(trial(n).hnd.tar(n_i_t_h(n)).pos(1),trial(n).hnd.tar(n_i_t_h(n)).pos(2));
        end
        if effector_sr(n,1) && ~isnan(s_i_t_e(n))
            saccades(n).tar_pos = complex(trial(n).eye.tar(s_i_t_e(n)).pos(1),trial(n).eye.tar(s_i_t_e(n)).pos(2));
            saccades(n).tar_rad = trial(n).eye.tar(s_i_t_e(n)).pos(4);
            saccades(n).tar_siz = trial(n).eye.tar(s_i_t_e(n)).pos(3);
        elseif (trial(n).effector==1 || trial(n).effector==6) && ~isnan(s_i_t_h(n))
            saccades(n).tar_pos = complex(trial(n).hnd.tar(s_i_t_h(n)).pos(1),trial(n).hnd.tar(s_i_t_h(n)).pos(2));
            saccades(n).tar_rad = trial(n).hnd.tar(s_i_t_h(n)).pos(4);
            saccades(n).tar_siz = trial(n).hnd.tar(s_i_t_h(n)).pos(3);
        end
        if effector_sr(n,2) && ~isnan(s_i_t_h(n))
            reaches(n).tar_pos  = complex(trial(n).hnd.tar(s_i_t_h(n)).pos(1),trial(n).hnd.tar(s_i_t_h(n)).pos(2));
            reaches(n).tar_rad  = trial(n).hnd.tar(s_i_t_h(n)).pos(4);
            reaches(n).tar_siz  = trial(n).hnd.tar(s_i_t_h(n)).pos(3);
        end
        if effector_fix_eh(n,1)
            saccades(n).fix_pos = complex(trial(n).eye.fix.pos(1),trial(n).eye.fix.pos(2));
            saccades(n).fix_rad = trial(n).eye.fix.pos(4);
            saccades(n).fix_siz = trial(n).eye.fix.pos(3);
        end
        if effector_fix_eh(n,2)
            reaches(n).fix_pos  = complex(trial(n).hnd.fix.pos(1),trial(n).hnd.fix.pos(2));
            reaches(n).fix_rad  = trial(n).hnd.fix.pos(4);
            reaches(n).fix_siz  = trial(n).hnd.fix.pos(3);
        end
        
        if trial(n).type==1
            [saccades(n).tar_pos,saccades(n).nct_pos]   = deal(saccades(n).fix_pos);
            [reaches(n).tar_pos,reaches(n).nct_pos]     = deal(reaches(n).fix_pos);
            saccades(n).tar_rad = trial(n).eye.fix.pos(4);
            reaches(n).tar_rad  = trial(n).hnd.fix.pos(4);
            saccades(n).tar_siz = trial(n).eye.fix.pos(3);
            reaches(n).tar_siz  = trial(n).hnd.fix.pos(3);
        end
        
        % target colors
        if trial(n).type==1
            target_for_color='fix';
        elseif trial(n).type==3
            target_for_color='cue';
        else
            target_for_color='tar';
        end
        
        
        saccades(n).col_dim = vertcat(trial(n).task.eye.(target_for_color).color_dim);
        saccades(n).col_bri = vertcat(trial(n).task.eye.(target_for_color).color_bright);
        reaches(n).col_dim  = vertcat(trial(n).task.hnd.(target_for_color).color_dim);
        reaches(n).col_bri  = vertcat(trial(n).task.hnd.(target_for_color).color_bright);
        
        
        %%     REACHES
        % reaches are defined if hand is used as a target effector (effector_sr(n,2))
        % by periods of no touchscreen information (NaNs) during observed
        % state, for reach initiation we take the time of the last non-NaN hand position,
        % for reach finishing three different definitions are available, selected with keys
        % 'reach_1st_pos', 'reach_1st_pos_in' and 'reach_pos_at_state_change'
        % If Multiple defintions are selected, reach positions are calculated seperately,
        % latencies, durations and precision are computed following the priority rule
        % 'reach_1st_pos' --> 'reach_1st_pos_in' --> 'reach_pos_at_state_change'
        % Relevant output: structure 'reaches', fields 'ini', 'end', 'pos',
        % 'pos_inside', 'pos_last', 'accuracy_xy' 'tar_pos'
        
        if all(isfield(trial(n), {'sen_R', 'sen_L'}))
            %smpidx.released_sensors             = find(logical([ diff(trial(n).sen_L)~=0 | diff(trial(n).sen_R)~=0 ; 0]));
            smpidx.released_seonsors_in_fix_acq = find(logical([ diff(trial(n).sen_L)~=0 | diff(trial(n).sen_R)~=0 ; 0]) & trial(n).state == MA_STATES.FIX_ACQ);
            smpidx.fix                  = find(trial(n).state == MA_STATES.FIX_HOL);
            if ~isempty(smpidx.released_seonsors_in_fix_acq)
                reaches(n).ini_fix = trial(n).time_axis(smpidx.released_seonsors_in_fix_acq(1));
                if ~isempty(smpidx.fix)
                    reaches(n).pos_first_fix = trial(n).x_hnd(smpidx.fix(1)) + 1i*trial(n).y_hnd(smpidx.fix(1));
                    reaches(n).dur_fix = trial(n).time_axis(smpidx.fix(1)) - trial(n).time_axis(smpidx.released_seonsors_in_fix_acq(1));
                    reaches(n).accuracy_xy_fix  = reaches(n).pos_first_fix - reaches(n).fix_pos;
                   
                end
            end
        end
        
        
        if effector_sr(n,2) % && ~isnan(s_c_t(n)) ???
            smpidx.reaching_nan  = find(isnan(trial(n).x_hnd) & trial(n).state == states(n).state_obs)'; % general sample indexes for reaching
            if ~isempty(smpidx.reaching_nan) && smpidx.reaching_nan(end)~= numel(trial(n).state)
                smpidx.reaching                     = [smpidx.reaching_nan(1)-1 smpidx.reaching_nan smpidx.reaching_nan(end)+1];% expanding index by one sample in both directions to take positions lift and land
                times.reach                         = trial(n).time_axis(smpidx.reaching); % corresponding time after start of run
                reaches(n).ini                      = times.reach(2); % time for reach initiation
                reaches(n).startpos                 = trial(n).x_hnd(smpidx.reaching(1)) +1i*trial(n).y_hnd(smpidx.reaching(1));
               
                if  ~isnan(trial(n).x_hnd(smpidx.reaching(end))) && any(trial(n).state == states(n).state_1ao)
                    reaches(n).end_stat                 = trial(n).time_axis(smpidx.state_obs(end));
                end
                if ~isnan(trial(n).x_hnd(smpidx.reaching(end)))
                    %reaches(n).end_first                      = times.reach(end);
                    reaches(n).pos_first                      = trial(n).x_hnd(smpidx.reaching(end)) +1i*trial(n).y_hnd(smpidx.reaching(end));
                end
                if ~isnan(trial(n).x_hnd(smpidx.reaching(end))) && any(trial(n).state == states(n).state_1ao) % it was taking also reaches outside the target, check for a better definition
                    reaches(n).pos_inside               = trial(n).x_hnd(smpidx.state_obs(end)) + 1i*trial(n).y_hnd(smpidx.state_obs(end));
                    %reaches(n).end_inside               = trial(n).time_axis(smpidx.state_obs(end));
                end
                if ~isnan(trial(n).x_hnd(smpidx.reaching(end)))
                    reaches(n).pos_last                 = trial(n).x_hnd(smpidx.state_1ao(end)) +1i*trial(n).y_hnd(smpidx.state_1ao(end));
                    %reaches(n).end_last                 = trial(n).time_axis(smpidx.state_1ao(end));
                end
                if calcoptions.reach_1st_pos %|| (ismat(calcoptions.reach_definition) && calcoptions.reach_definition==1) || (ischar(calcoptions.reach_definition) && strcmp(calcoptions.reach_definition,'1st_pos'))
                    %reaches(n).end_stat                 = reaches(n).end_first;
                    reaches(n).endpos                   = reaches(n).pos_first;
                elseif calcoptions.reach_1st_pos_in %|| (ismat(calcoptions.reach_definition) && calcoptions.reach_definition==2) || (ischar(calcoptions.reach_definition) && strcmp(calcoptions.reach_definition,'1st_pos_in'))
                    %reaches(n).end_stat                 = reaches(n).end_inside;
                    reaches(n).endpos                   = reaches(n).pos_inside;
                elseif calcoptions.reach_pos_at_state_change %|| (ismat(calcoptions.reach_definition) && calcoptions.reach_definition==3) || (ischar(calcoptions.reach_definition) && strcmp(calcoptions.reach_definition,'pos_at_state_change'))
                    %reaches(n).end_stat                 = reaches(n).end_last;
                    reaches(n).endpos                   = reaches(n).pos_last;
                end
                reaches(n).accuracy_xy              = reaches(n).endpos - reaches(n).tar_pos; % x y n hand position first touch - target position
                reaches(n).lat                      = reaches(n).ini-times.state_change_obs(1);
                reaches(n).dur                      = reaches(n).end_stat-reaches(n).ini;
                [~, min_distance_idx]               = min(unique_hnd_target_positions-reaches(n).endpos);
                reaches(n).tar_pos_closest          = unique_hnd_target_positions(min_distance_idx);
            end
            
            %smpidx.reaching_nan_fix     = find(isnan(trial(n).x_hnd) & trial(n).state == MA_STATES.FIX_ACQ);
            %smpidx.fix                  = find(trial(n).state == MA_STATES.FIX_HOL);
            reaches(n).accuracy_rad     = (reaches(n).endpos - reaches(n).tar_pos)*(reaches(n).fix_pos-reaches(n).tar_pos)'/abs(reaches(n).fix_pos-reaches(n).tar_pos);
            if trial(n).type==1
                reaches(n).lat=reaches(n).ini_fix;
                reaches(n).ini=reaches(n).ini_fix;
                reaches(n).dur=reaches(n).dur_fix;
                reaches(n).accuracy_xy=reaches(n).accuracy_xy_fix;
            end
           
            tarpos                          = vertcat(trial(n).hnd.tar.pos);
            reaches(n).all_tar_pos          = complex(tarpos(:,1),tarpos(:,2));
                reaches(n).n_targets        = numel(trial(n).task.hnd.tar);
            if isfield(trial(n).hnd.tar(1),'shape') && isstruct(trial(n).hnd.tar(1).shape)
                if ~isnan(s_i_t_h(n))
                    reaches(n).selected_convexity= trial(n).hnd.tar(s_i_t_h(n)).shape.convexity;
                    reaches(n).selected_convex_sides= trial(n).hnd.tar(s_i_t_h(n)).shape.convex_side;
                end
                reaches(n).targets_inspected    = trial(n).hand_targets_inspected;
                reaches(n).cue_pos              = trial(n).hnd.cue(1).pos(1)+1i*trial(n).hnd.cue(1).pos(2);
                reaches(n).n_targets            = trial(n).task.n_targets;
                tarshapes                       = [trial(n).hnd.tar.shape];
                reaches(n).all_convexities      = [tarshapes.convexity];
                reaches(n).all_convex_sides     = {tarshapes.convex_side};
                if ~isempty(times.before_state_change_obs) && ~isempty(times.state_change_1ao)
                    reaches(n).exploration_time = times.state_change_1ao(end)-times.before_state_change_obs(1);
                    if numel(times.before_state_change_obs)>=2 && numel(times.state_change_1ao)>=2
                        if trial(n).completed
                            reaches(n).all_inspection_durations=[times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end-1)', trial(n).task.timing.tar_time_hold];
                            reaches(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                            %reaches(n).all_inspection_durations=times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end-1)';
                        else
                            reaches(n).all_inspection_durations=times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end)';
                            reaches(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs(1:end-1)'];
                        end
                    elseif numel(times.before_state_change_obs)>=2 && ~trial(n).completed
                        reaches(n).all_inspection_durations=times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end)';
                        reaches(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs(1:end-1)'];
                    elseif trial(n).completed
                        reaches(n).all_inspection_durations=trial(n).task.timing.tar_time_hold;
                        reaches(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                    elseif ~isempty(times.state_change_1ao)
                        reaches(n).all_inspection_durations=trial(n).task.timing.tar_time_hold;
                        reaches(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                    end
                end
                
            end
        end
        
        
        %%     SACCADES
        logsmpidx.sac_above         =(trial(n).eye_vel_i >= calcoptions.sac_ini_t) & logsmpidx.not_iti ;
        logsmpidx.sac_under         =(trial(n).eye_vel_i <= calcoptions.sac_end_t) & logsmpidx.not_iti ;
        smpidx.between_TH_start     =find([diff(logsmpidx.sac_above)==-1 | diff(logsmpidx.sac_under)==-1 false ]);
        smpidx.between_TH_end       =find([false diff(logsmpidx.sac_above)==1 | diff(logsmpidx.sac_under)==1 ]);
        if numel(smpidx.between_TH_end)>0 && numel(smpidx.between_TH_start)>0 && smpidx.between_TH_end(1)<= smpidx.between_TH_start(1)
            smpidx.between_TH_end(1)=[];
        end
        logsmpidx.startfromlow      =trial(n).eye_vel_i(smpidx.between_TH_start)<=calcoptions.sac_end_t;
        logsmpidx.startfromhigh     =trial(n).eye_vel_i(smpidx.between_TH_start)>=calcoptions.sac_ini_t;
        logsmpidx.endinlow          =trial(n).eye_vel_i(smpidx.between_TH_end)<=calcoptions.sac_end_t;
        logsmpidx.endinhigh         =trial(n).eye_vel_i(smpidx.between_TH_end)>=calcoptions.sac_ini_t;
        if numel(smpidx.between_TH_end) +1 == numel(smpidx.between_TH_start)
            smpidx.between_TH_end(end+1)   =smpidx.total_i(end);
            logsmpidx.endinlow(end+1)   =true;
            logsmpidx.endinhigh(end+1)  =false;
        end
        
        smpidx.sac_start            =smpidx.between_TH_end(logsmpidx.endinhigh & logsmpidx.startfromlow);
        smpidx.sac_amp_start        =smpidx.between_TH_end(logsmpidx.endinhigh & logsmpidx.startfromlow);
        smpidx.sac_end              =smpidx.between_TH_end(logsmpidx.endinlow  & logsmpidx.startfromhigh);
        if numel(smpidx.sac_start)==0 && numel(smpidx.sac_end)~=0 &&~logsmpidx.sac_above(1)
            smpidx.sac_start        =1;
            smpidx.sac_amp_start    =1;
        elseif numel(smpidx.sac_start)==0 && numel(smpidx.sac_end)~=0
            smpidx.sac_start        =[];
            smpidx.sac_amp_start    =[];
        elseif numel(smpidx.sac_end)==0
        elseif smpidx.sac_end(1)< smpidx.sac_start(1) && find(smpidx.between_TH_end==smpidx.sac_end(1))>1
            smpidx.sac_start       =[1 smpidx.sac_start];
            smpidx.sac_amp_start   =[1 smpidx.sac_amp_start];
        elseif smpidx.sac_end(1)< smpidx.sac_start(1)
            smpidx.sac_end(1)       =[];
        end
        if numel(smpidx.sac_end) +1 == numel(smpidx.sac_start)
            smpidx.sac_end(end+1)   =smpidx.total_i(end);
        end
        durations_all                   =trial(n).time_axis_i(smpidx.sac_end)-trial(n).time_axis_i(smpidx.sac_start);
        
        
        sacidx_dur=durations_all.*1000 >= calcoptions.sac_min_dur;
        if ~trial(n).success && numel(sacidx_dur)>0 % duration criterion for last saccade (if error only!)?
            sacidx_dur(end)=true;
        end
        nsacc_max=min(calcoptions.nsacc_max, sum(sacidx_dur));
        smpidx.sac_start            =smpidx.sac_start(sacidx_dur);
        smpidx.sac_end              =smpidx.sac_end(sacidx_dur);
        n_samples_back              =6; % one more because < than...
        average_window              =10;
        
        smpidx.sac_amp_avarage                          = smpidx.sac_amp_start-n_samples_back;
        for t=1:nsacc_max
            saccades(n).vel_all(t)      = max(trial(n).eye_vel_i(smpidx.sac_start(t):smpidx.sac_end(t)));
            if smpidx.sac_amp_avarage(t)>average_window
                saccades(n).startpos_all(t) = median(trial(n).x_eye_i((smpidx.sac_amp_avarage(t)-average_window):smpidx.sac_amp_avarage(t)))+1i*median(trial(n).y_eye_i((smpidx.sac_amp_avarage(t)-average_window):smpidx.sac_amp_avarage(t)));
            elseif smpidx.sac_amp_start>1
                saccades(n).startpos_all(t) = median(trial(n).x_eye_i(smpidx.sac_amp_start-1))+1i*median(trial(n).y_eye_i(smpidx.sac_amp_start-1));
            end
            %saccades(n).startpos_all(t) = median(trial(n).x_eye_i(smpidx.sac_amp_avarage(t):smpidx.sac_amp_start(t)))+1i*median(trial(n).y_eye_i(smpidx.sac_amp_avarage(t):smpidx.sac_amp_start(t)));
        end
        saccades(n).ini_all(1:nsacc_max)             = trial(n).time_axis_i(smpidx.sac_start(1:nsacc_max));
        saccades(n).end_all(1:nsacc_max)             = trial(n).time_axis_i(smpidx.sac_end(1:nsacc_max));
        saccades(n).endpos_all(1:nsacc_max)          = trial(n).x_eye_i(smpidx.sac_end(1:nsacc_max)) +1i*trial(n).y_eye_i(smpidx.sac_end(1:nsacc_max));
        
        if isfield(trial(n),'microstim_state') && ~isnan(trial(n).microstim_state) && calcoptions.lat_after_micstim==1  && (trial(n).microstim==1 || keys.evok_val.simulate_evoked == 1)
            
            after_stim=[trial(n).time_axis(trial(n).state== trial(n).microstim_state)'+trial(n).microstim_start,trial(n).time_axis_i(end),trial(n).time_axis_i(end) ];
            saccades(n).ini_all             = saccades(n).ini_all - after_stim(2);
            saccades(n).end_all             = saccades(n).end_all - after_stim(2);
        end
        
        states_of_saccades=trial(n).state_i(smpidx.sac_start);
        
        
        smpidx.state_obs                        = find(trial(n).state   == states(n).state_obs);
        if trial(n).type==5 || trial(n).type==6
            logsmpidx.sac_obs                       = ismember(states_of_saccades,[states(n).state_obs states(n).state_1ao]);
        else
            logsmpidx.sac_obs                       = ismember(states_of_saccades,states(n).state_obs);
        end
        smpidx.sac_start_obs_i                  = smpidx.sac_start(logsmpidx.sac_obs);
        n_obs                                   = sum(logsmpidx.sac_obs);
        saccades(n).endpos_obs(1:n_obs)         = trial(n).x_eye_i(smpidx.sac_end(logsmpidx.sac_obs)) +1i*trial(n).y_eye_i(smpidx.sac_end(logsmpidx.sac_obs));
        saccades(n).startpos_obs(1:n_obs)       = trial(n).x_eye_i(smpidx.sac_start(logsmpidx.sac_obs)) +1i*trial(n).y_eye_i(smpidx.sac_start(logsmpidx.sac_obs));
        amp_obs                                 = abs(saccades(n).endpos_obs(1:n_obs) - saccades(n).startpos_obs(1:n_obs));
        saccades(n).amplitudes_obs(1:n_obs)     = amp_obs;
        
        All_n_sac=1:numel(saccades(n).ini_all);
        
        
        %% saccade definitions
        if calcoptions.saccade_definition==1    % closest saccade, if it was big enough
            s_big_amplitudes_obs   = amp_obs>=calcoptions.sac_min_amp;
            distance_obs=abs(saccades(n).endpos_obs - saccades(n).tar_pos);
            All_n_sac=All_n_sac(s_big_amplitudes_obs);
            [~,minsac_idx]=min(distance_obs(s_big_amplitudes_obs));
            sel_n_obs=All_n_sac(minsac_idx);
            
        elseif calcoptions.saccade_definition==2  % biggest saccade, if it was close enough
            close_obs=abs(saccades(n).endpos_obs - saccades(n).tar_pos)<= calcoptions.sac_max_off;
            All_n_sac=All_n_sac(close_obs);
            [~,maxsac_idx]=max(amp_obs(close_obs));
            sel_n_obs=All_n_sac(maxsac_idx);
            %sel_n_obs=All_n_sac(amp_obs==max([amp_obs(close_obs),0]));
            
        elseif calcoptions.saccade_definition==3      % last saccade in the state, the one that entered the window
            sel_n_obs=n_obs;
            
        elseif calcoptions.saccade_definition==4      % first saccade in the state
            sel_n_obs=1;
        
        elseif calcoptions.saccade_definition==5      % first saccade inside any of the potential targets in this run
            s_big_amplitudes_obs   = amp_obs>=calcoptions.sac_min_amp;
            sel_n_obs = find(s_big_amplitudes_obs,1,'first');
            
        elseif calcoptions.saccade_definition==10      % first saccade inside any of the potential targets in this run
            
            sel_n_obs=[];
            if numel(closest_target_radius)<=1 %%% ???
                current_closest_radius=closest_target_radius;
            else
                current_closest_radius=closest_target_radius(n);
            end
            for sac_idx=1:n_obs
                if any(abs(unique_eye_target_positions-saccades(n).endpos_obs(sac_idx))<=current_closest_radius)
                    sel_n_obs=sac_idx;
                    break
                end
            end
        else
            disp('No valid saccade definition selected')
        end
        
        saccades(n).vel_obs(1:n_obs)     = max(trial(n).eye_vel_i(smpidx.sac_start(logsmpidx.sac_obs):smpidx.sac_end(logsmpidx.sac_obs))); 
        saccades(n).ini_obs(1:n_obs)     = trial(n).time_axis_i(smpidx.sac_start(logsmpidx.sac_obs));
        saccades(n).end_obs(1:n_obs)     = trial(n).time_axis_i(smpidx.sac_end(logsmpidx.sac_obs));
        
        lat_lockedtomicrostimstate=[];
        
        
        
        if ~isempty(smpidx.sac_start_obs_i) && ~isempty(sel_n_obs)
            states(n).state_sac         =     states(n).state_obs;
            saccades(n).lat             =     saccades(n).ini_obs(sel_n_obs) - states(n).start_obs;
            saccades(n).dur             =     saccades(n).end_obs(sel_n_obs) - saccades(n).ini_obs(sel_n_obs);
            saccades(n).endpos          =     saccades(n).endpos_obs(sel_n_obs);
            saccades(n).startpos        =     saccades(n).startpos_obs(sel_n_obs);
            saccades(n).velocity        =     saccades(n).vel_obs(sel_n_obs);
            saccades(n).num_sac         =     n_obs ;
            saccades(n).sel_n_sac       =     sel_n_obs ;
            states(n).start_sac         =     states(n).start_obs;
        end
        
        % latency after stim onset (?)
        if isfield(trial,'microstim_start')  && (trial(n).microstim==1 || keys.evok_val.simulate_evoked == 1) && (~isnan(trial(n).microstim_start) || ~isnan(trial(n).stim_to_state_end))
            microstim_delay                   = trial(n).time_axis_i (trial(n).state_i ==trial(n).microstim_state);
            if ~isempty(microstim_delay)
                states(n).start_mis               = microstim_delay(1);
                task(n).ini_mis                   = microstim_delay(1)+trial(n).microstim_start;
            end
            lat_lockedtomicrostimstate=[saccades(n).ini_all-task(n).ini_mis];
            dir_lockedtomicrostimstate=[saccades(n).endpos_all-saccades(n).startpos_all];
        end
        
        saccades(n).n_obs               = n_obs;

        if isfield(trial,'microstim_start') && ~isnan(trial(n).microstim_start) && (trial(n).microstim || keys.evok_val.simulate_evoked == 1) && calcoptions.lat_after_micstim
            if  calcoptions.saccade_obs && ~isempty(smpidx.sac_start_obs_i)
                saccades(n).lat             =     saccades(n).ini_obs(n_obs) - task(n).ini_mis;
            elseif calcoptions.saccade_1bo && ~isempty(smpidx.sac_start_1bo_i)
                saccades(n).lat             =     saccades(n).ini_1bo(n_1bo) - task(n).ini_mis;
            elseif calcoptions.saccade_2bo && ~isempty(smpidx.sac_start_2bo_i)
                saccades(n).lat             =     saccades(n).ini_2bo(n_2bo) - task(n).ini_mis;
            end
        end
        
        [~, min_distance_idx]           = min(unique_eye_target_positions-saccades(n).endpos);
        saccades(n).tar_pos_closest     = unique_eye_target_positions(min_distance_idx);
        saccades(n).accuracy_rad        = (saccades(n).endpos-saccades(n).tar_pos)*(saccades(n).tar_pos-saccades(n).fix_pos)'/abs(saccades(n).tar_pos-saccades(n).fix_pos);
        saccades(n).accuracy_xy         = saccades(n).endpos     - saccades(n).tar_pos; % x y n eye position in observed - target position
        
        %% evoked saccade definition! (liberal !?!? CHECK VERY VERY CAREFULLY!!)
        saccades(n).evoked=false;
        saccades(n).ini_evo=NaN;
        idx_pot_lockedtomicrostimstate_positive=lat_lockedtomicrostimstate<=keys.evok_val.evoked_stimlocked_latency_max & lat_lockedtomicrostimstate >=keys.evok_val.evoked_stimlocked_latency_min;
        if any(idx_pot_lockedtomicrostimstate_positive)
            idx_amp_lts=abs(dir_lockedtomicrostimstate)>=keys.evok_val.evoked_amplitude_min;
            idx_dir_lts=real(dir_lockedtomicrostimstate)<0;
            if any(idx_dir_lts & idx_amp_lts & idx_pot_lockedtomicrostimstate_positive)
                times.afterstimonset=trial(n).time_axis_i(trial(n).state_i== trial(n).microstim_state);
                if keys.evok_val.consecutive_saccade==1
                    n_total_saccades_in_range=2;
                else
                    n_total_saccades_in_range=1;
                end
                %% doublecheck!
                if ~isempty(smpidx.state_obs_i) && sum((trial(n).time_axis_i(smpidx.sac_start(~isnan(smpidx.sac_start)))-task(n).ini_mis)>0 &...
                        trial(n).time_axis_i(smpidx.sac_start(~isnan(smpidx.sac_start))) < max(times.afterstimonset(1)+trial(n).microstim_end,trial(n).time_axis_i(smpidx.state_obs_i(end)))+0.1)>=n_total_saccades_in_range
                    
                    pot_lat_lockedtomicrostimstate_positive=lat_lockedtomicrostimstate(idx_dir_lts & idx_amp_lts & idx_pot_lockedtomicrostimstate_positive);
                    saccades(n).evoked=true;
                    saccades(n).ini_evo=pot_lat_lockedtomicrostimstate_positive(1);
                end
            end
        end
        if effector_sr(n,1)
        tarpos                          = vertcat(trial(n).eye.tar.pos);
        saccades(n).all_tar_pos         = complex(tarpos(:,1),tarpos(:,2));
        saccades(n).n_targets        = numel(trial(n).task.eye.tar);
        end
        if effector_sr(n,1) && isfield(trial(n).eye.tar(1),'shape') && isstruct(trial(n).eye.tar(1).shape)
            if ~isnan(s_i_t_e(n))
                saccades(n).selected_convexity      = trial(n).eye.tar(s_i_t_e(n)).shape.convexity;
                saccades(n).selected_convex_sides   = trial(n).eye.tar(s_i_t_e(n)).shape.convex_side;
            end
            saccades(n).targets_inspected   = trial(n).eye_targets_inspected;
            saccades(n).cue_pos             = trial(n).eye.cue(1).pos(1)+1i*trial(n).eye.cue(1).pos(2);
            saccades(n).n_targets           = trial(n).task.n_targets;
            tarshapes                       = [trial(n).eye.tar.shape];
            saccades(n).all_convexities     = [tarshapes.convexity];
            saccades(n).all_convex_sides    = {tarshapes.convex_side};
            if ~isempty(times.before_state_change_obs) && ~isempty(times.state_change_1ao)
                saccades(n).exploration_time = times.state_change_1ao(end)-times.before_state_change_obs(1);
                if numel(times.before_state_change_obs)>=2 && numel(times.state_change_1ao)>=2
                    if trial(n).completed && numel(times.state_change_1ao)==numel(times.before_state_change_obs) %% due to manual skipping, should be removed in clean_data
                        saccades(n).all_inspection_durations=[times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end-1)', trial(n).task.timing.tar_time_hold];
                        saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                    elseif numel(times.before_state_change_obs)==numel(times.state_change_1ao) % unfortunately the case sometimes in early versions... running out of time??
                        saccades(n).all_inspection_durations=[times.before_state_change_obs(2:end)', times.state_changed(end)]-times.state_change_1ao(1:end)';
                        saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                    else
                        saccades(n).all_inspection_durations=times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end)';
                        saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs(1:end-1)'];
                    end
                elseif numel(times.before_state_change_obs)>=2 && ~trial(n).completed
                    saccades(n).all_inspection_durations=times.before_state_change_obs(2:end)'-times.state_change_1ao(1:end)';
                    saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs(1:end-1)'];
                elseif trial(n).completed
                    saccades(n).all_inspection_durations=trial(n).task.timing.tar_time_hold;
                    saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                elseif ~isempty(times.state_change_1ao)
                    saccades(n).all_inspection_durations=trial(n).task.timing.tar_time_hold;
                    saccades(n).all_inspection_intervals=[times.state_change_1ao' - times.before_state_change_obs'];
                end
            end
        end
    end
end
%% Logical indexes for further use
% threshold distances taken for deciding if saccade/reach was a regular attempt (within_distance) or not
% are defined by the input keys calcoptions.sac_int_xy/calcoptions.rea_int_xy


logidx.success          =[trial.aborted_state]==-1;                 % if it was a succesful trial or not
if isfield(trial(1), 'completed')
    [logidx.completed]           = [trial.completed]==1;
else
    [logidx.completed]           = [logidx.success]==1;
end
logidx.choice           =[trial.choice]==1;                         % if it was a choice trial (1) or instructed (0)
logidx.abort_in_obs     =[trial.aborted_state]==[states.state_obs];   % if it was aborted in observed state
logidx.targets_visible  =([trial.aborted_state]>MA_STATES.FIX_HOL | [trial.aborted_state]==-1);    % if the target positions were visible
logidx.reward_modulation=([trial.reward_modulation]==1);
logidx.reward_selected_small=([trial.reward_selected]==1);
logidx.reward_selected_normal=([trial.reward_selected]==2);
logidx.reward_selected_large=([trial.reward_selected]==3);
if numel(trial(1).rest_hand)==2
    sen=reshape([trial.rest_hand],2,[]);
    logidx.rest_sensor_1=sen(1,:)==1;
    logidx.rest_sensor_2=sen(2,:)==1;
else %% don't know what is happening when rest_sensor has only one element
    
    logidx.rest_sensor_1=false(size(trial));
    logidx.rest_sensor_2=false(size(trial));
end
logidx.rest_sensors_on =  logidx.rest_sensor_1 & logidx.rest_sensor_2 == 1;

logidx.saccade_expected=(effector_sr(:,1)==1)';
logidx.reach_expected=(effector_sr(:,2)==1)';
%
trial_length= length(trial);
for idx_empty=1:trial_length
    if isempty(trial(1,idx_empty).reach_hand)
        trial(1,idx_empty).reach_hand=NaN;
    end
end

logidx.temp_reach_hnd_1=[trial.reach_hand]==1;
logidx.temp_reach_hnd_2=[trial.reach_hand]==2;
logidx.reach_hnd_1=logidx.temp_reach_hnd_1 & logidx.rest_sensors_on;
logidx.reach_hnd_2=logidx.temp_reach_hnd_2 & logidx.rest_sensors_on;

% !!! nosaccade/ noreach definitions!!!
logidx.nosaccade    =isnan([saccades.endpos])& logidx.saccade_expected;           % if there was no saccade detected (no eye positions recorded OR calcoptions.saccade_obs false)
logidx.noreach      =isnan([reaches.endpos]) & logidx.reach_expected;                % if there was no reaching detected (no reach task OR calcoptions.reach_1st_pos false OR no Nan, meaning no lifting of the hand)
logidx.right_hand   =[reaches.reach_hand]==2;                % if right hand was demanded in the task settings (NOT neccessarily right hand used!)
logidx.left_hand    =[reaches.reach_hand]==1;                % if left hand was demanded in the task settings (NOT neccessarily left hand used !)

logidx.eyetar_l =(real([saccades.tar_pos] - [saccades.fix_pos]) < 0) | ([saccades.tar_pos]==[saccades.fix_pos] & [saccades.tar_pos] <0);  % if there was a saccade target on the left side
logidx.eyetar_r =(real([saccades.tar_pos] - [saccades.fix_pos]) > 0) | ([saccades.tar_pos]==[saccades.fix_pos] & [saccades.tar_pos] >0);  % if there was a saccade target on the right side
logidx.hndtar_l =(real([reaches.tar_pos]  - [reaches.fix_pos ]) < 0) | ([reaches.tar_pos] ==[reaches.fix_pos]  & [reaches.tar_pos]  <0);  % if there was a reach target on the left side
logidx.hndtar_r =(real([reaches.tar_pos]  - [reaches.fix_pos ]) > 0) | ([reaches.tar_pos] ==[reaches.fix_pos]  & [reaches.tar_pos]  >0);  % if there was a reach target on the right side

logidx.sac_within_distance_l=real([saccades.accuracy_xy])<calcoptions.sac_int_xy(1) & imag([saccades.accuracy_xy])<calcoptions.sac_int_xy(2) & logidx.eyetar_l;
logidx.sac_within_distance_r=real([saccades.accuracy_xy])<calcoptions.sac_int_xy(1) & imag([saccades.accuracy_xy])<calcoptions.sac_int_xy(2) & logidx.eyetar_r;
logidx.rea_within_distance_l=real([reaches.accuracy_xy])<calcoptions.rea_int_xy(1)  & imag([reaches.accuracy_xy])<calcoptions.rea_int_xy(2)  & logidx.hndtar_l;
logidx.rea_within_distance_r=real([reaches.accuracy_xy])<calcoptions.rea_int_xy(1)  & imag([reaches.accuracy_xy])<calcoptions.rea_int_xy(2)  & logidx.hndtar_r;

logidx.sac_within_closest_target = abs([saccades.endpos]-[saccades.tar_pos_closest])    <closest_target_radius;
logidx.rea_within_closest_target = abs([reaches.endpos]-[reaches.tar_pos_closest])      <closest_target_radius;

logidx.sac_us_l=real([saccades.accuracy_rad])<0 & logidx.sac_within_distance_l & abs([saccades.accuracy_rad]) > [saccades.tar_rad];% if there was an undershooting saccade  to a left target
logidx.sac_os_l=real([saccades.accuracy_rad])>0 & logidx.sac_within_distance_l & abs([saccades.accuracy_rad]) > [saccades.tar_rad];% if there was an overshooting  saccade  to a left target
logidx.sac_us_r=real([saccades.accuracy_rad])<0 & logidx.sac_within_distance_r & abs([saccades.accuracy_rad]) > [saccades.tar_rad];% if there was an undershooting saccade  to a right target
logidx.sac_os_r=real([saccades.accuracy_rad])>0 & logidx.sac_within_distance_r & abs([saccades.accuracy_rad]) > [saccades.tar_rad];% if there was an overshooting  saccade  to a right target
logidx.rea_us_l=real([reaches.accuracy_rad])<0  & logidx.rea_within_distance_l & abs([saccades.accuracy_rad])  > [reaches.tar_rad];% if there was an undershooting reaching to a left target
logidx.rea_os_l=real([reaches.accuracy_rad])>0  & logidx.rea_within_distance_l & abs([saccades.accuracy_rad])  > [reaches.tar_rad];% if there was an overshooting  reaching to a left target
logidx.rea_us_r=real([reaches.accuracy_rad])<0  & logidx.rea_within_distance_r & abs([saccades.accuracy_rad])  > [reaches.tar_rad];% if there was an undershooting reaching to a right target
logidx.rea_os_r=real([reaches.accuracy_rad])>0  & logidx.rea_within_distance_r & abs([saccades.accuracy_rad])  > [reaches.tar_rad];%  if there was an overshooting  reaching to a right target

logidx.sac_doesntgo     = [logidx.nosaccade] & [logidx.abort_in_obs];
logidx.rea_doesntgo     = [logidx.noreach]   & [logidx.abort_in_obs];
logidx.sac_inprecise    = [logidx.sac_us_l]  | [logidx.sac_us_r] | [logidx.sac_os_l] | [logidx.sac_os_r];
logidx.rea_inprecise    = [logidx.rea_us_l]  | [logidx.rea_us_r] | [logidx.rea_os_l] | [logidx.rea_os_r];

logidx.sac_nottotarget  = ~[logidx.sac_inprecise] & ~[logidx.nosaccade] & [logidx.abort_in_obs] & [logidx.saccade_expected];
logidx.rea_nottotarget  = ~[logidx.rea_inprecise] & ~[logidx.noreach] & [logidx.abort_in_obs] & [logidx.reach_expected];

binary=restructure_field_indexes(logidx)';
tmp=num2cell(-1*(logidx.eyetar_l | logidx.hndtar_l) + (logidx.eyetar_r | logidx.hndtar_r));
[task.target_side] = tmp{:} ;

if isfield(trial,'task') ; timing=[trialtask.timing]';
end

%%%

if ~isempty(calcoptions.passfilter)
    
    for idx_pass=1:size(calcoptions.passfilter,1)
        current_filter = calcoptions.passfilter(idx_pass,:);
        current_structure = eval(current_filter{1});
        out_idx(idx_pass,:) = ([current_structure.(current_filter{2})] < current_filter{3}) | ([current_structure.(current_filter{2})] > current_filter{4});
    end
    idx_to_take_out = any(out_idx);
    if sum(idx_to_take_out)~=0,    disp(['taking out ' num2str(sum(idx_to_take_out)) ' trials']); end
    saccades(idx_to_take_out)           = [];
    selected(idx_to_take_out)           = [];
    task(idx_to_take_out)               = [];
    timing(idx_to_take_out)             = [];
    states(idx_to_take_out)             = [];
    reaches(idx_to_take_out)            = [];
    physiology(idx_to_take_out)         = [];
    binary(idx_to_take_out)             = [];
    raw(idx_to_take_out)                = [];
  
end



[statistic, correlation] = saccade_reach_correlation(keys,reaches,saccades,task,selected,binary);
out=struct('keys',struct,'selected',selected,'task',task,'timing',timing,'states',states,'saccades',saccades,'reaches',reaches,'physiology',physiology,'binary',binary,'raw',raw,...
    'counts',struct,'statistic',statistic,'correlation',correlation,'rundescriptions',struct,'emptyflag',emptyflag);
%% Trial history part
if ~isnan(keys.mode_val.trial_history_mode) && ~keys.mode_val.trial_history_mode==0
    current_parameter=keys.hist_val.current_parameter;
    current_structure=keys.hist_val.current_structure;
    past_parameter=keys.hist_val.past_parameter;
    past_structure=keys.hist_val.past_structure;
    if strcmp(current_structure,'trialtask')
        current_structure=[trial.task];
    elseif strcmp(current_structure,'trial')
        current_structure=trial;
    else
        current_structure=[out.(current_structure)];
    end
    if strcmp(past_structure,'trialtask')
        past_structure=[trial.task];
    elseif strcmp(past_structure,'trial')
        past_structure=trial;
    else
        past_structure=[out.(past_structure)];
    end
    
    [selected.past_hist_values_tmp]=past_structure.(past_parameter);
    [selected.current_hist_values] =current_structure.(current_parameter);
    out.selected=selected;
end

end

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
MA_STATES.MSK_HOL     = 17; % mask for delayed M2S
MA_STATES.ABORT       = 19;
MA_STATES.SUCCESS     = 20;
MA_STATES.REWARD      = 21;
MA_STATES.ITI         = 50;
MA_STATES.CLOSE       = 99;
MA_STATES.SUCCESS_ABORT =-1;

MA_STATES.ALL               =[MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.DEL_PER MA_STATES.TAR_ACQ_INV  MA_STATES.TAR_HOL_INV...
    MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL MA_STATES.MAT_ACQ MA_STATES.MAT_HOL MA_STATES.MAT_ACQ_MSK MA_STATES.MAT_HOL_MSK MA_STATES.SEN_RET MA_STATES.MSK_HOL MA_STATES.SUCCESS_ABORT  MA_STATES.REWARD  MA_STATES.ITI];
MA_STATES.ALL_NAMES         ={'Trial Initiation', 'Fixation Acquisition', 'Fixation Hold', 'Cue On', 'Memory period', 'Delay period', 'Target Acquisition (invisible)',...
    'Target Hold (invisible)','Target Acquisition', 'Target Hold', 'Match Aquisition', 'Match Hold', 'Match Aquisition (Masked)', 'Match Hold (Masked)', 'Return to Sensors','M2S Mask Hold', 'Not aborted', 'Reward', 'ITI'};
MA_STATES.LABELS={'INI','Initial acq.', 'Initial hold', 'Cue on', 'Memory ', 'Delay', 'Tar inv acq.', 'Tar inv hold', 'Tar acq.', 'Target hold', 'Tar acq.', 'Tar hold', 'Tar acq. mask', 'Tar hold', 'Sen Ret','Msk hold', 'Success', 'Reward', 'ITI'};
MA_STATES.ALL_CHANGE_NAMES  ={'Holding sensors(?)', 'fixation', 'fixation brightening', 'cue onset', 'cue offset', 'delay period',...
    'go signal', 'target acquired', 'targets visible', 'targets brightening', 'targets visible', 'targets brightening', 'masked targets visible', 'target revealed', 'Target sensor reached','M2S Mask Hold', 'success', 'reward', 'ITI'};


end

function counts = counting_binary(binary)
%% Counting occurrences of different combinations
% sac/rea: saccades/reaches;
% suc/abo/tot: success/aborted/total;
% inst/choi: instructed/choice;
% lh/rh: left hand/right hand used;
% l/r: left/right target position
% ushoot/oshoot: undershooting/overshooting errors;
% doesntgo: no reaction on go-cue (especially for reaches);
% nottotarget: out of range errors(according to calcoptions.sac_int_xy/calcoptions.rea_int_xy)

counts.sac_suc_inst_l                               = sum([binary.targets_visible] & [binary.eyetar_l] & ~[binary.choice] & [binary.success]);
counts.sac_suc_inst_r                               = sum([binary.targets_visible] & [binary.eyetar_r] & ~[binary.choice] & [binary.success]);
counts.rea_suc_inst_l                               = sum([binary.targets_visible] & [binary.hndtar_l] & ~[binary.choice] & [binary.success]);
counts.rea_suc_inst_r                               = sum([binary.targets_visible] & [binary.hndtar_r] & ~[binary.choice] & [binary.success]);

counts.sac_abo_inst_l                               = sum([binary.targets_visible] & [binary.eyetar_l] & ~[binary.choice] & ~[binary.success]);
counts.sac_abo_inst_r                               = sum([binary.targets_visible] & [binary.eyetar_r] & ~[binary.choice] & ~[binary.success]);
counts.rea_abo_inst_l                               = sum([binary.targets_visible] & [binary.hndtar_l] & ~[binary.choice] & ~[binary.success]);
counts.rea_abo_inst_r                               = sum([binary.targets_visible] & [binary.hndtar_r] & ~[binary.choice] & ~[binary.success]);

counts.sac_tot_inst_l                               = counts.sac_suc_inst_l + counts.sac_abo_inst_l;
counts.sac_tot_inst_r                               = counts.sac_suc_inst_r + counts.sac_abo_inst_r;
counts.rea_tot_inst_l                               = counts.rea_suc_inst_l + counts.rea_abo_inst_l;
counts.rea_tot_inst_r                               = counts.rea_suc_inst_r + counts.rea_abo_inst_r;

counts.rea_suc_choi_l                               = sum([binary.targets_visible] & [binary.hndtar_l] & [binary.choice] & [binary.success]);
counts.rea_suc_choi_r                               = sum([binary.targets_visible] & [binary.hndtar_r] & [binary.choice] & [binary.success]);
counts.sac_suc_choi_l                               = sum([binary.targets_visible] & [binary.eyetar_l] & [binary.choice] & [binary.success]);
counts.sac_suc_choi_r                               = sum([binary.targets_visible] & ~[binary.eyetar_r] & [binary.choice] & [binary.success]);

counts.rea_tot_choi_l                               = sum([binary.targets_visible] & [binary.hndtar_l] & [binary.choice]);
counts.rea_tot_choi_r                               = sum([binary.targets_visible] & [binary.hndtar_r] & [binary.choice]);
counts.sac_tot_choi_l                               = sum([binary.targets_visible] & [binary.eyetar_l] & [binary.choice]);
counts.sac_tot_choi_r                               = sum([binary.targets_visible] & [binary.eyetar_r] & [binary.choice]);
counts.tot_choi                                     = sum([binary.targets_visible] & [binary.choice]);

counts.right_inst_saw                               =sum([binary.targets_visible] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r] ));
counts.left_inst_saw                                =sum([binary.targets_visible] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l] ));

counts.right_chosen_baseline                        = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r] ));
counts.left_chosen_baseline                         = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l] ));
counts.right_chosen_successful_baseline             = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r]) & [binary.success]);
counts.left_chosen_successful_baseline              = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l]) & [binary.success]);
counts.total_chosen_baseline                        = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice]);
counts.total_chosen_successful_baseline             = sum([binary.targets_visible] & ~[binary.microstim] & [binary.choice] & [binary.success]);

counts.right_chosen_microstim                       = sum([binary.targets_visible] & [binary.microstim] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r] ));
counts.left_chosen_microstim                        = sum([binary.targets_visible] & [binary.microstim] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l] ));
counts.right_chosen_successful_microstim            = sum([binary.targets_visible] & [binary.microstim] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r]) & [binary.success]);
counts.left_chosen_successful_microstim             = sum([binary.targets_visible] & [binary.microstim] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l]) & [binary.success]);
counts.total_chosen_microstim                       = sum([binary.targets_visible] & [binary.microstim] & [binary.choice]);
counts.total_chosen_successful_microstim            = sum([binary.targets_visible] & [binary.microstim] & [binary.choice] & [binary.success]);

counts.right_chosen                                 = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r] ));
counts.left_chosen                                  = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l] ));
counts.right_chosen_successful                      = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r]) & [binary.success]);
counts.left_chosen_successful                       = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l]) & [binary.success]);
counts.total_chosen                                 = sum([binary.targets_visible] & [binary.choice]);
counts.total_chosen_successful                      = sum([binary.targets_visible] & [binary.choice] & [binary.success]);

counts.rew_mod                                      = sum([binary.reward_modulation]);

counts.rew_abo_large_inst_l                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_abo_large_inst_r                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_abo_normal_inst_l                        = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_abo_normal_inst_r                        = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_abo_small_inst_l                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_abo_small_inst_r                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_suc_large_inst_l                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_suc_large_inst_r                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_suc_normal_inst_l                        = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_suc_normal_inst_r                        = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_suc_small_inst_l                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_suc_small_inst_r                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_abo_large_choi_l                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_abo_large_choi_r                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_abo_normal_choi_l                        = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_abo_normal_choi_r                        = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_abo_small_choi_l                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_abo_small_choi_r                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_suc_large_choi_l                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_suc_large_choi_r                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_suc_normal_choi_l                        = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_suc_normal_choi_r                        = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_suc_small_choi_l                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_suc_small_choi_r                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_large_choi_l                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_large_choi_r                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_normal_choi_l                            = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_normal_choi_r                            = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_small_choi_l                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_small_choi_r                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_large_choi_l                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_large_choi_r                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large]);
counts.rew_normal_choi_l                            = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_normal_choi_r                            = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal]);
counts.rew_small_choi_l                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small]);
counts.rew_small_choi_r                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small]);

counts.rew_abo_large_inst_l_LA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_abo_large_inst_r_LA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_abo_normal_inst_l_LA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_abo_normal_inst_r_LA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_abo_small_inst_l_LA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_abo_small_inst_r_LA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_suc_large_inst_l_LA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_suc_large_inst_r_LA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_suc_normal_inst_l_LA                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_suc_normal_inst_r_LA                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_suc_small_inst_l_LA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_suc_small_inst_r_LA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_abo_large_choi_l_LA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_abo_large_choi_r_LA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_abo_normal_choi_l_LA                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_abo_normal_choi_r_LA                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_abo_small_choi_l_LA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_abo_small_choi_r_LA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_suc_large_choi_l_LA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_suc_large_choi_r_LA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_suc_normal_choi_l_LA                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_suc_normal_choi_r_LA                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_suc_small_choi_l_LA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_suc_small_choi_r_LA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_large_choi_l_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_large_choi_r_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_normal_choi_l_LA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_normal_choi_r_LA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_small_choi_l_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_small_choi_r_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_large_choi_l_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_large_choi_r_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_1]);
counts.rew_normal_choi_l_LA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_normal_choi_r_LA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_1]);
counts.rew_small_choi_l_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);
counts.rew_small_choi_r_LA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_1]);

counts.rew_abo_large_inst_l_RA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_abo_large_inst_r_RA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_abo_normal_inst_l_RA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_abo_normal_inst_r_RA                         = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_abo_small_inst_l_RA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_abo_small_inst_r_RA                          = sum([binary.targets_visible] & ~[binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

counts.rew_suc_large_inst_l_RA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_suc_large_inst_r_RA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_suc_normal_inst_l_RA                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_suc_normal_inst_r_RA                         = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_suc_small_inst_l_RA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_suc_small_inst_r_RA                          = sum([binary.targets_visible] & [binary.success] & ~[binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

counts.rew_abo_large_choi_l_RA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_abo_large_choi_r_RA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_abo_normal_choi_l_RA                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_abo_normal_choi_r_RA                         = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_abo_small_choi_l_RA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_abo_small_choi_r_RA                          = sum([binary.targets_visible] & ~[binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

counts.rew_suc_large_choi_l_RA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_suc_large_choi_r_RA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_suc_normal_choi_l_RA                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_suc_normal_choi_r_RA                         = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_suc_small_choi_l_RA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_suc_small_choi_r_RA                          = sum([binary.targets_visible] & [binary.success] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

counts.rew_large_choi_l_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_large_choi_r_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_normal_choi_l_RA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_normal_choi_r_RA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_small_choi_l_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_small_choi_r_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

counts.rew_large_choi_l_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_large_choi_r_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_large] & [binary.reach_hnd_2]);
counts.rew_normal_choi_l_RA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_normal_choi_r_RA                             = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & ~[binary.reward_modulation] & [binary.reward_selected_normal] & [binary.reach_hnd_2]);
counts.rew_small_choi_l_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_l] | [binary.hndtar_l])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);
counts.rew_small_choi_r_RA                              = sum([binary.targets_visible] & [binary.choice] & ([binary.eyetar_r] | [binary.hndtar_r])  & [binary.reward_modulation] & [binary.reward_selected_small] & [binary.reach_hnd_2]);

% ratios of right/left selected in baseline
counts.right_choice_ratio_baseline                  = counts.right_chosen_baseline/counts.total_chosen_baseline;
counts.left_choice_ratio_baseline                   = counts.left_chosen_baseline/counts.total_chosen_baseline;
counts.right_choice_ratio_successful_baseline       = (counts.right_chosen_successful_baseline/counts.total_chosen_successful_baseline);
counts.left_choice_ratio_successful_baseline        = (counts.left_chosen_successful_baseline/counts.total_chosen_successful_baseline );

% ratios of right/left selected in microstim
counts.right_choice_ratio_microstim                 = counts.right_chosen_microstim/counts.total_chosen_microstim;
counts.left_choice_ratio_microstim                  = counts.left_chosen_microstim/counts.total_chosen_microstim;
counts.right_choice_ratio_successful_microstim      = (counts.right_chosen_successful_microstim/counts.total_chosen_successful_microstim);
counts.left_choice_ratio_successful_microstim       = (counts.left_chosen_successful_microstim/counts.total_chosen_successful_microstim );

% ratio of right selected all
counts.right_choice_ratio_right_large               = counts.rew_large_choi_r         /(counts.rew_large_choi_r    +counts.rew_small_choi_l);
counts.right_choice_ratio_right_normal              = counts.rew_normal_choi_r        /(counts.rew_normal_choi_r   +counts.rew_normal_choi_l);
counts.right_choice_ratio_right_small               = counts.rew_small_choi_r         /(counts.rew_small_choi_r    +counts.rew_large_choi_l);
% ratio of left selected all
counts.left_choice_ratio_left_large                 = counts.rew_large_choi_l         /(counts.rew_large_choi_l    +counts.rew_small_choi_r);
counts.left_choice_ratio_left_normal                = counts.rew_normal_choi_l        /(counts.rew_normal_choi_l   +counts.rew_normal_choi_r);
counts.left_choice_ratio_left_small                 = counts.rew_small_choi_l         /(counts.rew_small_choi_l    +counts.rew_large_choi_r);

% ratio of right selected successful
counts.right_choice_ratio_right_large_suc           = counts.rew_suc_large_choi_r     /(counts.rew_large_choi_r    +counts.rew_small_choi_l);
counts.right_choice_ratio_right_normal_suc          = counts.rew_suc_normal_choi_r    /(counts.rew_normal_choi_r   +counts.rew_normal_choi_l);
counts.right_choice_ratio_right_small_suc           = counts.rew_suc_small_choi_r     /(counts.rew_small_choi_r    +counts.rew_large_choi_l);
% ratio of left selected successful
counts.left_choice_ratio_left_large_suc             = counts.rew_suc_large_choi_l     /(counts.rew_large_choi_l    +counts.rew_small_choi_r);
counts.left_choice_ratio_left_normal_suc            = counts.rew_suc_normal_choi_l    /(counts.rew_normal_choi_r   +counts.rew_normal_choi_l);
counts.left_choice_ratio_left_small_suc             = counts.rew_suc_small_choi_l     /(counts.rew_small_choi_l    +counts.rew_large_choi_r);

% ratio of right selected aborted
counts.right_choice_ratio_right_large_abo           = counts.rew_abo_large_choi_r     /(counts.rew_large_choi_r    +counts.rew_small_choi_l);
counts.right_choice_ratio_right_normal_abo          = counts.rew_abo_normal_choi_r    /(counts.rew_normal_choi_r   +counts.rew_normal_choi_l);
counts.right_choice_ratio_right_small_abo           = counts.rew_abo_small_choi_r     /(counts.rew_small_choi_r    +counts.rew_large_choi_l);
% ratio of left selected aborted
counts.left_choice_ratio_left_large_abo             = counts.rew_abo_large_choi_l     /(counts.rew_large_choi_l    +counts.rew_small_choi_r);
counts.left_choice_ratio_left_normal_abo            = counts.rew_abo_normal_choi_l    /(counts.rew_normal_choi_r   +counts.rew_normal_choi_l);
counts.left_choice_ratio_left_small_abo             = counts.rew_abo_small_choi_l     /(counts.rew_small_choi_l    +counts.rew_large_choi_r);


% ratio of right selected all left arm
counts.right_choice_ratio_right_large_LA               = counts.rew_large_choi_r_LA         /(counts.rew_large_choi_r_LA    +counts.rew_small_choi_l_LA);
counts.right_choice_ratio_right_normal_LA              = counts.rew_normal_choi_r_LA        /(counts.rew_normal_choi_r_LA   +counts.rew_normal_choi_l_LA);
counts.right_choice_ratio_right_small_LA               = counts.rew_small_choi_r_LA         /(counts.rew_small_choi_r_LA    +counts.rew_large_choi_l_LA);
% ratio of left selected all left arm
counts.left_choice_ratio_left_large_LA                 = counts.rew_large_choi_l_LA         /(counts.rew_large_choi_l_LA    +counts.rew_small_choi_r_LA);
counts.left_choice_ratio_left_normal_LA                = counts.rew_normal_choi_l_LA        /(counts.rew_normal_choi_l_LA   +counts.rew_normal_choi_r_LA);
counts.left_choice_ratio_left_small_LA                 = counts.rew_small_choi_l_LA         /(counts.rew_small_choi_l_LA    +counts.rew_large_choi_r_LA);

% ratio of right selected successful left arm
counts.right_choice_ratio_right_large_suc_LA           = counts.rew_suc_large_choi_r_LA     /(counts.rew_large_choi_r_LA    +counts.rew_small_choi_l_LA);
counts.right_choice_ratio_right_normal_suc_LA          = counts.rew_suc_normal_choi_r_LA    /(counts.rew_normal_choi_r_LA   +counts.rew_normal_choi_l_LA);
counts.right_choice_ratio_right_small_suc_LA           = counts.rew_suc_small_choi_r_LA     /(counts.rew_small_choi_r_LA    +counts.rew_large_choi_l_LA);
% ratio of left selected successful left arm
counts.left_choice_ratio_left_large_suc_LA             = counts.rew_suc_large_choi_l_LA     /(counts.rew_large_choi_l_LA    +counts.rew_small_choi_r_LA);
counts.left_choice_ratio_left_normal_suc_LA            = counts.rew_suc_normal_choi_l_LA    /(counts.rew_normal_choi_r_LA   +counts.rew_normal_choi_l_LA);
counts.left_choice_ratio_left_small_suc_LA             = counts.rew_suc_small_choi_l_LA     /(counts.rew_small_choi_l_LA    +counts.rew_large_choi_r_LA);

% ratio of right selected aborted left arm
counts.right_choice_ratio_right_large_abo_LA           = counts.rew_abo_large_choi_r_LA     /(counts.rew_large_choi_r_LA    +counts.rew_small_choi_l_LA);
counts.right_choice_ratio_right_normal_abo_LA          = counts.rew_abo_normal_choi_r_LA    /(counts.rew_normal_choi_r_LA   +counts.rew_normal_choi_l_LA);
counts.right_choice_ratio_right_small_abo_LA           = counts.rew_abo_small_choi_r_LA     /(counts.rew_small_choi_r_LA    +counts.rew_large_choi_l_LA);
% ratio of left selected aborted left arm
counts.left_choice_ratio_left_large_abo_LA             = counts.rew_abo_large_choi_l_LA     /(counts.rew_large_choi_l_LA    +counts.rew_small_choi_r_LA);
counts.left_choice_ratio_left_normal_abo_LA            = counts.rew_abo_normal_choi_l_LA    /(counts.rew_normal_choi_r_LA   +counts.rew_normal_choi_l_LA);
counts.left_choice_ratio_left_small_abo_LA             = counts.rew_abo_small_choi_l_LA     /(counts.rew_small_choi_l_LA    +counts.rew_large_choi_r_LA);


% ratio of right selected all right arm
counts.right_choice_ratio_right_large_RA               = counts.rew_large_choi_r_RA         /(counts.rew_large_choi_r_RA    +counts.rew_small_choi_l_RA);
counts.right_choice_ratio_right_normal_RA              = counts.rew_normal_choi_r_RA        /(counts.rew_normal_choi_r_RA   +counts.rew_normal_choi_l_RA);
counts.right_choice_ratio_right_small_RA               = counts.rew_small_choi_r_RA         /(counts.rew_small_choi_r_RA    +counts.rew_large_choi_l_RA);
% ratio of left selected all right arm
counts.left_choice_ratio_left_large_RA                 = counts.rew_large_choi_l_RA         /(counts.rew_large_choi_l_RA    +counts.rew_small_choi_r_RA);
counts.left_choice_ratio_left_normal_RA                = counts.rew_normal_choi_l_RA        /(counts.rew_normal_choi_l_RA   +counts.rew_normal_choi_r_RA);
counts.left_choice_ratio_left_small_RA                 = counts.rew_small_choi_l_RA         /(counts.rew_small_choi_l_RA    +counts.rew_large_choi_r_RA);

% ratio of right selected successful right arm
counts.right_choice_ratio_right_large_suc_RA           = counts.rew_suc_large_choi_r_RA     /(counts.rew_large_choi_r_RA    +counts.rew_small_choi_l_RA);
counts.right_choice_ratio_right_normal_suc_RA          = counts.rew_suc_normal_choi_r_RA    /(counts.rew_normal_choi_r_RA   +counts.rew_normal_choi_l_RA);
counts.right_choice_ratio_right_small_suc_RA           = counts.rew_suc_small_choi_r_RA     /(counts.rew_small_choi_r_RA    +counts.rew_large_choi_l_RA);
% ratio of left selected successful right arm
counts.left_choice_ratio_left_large_suc_RA             = counts.rew_suc_large_choi_l_RA     /(counts.rew_large_choi_l_RA    +counts.rew_small_choi_r_RA);
counts.left_choice_ratio_left_normal_suc_RA            = counts.rew_suc_normal_choi_l_RA    /(counts.rew_normal_choi_r_RA   +counts.rew_normal_choi_l_RA);
counts.left_choice_ratio_left_small_suc_RA             = counts.rew_suc_small_choi_l_RA     /(counts.rew_small_choi_l_RA    +counts.rew_large_choi_r_RA);

% ratio of right selected aborted right arm
counts.right_choice_ratio_right_large_abo_RA           = counts.rew_abo_large_choi_r_RA     /(counts.rew_large_choi_r_RA    +counts.rew_small_choi_l_RA);
counts.right_choice_ratio_right_normal_abo_RA          = counts.rew_abo_normal_choi_r_RA    /(counts.rew_normal_choi_r_RA   +counts.rew_normal_choi_l_RA);
counts.right_choice_ratio_right_small_abo_RA           = counts.rew_abo_small_choi_r_RA     /(counts.rew_small_choi_r_RA    +counts.rew_large_choi_l_RA);
% ratio of left selected aborted right arm
counts.left_choice_ratio_left_large_abo_RA             = counts.rew_abo_large_choi_l_RA     /(counts.rew_large_choi_l_RA    +counts.rew_small_choi_r_RA);
counts.left_choice_ratio_left_normal_abo_RA            = counts.rew_abo_normal_choi_l_RA    /(counts.rew_normal_choi_r_RA   +counts.rew_normal_choi_l_RA);
counts.left_choice_ratio_left_small_abo_RA             = counts.rew_abo_small_choi_l_RA     /(counts.rew_small_choi_l_RA    +counts.rew_large_choi_r_RA);

counts.left_choice_ratio_baseline                   = counts.left_chosen_baseline/counts.total_chosen_baseline;
counts.right_choice_ratio_successful_baseline       = (counts.right_chosen_successful_baseline/counts.total_chosen_successful_baseline);
counts.left_choice_ratio_successful_baseline        = (counts.left_chosen_successful_baseline/counts.total_chosen_successful_baseline );


% ratios of right/left selected in any type of trial
counts.right_choice_ratio                           = counts.right_chosen/counts.total_chosen;
counts.left_choice_ratio                            = counts.left_chosen/counts.total_chosen;
counts.right_choice_ratio_successful                = (counts.right_chosen_successful/counts.total_chosen_successful);
counts.left_choice_ratio_successful                 = (counts.left_chosen_successful/counts.total_chosen_successful);

% percentage of right/left selected in baseline
counts.right_choice_percentage_total_baseline       = counts.right_choice_ratio_baseline*100;
counts.left_choice_percentage_total_baseline        = counts.left_choice_ratio_baseline*100;
counts.right_choice_percentage_successful_baseline  = counts.right_choice_ratio_successful_baseline*100;
counts.left_choice_percentage_successful_baseline   = counts.left_choice_ratio_successful_baseline*100;

% percentage of right/left selected in microstim
counts.right_choice_percentage_total_microstim      = counts.right_choice_ratio_microstim*100;
counts.left_choice_percentage_total_microstim       = counts.left_choice_ratio_microstim*100;
counts.right_choice_percentage_successful_microstim = counts.right_choice_ratio_successful_microstim*100;
counts.left_choice_percentage_successful_microstim  = counts.left_choice_ratio_successful_microstim*100;

% percentage of right/left selected in any type of trial
counts.right_choice_percentage_total                = counts.right_choice_ratio*100;
counts.left_choice_percentage_total                 = counts.left_choice_ratio*100;
counts.right_choice_percentage_successful           = counts.right_choice_ratio_successful*100;
counts.left_choice_percentage_successful            = counts.left_choice_ratio_successful*100;

% percentage of right selected all
counts.right_choice_percentage_right_large          = counts.right_choice_ratio_right_large*100;
counts.right_choice_percentage_right_normal         = counts.right_choice_ratio_right_normal*100;
counts.right_choice_percentage_right_small          = counts.right_choice_ratio_right_small*100;
% percentage of right selected aborted
counts.right_choice_percentage_right_large_abo      = counts.right_choice_ratio_right_large_abo*100;
counts.right_choice_percentage_right_normal_abo     = counts.right_choice_ratio_right_normal_abo*100;
counts.right_choice_percentage_right_small_abo      = counts.right_choice_ratio_right_small_abo*100;
% percentage of right selected success
counts.right_choice_percentage_right_large_suc      = counts.right_choice_ratio_right_large_suc*100;
counts.right_choice_percentage_right_normal_suc     = counts.right_choice_ratio_right_normal_suc*100;
counts.right_choice_percentage_right_small_suc      = counts.right_choice_ratio_right_small_suc*100;

% percentage of left selected all
counts.left_choice_percentage_left_large          = counts.left_choice_ratio_left_large*100;
counts.left_choice_percentage_left_normal         = counts.left_choice_ratio_left_normal*100;
counts.left_choice_percentage_left_small          = counts.left_choice_ratio_left_small*100;
% percentage of left selected aborted
counts.left_choice_percentage_left_large_abo      = counts.left_choice_ratio_left_large_abo*100;
counts.left_choice_percentage_left_normal_abo     = counts.left_choice_ratio_left_normal_abo*100;
counts.left_choice_percentage_left_small_abo      = counts.left_choice_ratio_left_small_abo*100;
% percentage of left selected success
counts.left_choice_percentage_left_large_suc      = counts.left_choice_ratio_left_large_suc*100;
counts.left_choice_percentage_left_normal_suc     = counts.left_choice_ratio_left_normal_suc*100;
counts.left_choice_percentage_left_small_suc      = counts.left_choice_ratio_left_small_suc*100;



% percentage of right selected all left arm
counts.right_choice_percentage_right_large_LA          = counts.right_choice_ratio_right_large_LA*100;
counts.right_choice_percentage_right_normal_LA         = counts.right_choice_ratio_right_normal_LA*100;
counts.right_choice_percentage_right_small_LA          = counts.right_choice_ratio_right_small_LA*100;
% percentage of right selected aborted left arm
counts.right_choice_percentage_right_large_abo_LA      = counts.right_choice_ratio_right_large_abo_LA*100;
counts.right_choice_percentage_right_normal_abo_LA     = counts.right_choice_ratio_right_normal_abo_LA*100;
counts.right_choice_percentage_right_small_abo_LA      = counts.right_choice_ratio_right_small_abo_LA*100;
% percentage of right selected success left arm
counts.right_choice_percentage_right_large_suc_LA      = counts.right_choice_ratio_right_large_suc_LA*100;
counts.right_choice_percentage_right_normal_suc_LA     = counts.right_choice_ratio_right_normal_suc_LA*100;
counts.right_choice_percentage_right_small_suc_LA      = counts.right_choice_ratio_right_small_suc_LA*100;

% percentage of left selected all left arm
counts.left_choice_percentage_left_large_LA          = counts.left_choice_ratio_left_large_LA*100;
counts.left_choice_percentage_left_normal_LA         = counts.left_choice_ratio_left_normal_LA*100;
counts.left_choice_percentage_left_small_LA          = counts.left_choice_ratio_left_small_LA*100;
% percentage of left selected aborted left arm
counts.left_choice_percentage_left_large_abo_LA      = counts.left_choice_ratio_left_large_abo_LA*100;
counts.left_choice_percentage_left_normal_abo_LA     = counts.left_choice_ratio_left_normal_abo_LA*100;
counts.left_choice_percentage_left_small_abo_LA      = counts.left_choice_ratio_left_small_abo_LA*100;
% percentage of left selected success left arm
counts.left_choice_percentage_left_large_suc_LA      = counts.left_choice_ratio_left_large_suc_LA*100;
counts.left_choice_percentage_left_normal_suc_LA     = counts.left_choice_ratio_left_normal_suc_LA*100;
counts.left_choice_percentage_left_small_suc_LA      = counts.left_choice_ratio_left_small_suc_LA*100;



% percentage of right selected all right arm
counts.right_choice_percentage_right_large_RA          = counts.right_choice_ratio_right_large_RA*100;
counts.right_choice_percentage_right_normal_RA         = counts.right_choice_ratio_right_normal_RA*100;
counts.right_choice_percentage_right_small_RA          = counts.right_choice_ratio_right_small_RA*100;
% percentage of right selected aborted right arm
counts.right_choice_percentage_right_large_abo_RA      = counts.right_choice_ratio_right_large_abo_RA*100;
counts.right_choice_percentage_right_normal_abo_RA     = counts.right_choice_ratio_right_normal_abo_RA*100;
counts.right_choice_percentage_right_small_abo_RA      = counts.right_choice_ratio_right_small_abo_RA*100;
% percentage of right selected success right arm
counts.right_choice_percentage_right_large_suc_RA      = counts.right_choice_ratio_right_large_suc_RA*100;
counts.right_choice_percentage_right_normal_suc_RA     = counts.right_choice_ratio_right_normal_suc_RA*100;
counts.right_choice_percentage_right_small_suc_RA      = counts.right_choice_ratio_right_small_suc_RA*100;

% percentage of left selected all right arm
counts.left_choice_percentage_left_large_RA          = counts.left_choice_ratio_left_large_RA*100;
counts.left_choice_percentage_left_normal_RA         = counts.left_choice_ratio_left_normal_RA*100;
counts.left_choice_percentage_left_small_RA          = counts.left_choice_ratio_left_small_RA*100;
% percentage of left selected aborted right arm
counts.left_choice_percentage_left_large_abo_RA      = counts.left_choice_ratio_left_large_abo_RA*100;
counts.left_choice_percentage_left_normal_abo_RA     = counts.left_choice_ratio_left_normal_abo_RA*100;
counts.left_choice_percentage_left_small_abo_RA      = counts.left_choice_ratio_left_small_abo_RA*100;
% percentage of left selected success right arm
counts.left_choice_percentage_left_large_suc_RA      = counts.left_choice_ratio_left_large_suc_RA*100;
counts.left_choice_percentage_left_normal_suc_RA     = counts.left_choice_ratio_left_normal_suc_RA*100;
counts.left_choice_percentage_left_small_suc_RA      = counts.left_choice_ratio_left_small_suc_RA*100;



% both hands
counts.sac_ushoot_l     = sum([binary.sac_us_l]);
counts.sac_ushoot_r     = sum([binary.sac_us_r]);
counts.sac_oshoot_l     = sum([binary.sac_os_l]);
counts.sac_oshoot_r     = sum([binary.sac_os_r]);
counts.sac_doesntgo     = sum([binary.sac_doesntgo]);
counts.sac_nottotarget  = sum([binary.sac_nottotarget]);

counts.rea_ushoot_l     = sum([binary.rea_us_l]);
counts.rea_ushoot_r     = sum([binary.rea_us_r]);
counts.rea_oshoot_l     = sum([binary.rea_os_l]);
counts.rea_oshoot_r     = sum([binary.rea_os_r]);
counts.rea_doesntgo     = sum([binary.rea_doesntgo]);
counts.rea_nottotarget  = sum([binary.rea_nottotarget]);

% right hand
counts.rea_ushoot_rh_l      = sum([binary.right_hand] & [binary.rea_us_l]);
counts.rea_ushoot_rh_r      = sum([binary.right_hand] & [binary.rea_us_r]);
counts.rea_oshoot_rh_l      = sum([binary.right_hand] & [binary.rea_os_l]);
counts.rea_oshoot_rh_r      = sum([binary.right_hand] & [binary.rea_os_r]);
counts.rea_doesntgo_rh      = sum([binary.right_hand] & [binary.rea_doesntgo]);
counts.rea_nottotarget_rh   = sum([binary.right_hand] & [binary.rea_nottotarget]);

counts.sac_ushoot_rh_l      = sum([binary.right_hand] & [binary.sac_us_l]);
counts.sac_ushoot_rh_r      = sum([binary.right_hand] & [binary.sac_us_r]);
counts.sac_oshoot_rh_l      = sum([binary.right_hand] & [binary.sac_os_l]);
counts.sac_oshoot_rh_r      = sum([binary.right_hand] & [binary.sac_os_r]);
counts.sac_doesntgo_rh      = sum([binary.right_hand] & [binary.sac_doesntgo]);
counts.sac_nottotarget_rh   = sum([binary.right_hand] & [binary.sac_nottotarget]);

% left hand
counts.rea_ushoot_lh_l      = sum([binary.left_hand] & [binary.rea_us_l]);
counts.rea_ushoot_lh_r      = sum([binary.left_hand] & [binary.rea_us_r]);
counts.rea_oshoot_lh_l      = sum([binary.left_hand] & [binary.rea_os_l]);
counts.rea_oshoot_lh_r      = sum([binary.left_hand] & [binary.rea_os_r]);
counts.rea_doesntgo_lh      = sum([binary.left_hand] & [binary.rea_doesntgo]);
counts.rea_nottotarget_lh   = sum([binary.left_hand] & [binary.rea_nottotarget]);

counts.sac_ushoot_lh_l      = sum([binary.left_hand] & [binary.sac_us_l]);
counts.sac_ushoot_lh_r      = sum([binary.left_hand] & [binary.sac_us_r]);
counts.sac_oshoot_lh_l      = sum([binary.left_hand] & [binary.sac_os_l]);
counts.sac_oshoot_lh_r      = sum([binary.left_hand] & [binary.sac_os_r]);
counts.sac_doesntgo_lh      = sum([binary.left_hand] & [binary.sac_doesntgo]);
counts.sac_nottotarget_lh   = sum([binary.left_hand] & [binary.sac_nottotarget]);

% aborted states

end

function [statistic, correlation] = saccade_reach_correlation(keys,reaches,saccades,task,selected,logidx)

if nargin<6
   logidx=struct; 
end

correlation_conditions= keys.calc_val.correlation_conditions;
parameters_to_correlate= keys.calc_val.parameters_to_correlate;
Unique_values={};

        statistic=struct();
        correlation=struct();
for c=1:numel(correlation_conditions)
    condition=correlation_conditions{c};
    if isfield(saccades,condition)
        sel_struct.(condition)=[saccades.(condition)];
    elseif isfield(reaches,condition)
        sel_struct.(condition)=[reaches.(condition)];
    elseif isfield(task,condition)
        sel_struct.(condition)=[task.(condition)];
    elseif isfield(logidx,condition)
        sel_struct.(condition)=[logidx.(condition)];
    else
        Unique_values{c}=NaN;
        continue;
    end 
    
    Unique_values{c}=unique([sel_struct.(condition)]);
    Unique_values{c}=Unique_values{c}(~isnan(Unique_values{c}));
    
    if isempty(Unique_values{c})
        Unique_values{c}=NaN;
    end
end
selection_matrix=combvec(Unique_values{:}); %....

runs=[selected.run];
sessions=[selected.session];
[unique_runs]=unique([sessions',runs'],'rows');
for sel=1:size(selection_matrix,2)
    if ~isempty(saccades)
        idx{sel}=true(size(saccades))';
    else
        idx{sel}=[];
    end
    for c=1:size(selection_matrix,1)
        condition=correlation_conditions{c};
        value=selection_matrix(c,sel);
        statistic(sel).conditions.(condition)=value;
        correlation(sel).conditions.(condition)=value;
        if ~isnan(value)
            idx{sel}=idx{sel} & [sel_struct.(condition)]==value;
        end        
    end
    for p=1:numel(parameters_to_correlate)
        par=parameters_to_correlate{p};
        idx_sac = idx{sel} & ~isnan([saccades.(par)]);
        idx_rea = idx{sel} & ~isnan([reaches.(par)]);
        idx_sac_rea = idx_sac & idx_rea;
        
        statistic(sel).(['sac_' par]).residuals=[];
        statistic(sel).(['rea_' par]).residuals=[];
        statistic(sel).(['sac_' par '_cor']).residuals=[];
        statistic(sel).(['rea_' par '_cor']).residuals=[];
        
        for run=1:size(unique_runs,1)
                         idx_run= sessions==unique_runs(run,1) & runs==unique_runs(run,2);
            %             [statistic(sel).(['sac_' par]).residuals] = [statistic(sel).(['sac_' par]).residuals; residuals_ignoring_empties([saccades(idx_sac & idx_run).(par)]',find(idx_sac(idx_run))')];
            %             [statistic(sel).(['rea_' par]).residuals] = [statistic(sel).(['rea_' par]).residuals; residuals_ignoring_empties([reaches(idx_rea & idx_run).(par)]',find(idx_rea(idx_run))')];
            %             [statistic(sel).(['sac_' par '_cor']).residuals] = [statistic(sel).(['sac_' par '_cor']).residuals; residuals_ignoring_empties([saccades(idx_sac_rea & idx_run).(par)]',find(idx_sac_rea(idx_run))')];
            %             [statistic(sel).(['rea_' par '_cor']).residuals] = [statistic(sel).(['rea_' par '_cor']).residuals; residuals_ignoring_empties([reaches(idx_sac_rea & idx_run).(par)]',find(idx_sac_rea(idx_run))')];

            [statistic(sel).(['sac_' par]).residuals] = [statistic(sel).(['sac_' par]).residuals; residuals_ignoring_empties([saccades(idx{sel}& idx_run).(par)]',find(idx{sel}(idx_run))')];
            [statistic(sel).(['rea_' par]).residuals] = [statistic(sel).(['rea_' par]).residuals; residuals_ignoring_empties([reaches(idx{sel}& idx_run).(par)]',find(idx{sel}(idx_run))')];
            [statistic(sel).(['sac_' par '_cor']).residuals] = [statistic(sel).(['sac_' par '_cor']).residuals; residuals_ignoring_empties([saccades(idx_sac_rea & idx_run).(par)]',find(idx_sac_rea(idx_run))')];
            [statistic(sel).(['rea_' par '_cor']).residuals] = [statistic(sel).(['rea_' par '_cor']).residuals; residuals_ignoring_empties([reaches(idx_sac_rea & idx_run).(par)]',find(idx_sac_rea(idx_run))')];
            
        end
        [correlation(sel).([par '_r']),correlation(sel).([par '_p']),correlation(sel).([par '_slo']),correlation(sel).([par '_int'])] = corr_ignoring_empties([saccades(idx_sac_rea).(par)],[reaches(idx_sac_rea).(par)],keys.calc_val.correlation_mode,keys.calc_val.remove_outliers);
        %[correlation(sel).([par '_raw_sac_rea'])] = [[saccades(idx_sac_rea).(par)]; [reaches(idx_sac_rea).(par)]];
        [correlation(sel).([par '_raw_sac_rea'])] = [[saccades(idx{sel}).(par)]; [reaches(idx{sel}).(par)]];
        [correlation(sel).([par '_r_residuals']),correlation(sel).([par '_p_residuals']),correlation(sel).([par '_slo_residuals']),correlation(sel).([par '_int_residuals'])] = corr_ignoring_empties(statistic(sel).(['sac_' par  '_cor']).residuals',statistic(sel).(['rea_' par  '_cor']).residuals',keys.calc_val.correlation_mode,keys.calc_val.remove_outliers);
        [correlation(sel).([par '_residuals_sac_rea'])]  = [statistic(sel).(['sac_' par]).residuals'; statistic(sel).(['rea_' par]).residuals'];
        [correlation(sel).([par '_difference_sac_rea'])]  = [reaches(idx_sac_rea).(par)] - [saccades(idx_sac_rea).(par)];
    end
end
end


%% combvec

function y = combvec(varargin)
%COMBVEC Create all combinations of vectors.
%
%  <a href="matlab:doc combvec">combvec</a>(A1,A2,...) takes any number of inputs A, where each Ai has
%  Ni columns, and return a matrix of (N1*N2*...) column vectors, where
%  the columns consist of all combinations found by combining one column
%  vector from each Ai.
%
%  For instance, here the four combinations of two 2-column matrices are
%  found.
%  
%    a1 = [1 2 3; 4 5 6];
%    a2 = [7 8; 9 10];
%    a3 = <a href="matlab:doc combvec">combvec</a>(a1,a2)

% Mark Beale, 12-15-93
% Copyright 1992-2010 The MathWorks, Inc.
% $Revision: 1.1.10.2 $  $Date: 2010/04/24 18:07:52 $

if length(varargin) == 0
    y = [];
else
    y = varargin{1};
    for i=2:length(varargin)
        z = varargin{i};
        y = [copy_blocked(y,size(z,2)); copy_interleaved(z,size(y,2))];
    end
end
end

function b = copy_blocked(m,n)

[mr,mc] = size(m);
b = zeros(mr,mc*n);
ind = 1:mc;
for i=[0:(n-1)]*mc
  b(:,ind+i) = m;
end
end

function b = copy_interleaved(m,n)

[mr,mc] = size(m);
b = zeros(mr*n,mc);
ind = 1:mr;
for i=[0:(n-1)]*mr
  b(ind+i,:) = m;
end
b = reshape(b,mr,n*mc);
end


%% Plotting functions

function descriptions = load_descriptions(task,states,binary,varargin)
n_trials=numel(task);

global MA_STATES
STATE_matrix = repmat(MA_STATES.ALL,n_trials,1);
type_matrix  = [1 2 2.5 3 4 5 6];

empty_cell   = repmat({''},n_trials,1);

descriptions=struct('choice', empty_cell, 'task', empty_cell, 'aborted', empty_cell,'state_observed', empty_cell,...
    'sacc_onset', empty_cell, 'runname', empty_cell, 'abort_code', empty_cell);

effector_details    = {' saccade', ' free gaze reaching', ' joint movement', ' saccade with fixed hand position', ' reaching with eye fixation', '', ' free gaze reach with fixation'};
type_details        = {' fixation only', ' direct', ' semi memory', ' memory', ' delayed', ' M2S', ' M2S masked'};

choice_detail       = {' instructed', ' choice'};
task_type_num=[task.type];
for k=1:n_trials
    %task_type_bin(k)=type_matrix==task_type_num(k)
    task_type(k)           = type_details(type_matrix==task_type_num(k));
end
task_type=task_type';

task_effector       = effector_details([task.effector]+1)';
task_description    = strcat(task_type, task_effector);

[n_state_obs,~]=find(ismember(STATE_matrix',[states.state_obs]'));
[n_aborted_state,~]=find(STATE_matrix'==ones(size(STATE_matrix,2),1)*[states.state_abo]);
[n_sac_state,~]=find(ismember(STATE_matrix',[states.state_sac]'));

[descriptions.choice]           = choice_detail{[binary.choice]+1};
[descriptions.task]             = task_description{:};
[descriptions.abort_code]       = task.abort_code;
[descriptions.aborted]          = MA_STATES.ALL_NAMES{n_aborted_state};
[descriptions.state_observed]   = MA_STATES.ALL_CHANGE_NAMES{n_state_obs};

if ~isempty(n_sac_state)
    %     sacconsetdescriptions=cellstr(MA_STATES.ALL_NAMES(n_sac_state));
    % [descriptions.sacc_onset]       = sacconsetdescriptions{:};
    [descriptions.sacc_onset]       = MA_STATES.ALL_NAMES{n_sac_state};
else
    [descriptions.sacc_onset]       = empty_cell{:};
end
if numel(varargin) > 0
    [descriptions.runname]          = deal(varargin);
end
end

function monkeypsych_plot_trial(out,trial,plotoptions,filename)
saccades     = out.saccades;
reaches      = out.reaches;
selected     = out.selected;
task         = out.task;
states       = out.states;
binary       = out.binary;

X_time_lim=0;
for n=1:numel(trial)
    X_time_lim=ceil(max(trial(n).time_axis(end),X_time_lim));
end
descriptions = load_descriptions(task,states,binary,filename);

global P_par MA_STATES

state_to_start_with=1;
if ~plotoptions.show_trial_ini
    state_to_start_with=2;
end

circle_xy = exp(1i*(0:0.02:2 * pi));
amount_of_selected_trials=numel(selected);
trial_figure=figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf, 'Renderer', 'zbuffer');
n=1;
while n <= amount_of_selected_trials
    
    %hand used printout ???? add info about sensors
    if trial(n).effector == 0
        r_hand = 'right eye recorded';
    elseif trial(n).reach_hand == 1
        r_hand = 'left hand, right eye recorded';
    elseif trial(n).reach_hand == 2
        r_hand = 'right hand, right eye recorded';
    else
        r_hand = 'no hand specified, right eye recorded';
    end
    
    if isfield(trial(n),'microstim') && trial(n).microstim == 1,
        stimulation_start = trial(n).microstim_start;
        stimulation_end   = trial(n).microstim_end;
        stimulation_state = trial(n).microstim_state;
        train_duration = 0.2;
    end
    if isfield(trial(n),'microstim') && trial(n).microstim == 1 && any(trial(n).state == trial(n).microstim_state)
        stimulated_state        = trial(n).time_axis(trial(n).state == trial(n).microstim_state);
        times.stimulation_onset = trial(n).microstim_start + stimulated_state(1);
        times.stimulation_end   = trial(n).microstim_end + stimulated_state(1);
    end
    if plotoptions.show_trial_ini
        idx_i=trial(n).state_i>=0;
        idx_r=trial(n).state>=0;
    else
        idx_i=trial(n).state_i>=3;
        idx_r=trial(n).state>=3;
    end
    
    states_in_order=trial(n).state([true; diff(trial(n).state)~=0]);
    [allstates,unique_state_indexes]=unique(states_in_order);
    unique_state_indexes=sort(unique_state_indexes(unique_state_indexes>=state_to_start_with));
    Colors_used=jet(numel(allstates));
    [~, state_order]=ismember(states_in_order,allstates');
    state_colors=Colors_used(state_order,:);
    
    sph(1)=subplot(5, 4, [1 2]);cla
    set(gca,'XTick',[],'YTick',[],'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    
    %state changes
    if isfield(trial,'TDT_stat')
        times.TDT_samplestoshow_stat   = size(trial(n).TDT_stat,2);
        times.state_changes_TDT        = trial(n).time_axis([0;diff(trial(n).state)]~=0)';
    end
    times.state_changes            = trial(n).time_axis([1;diff(trial(n).state)]~=0)';
    times.state_changes_x          = NaN(length(times.state_changes),2)';
    times.state_changes_y          = NaN(length(times.state_changes),2)';
    times.state_changes_x(1:2:end) = times.state_changes;
    times.state_changes_x(2:2:end) = times.state_changes;
    times.state_changes_y(1:2:end) = P_par.ylim(1) * ones(size(times.state_changes));
    times.state_changes_y(2:2:end) = P_par.ylim(2) * ones(size(times.state_changes));
    
    %sample rate
    sample_rate=[NaN diff(trial(n).time_axis)'];
    p_sample_rate = plot(trial(n).time_axis(idx_r), sample_rate(idx_r));
    P_options('Sampling rate','','Time between samples(s)',[0 X_time_lim], [0 max(diff(trial(n).time_axis))]);
    set(p_sample_rate, 'LineWidth', P_par.LineWidth);
    
    
    % hand position
    sph(2)=subplot(5,4,[5 6]);cla;hold on
    %set(gca,'colororder',[P_par.hor_color;P_par.ver_color;state_colors; 0 0 0; 1 0 0; 1 0 0]);
    
    plot(trial(n).time_axis(idx_r),trial(n).x_hnd(idx_r),'-','MarkerSize',P_par.MarkerSize, 'Color', P_par.hor_color,'LineWidth',P_par.LineWidth);
    plot(trial(n).time_axis(idx_r),trial(n).y_hnd(idx_r),'-','MarkerSize',P_par.MarkerSize, 'Color', P_par.ver_color,'LineWidth',P_par.LineWidth);
    for Line_n=1:numel(state_order)
        line(times.state_changes_x(:,Line_n),times.state_changes_y(:,Line_n),'Color',state_colors(Line_n,:),'LineWidth',P_par.LineWidth);
    end
    %     reaches
    line([reaches(n).ini_fix reaches(n).ini_fix], P_par.ylim, 'Color', [0.5 0.5 0.5], 'LineWidth', P_par.LineWidth);
    line([reaches(n).ini reaches(n).ini], P_par.ylim, 'Color', [0 0 0], 'LineWidth', P_par.LineWidth);
    line([reaches(n).end_stat reaches(n).end_stat], P_par.ylim, 'Color', [0 0 0], 'LineWidth', P_par.LineWidth);
    
    %text(3,5,['position of hand target selected ', sprintf('%.0f',[real(reaches(n).tar_pos) imag(reaches(n).tar_pos)]) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    if isfield(trial,'microstim') && trial(n).microstim == 1,
        text(3,0,['stimulation start ', sprintf('%.3f',stimulation_start) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(3,-5,['stimulation end ', sprintf('%.3f',stimulation_end) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(3,-10,['stimulation state ', sprintf('%.3f',stimulation_state) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    end
    
    P_options('Hand position','','Position (degrees)',[0 X_time_lim],P_par.ylim)
    title([get(get(gca, 'title'), 'String') sprintf(', reaction time %.3f s, movement duration %.3f s',  reaches(n).lat, reaches(n).dur)], 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    legend('x axis','y axis');
    axis([0 X_time_lim P_par.ylim])
    set(gca,'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    
    % eye position
    sph(3)=subplot(5, 4, [9 10]);cla;hold on
    
    plot(trial(n).time_axis_i(idx_i), trial(n).x_eye_i(idx_i), 'Color', P_par.hor_color, 'LineWidth', P_par.LineWidth);
    plot(trial(n).time_axis_i(idx_i), trial(n).y_eye_i(idx_i), 'Color', P_par.ver_color, 'LineWidth', P_par.LineWidth);
    plot(trial(n).time_axis(idx_r), trial(n).x_eye(idx_r), 'Color', P_par.hor_color);
    plot(trial(n).time_axis(idx_r), trial(n).y_eye(idx_r), 'Color', P_par.ver_color);
    for Line_n=1:numel(state_order)
        line(times.state_changes_x(:,Line_n),times.state_changes_y(:,Line_n),'Color',state_colors(Line_n,:),'LineWidth',P_par.LineWidth);
    end
    %     saccades
    sac_2bo_idx=saccades(n).ini_all >= states(n).start_2bo & saccades(n).ini_all < states(n).start_1bo ;
    sac_1bo_idx=saccades(n).ini_all >= states(n).start_1bo & saccades(n).ini_all < states(n).start_obs ;
    sac_obs_idx=saccades(n).ini_all >= states(n).start_obs & saccades(n).ini_all < states(n).start_1ao ;
    sac_1ao_idx=saccades(n).ini_all >= states(n).start_1ao;
    nsacc_2bo=sum(sac_2bo_idx);
    nsacc_1bo=sum(sac_1bo_idx);
    nsacc_obs=sum(sac_obs_idx);
    nsacc_1ao=sum(sac_1ao_idx);
    line([saccades(n).ini_all(sac_2bo_idx); saccades(n).ini_all(sac_2bo_idx)], P_par.ylim'*ones(1,nsacc_2bo), 'Color', [0.8 0.8 0.8], 'LineWidth', P_par.LineWidth);
    line([saccades(n).end_all(sac_2bo_idx); saccades(n).end_all(sac_2bo_idx)], P_par.ylim'*ones(1,nsacc_2bo), 'Color', [0.8 0.8 0.8], 'LineWidth', P_par.LineWidth);
    line([saccades(n).ini_all(sac_1bo_idx); saccades(n).ini_all(sac_1bo_idx)], P_par.ylim'*ones(1,nsacc_1bo), 'Color', [0.6 0.6 0.6], 'LineWidth', P_par.LineWidth);
    line([saccades(n).end_all(sac_1bo_idx); saccades(n).end_all(sac_1bo_idx)], P_par.ylim'*ones(1,nsacc_1bo), 'Color', [0.6 0.6 0.6], 'LineWidth', P_par.LineWidth);
    line([saccades(n).ini_all(sac_obs_idx); saccades(n).ini_all(sac_obs_idx)], P_par.ylim'*ones(1,nsacc_obs), 'Color', [0.4 0.4 0.4],   'LineWidth', P_par.LineWidth);
    line([saccades(n).end_all(sac_obs_idx); saccades(n).end_all(sac_obs_idx)], P_par.ylim'*ones(1,nsacc_obs), 'Color', [0.4 0.4 0.4],   'LineWidth', P_par.LineWidth);
    line([saccades(n).ini_all(sac_1ao_idx); saccades(n).ini_all(sac_1ao_idx)], P_par.ylim'*ones(1,nsacc_1ao), 'Color', [0.4 0.4 0.4],   'LineWidth', P_par.LineWidth);
    line([saccades(n).end_all(sac_1ao_idx); saccades(n).end_all(sac_1ao_idx)], P_par.ylim'*ones(1,nsacc_1ao), 'Color', [0.4 0.4 0.4],   'LineWidth', P_par.LineWidth);
    line([saccades(n).lat+states(n).start_sac; saccades(n).lat+states(n).start_sac], P_par.ylim'*ones(1,1), 'Color', [0 0 0],   'LineWidth', P_par.LineWidth);
    
    if isfield(trial(n), 'microstim_state') && any(trial(n).state == trial(n).microstim_state)
%        line([saccades(n).ini_evo+times.stimulation_onset; saccades(n).ini_evo+times.stimulation_onset], P_par.ylim'*ones(1,nsacc), 'Color', [0 0 0],   'LineWidth', P_par.LineWidth);
    end
    if isfield(trial,'microstim') && trial(n).microstim == 1 && ~isempty(trial(n).time_axis(trial(n).state == trial(n).microstim_state))
        t=times.stimulation_onset;
        while t<times.stimulation_end
            rectangle('Position',[t P_par.ylim(1) train_duration P_par.ylim(2)*2],'EdgeColor','c','LineWidth',2,'LineStyle','--')
            t=t+trial(n).microstim_interval;
        end
    end
    
    %text(3,5,['position of eye target selected ', sprintf('%.0f',[real(saccades(n).tar_pos) imag(saccades(n).tar_pos)]) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    P_options('Eye position','','Position (degrees)',[0 X_time_lim],P_par.ylim)
    title([get(get(gca, 'title'), 'String') sprintf(', reaction time %.3f s, movement duration %.3f s', saccades(n).lat, saccades(n).dur)], 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    legend('x axis', 'y axis');
    axis([0 X_time_lim P_par.ylim]);
    set(gca, 'FontName', P_par.FontName, 'FontSize', P_par.FontSize);
    
    % eye velocity
    sph(4)=subplot(5, 4, [13 14]);cla
    p_e_v = plot(trial(n).time_axis_i(idx_i), trial(n).eye_vel_i(idx_i), 'Color', [0 0 0]);
    
    title('Eye velocity', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    xlabel('', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    ylabel('Velocity(deg/s)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    set(gca, 'Xlim', [0 X_time_lim], 'FontName', P_par.FontName, 'FontSize', P_par.FontSize)
    title([get(get(gca,'title'), 'String') sprintf(', peak velocity %.3f deg/s, saccade start >= %.0f deg/s, saccade ending <= %.0f deg/s', max(trial(n).eye_vel_i(idx_i)), plotoptions.sac_ini_t, plotoptions.sac_end_t)], 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    line(xlim, [plotoptions.sac_ini_t plotoptions.sac_ini_t], 'Color', [0 0 1], 'LineStyle', ':', 'LineWidth', P_par.LineWidth);
    line(xlim, [plotoptions.sac_end_t plotoptions.sac_end_t], 'Color', [0 0 1], 'LineStyle', ':', 'LineWidth', P_par.LineWidth);
    set(p_e_v, 'LineWidth', P_par.LineWidth);
    
    
    
    % TDT states
    sph(5)=subplot(5,4,[17 18]);cla;hold on
    
    if isfield(trial,'TDT_stat')
        plot((1:times.TDT_samplestoshow_stat)/trial(n).TDT_stat_samplingrate, trial(n).TDT_stat(1:times.TDT_samplestoshow_stat),'-','Color',P_par.ver_color,'MarkerSize',P_par.MarkerSize,'LineWidth',P_par.LineWidth);
        x_onsets_TDT=[trial(n).TDT_state_onsets'; [trial(n).TDT_state_onsets(2:end)' trial(n).TDT_state_onsets(end)]];
        y_states_TDT=[trial(n).TDT_states'; trial(n).TDT_states'];
        
        %plot(trial(n).TDT_state_onsets,trial(n).TDT_states,'r')
        plot(x_onsets_TDT(:),y_states_TDT(:),'r')
        times.state_changes_TDT_x          = NaN(1,length(trial(n).TDT_state_onsets) * 3);
        times.state_changes_TDT_y          = NaN(1,length(trial(n).TDT_state_onsets) * 3);
        times.state_changes_TDT_x(1:3:end) = trial(n).TDT_state_onsets;
        times.state_changes_TDT_x(2:3:end) = trial(n).TDT_state_onsets;
        times.state_changes_TDT_y(1:3:end) = P_par.ylim_states(1) * ones(size(trial(n).TDT_state_onsets));
        times.state_changes_TDT_y(2:3:end) = P_par.ylim_states(2) * ones(size(trial(n).TDT_state_onsets));
        line(times.state_changes_TDT_x,times.state_changes_TDT_y,'LineWidth',P_par.LineWidth, 'Color', 'r');
    end
%     graded_color=NaN(size(trial(n).time_axis_i,1),3);
    for Line_n=1:numel(state_order)
        state_lines(Line_n)=line(times.state_changes_x(:,Line_n),times.state_changes_y(:,Line_n).*3,'Color',state_colors(Line_n,:),'LineWidth',P_par.LineWidth);
%         graded_color(trial(n).time_axis_i >= times.state_changes_x(1,Line_n),1) = state_colors(Line_n,1);
%         graded_color(trial(n).time_axis_i >= times.state_changes_x(1,Line_n),2) = state_colors(Line_n,2);
%         graded_color(trial(n).time_axis_i >= times.state_changes_x(1,Line_n),3) = state_colors(Line_n,3);
    end
    
    legend1=legend(state_lines(unique_state_indexes),(MA_STATES.LABELS{ismember(MA_STATES.ALL,states_in_order(state_to_start_with:end))}),'Location', 'NorthEast');
    newPosition = [0.55 0.7 0.2 0.2]; %x_pos y_pos width height % all in proportion to figure size
    set(legend1,'Position', newPosition,'Units', 'normalized');
    
    %     reaches
    line([reaches(n).ini_fix reaches(n).ini_fix], P_par.ylim_states, 'Color', [0 0 0], 'LineWidth', P_par.LineWidth);
    line([reaches(n).ini reaches(n).ini], P_par.ylim_states, 'Color', [0 0 0], 'LineWidth', P_par.LineWidth);
    line([reaches(n).end_stat reaches(n).end_stat], P_par.ylim_states, 'Color', [0 0 0], 'LineWidth', P_par.LineWidth);
    
    if isfield(trial,'microstim') && trial(n).microstim == 1,
        text(3,0,['stimulation start ', sprintf('%.3f',stimulation_start) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(3,-5,['stimulation end ', sprintf('%.3f',stimulation_end) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(3,-10,['stimulation state ', sprintf('%.3f',stimulation_state) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    end
    
    P_options('TDT and Monkeypsych states','Time(s)','',[0 X_time_lim],[P_par.ylim_states])
    title(get(get(gca, 'title'), 'String'), 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %     legend('TDT states','Monkeypsych states');
    axis([0 X_time_lim P_par.ylim_states])
    set(gca,'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    
    linkaxes(sph,'x')
    
    
    % 2D
    subplot(5, 2, [6 8 10]);cla;hold on
    color_circle_2d='g';
    
    eye.pos_do      = plot(NaN, 'r.','MarkerSize',10,'LineWidth',P_par.LineWidth);
    graded_color=jet(numel(trial(n).state_i));
     eye.graded=scatter(trial(n).x_eye_i(trial(n).state_i >= 3 & idx_i), trial(n).y_eye_i(trial(n).state_i >= 3 & idx_i), 10, graded_color(trial(n).state_i >= 3 & idx_i,:) ,'o');
    %eye.pos_li      = plot(trial(n).x_eye_i(trial(n).state_i >= 3 & idx_i), trial(n).y_eye_i(trial(n).state_i >= 3 & idx_i), 'r-','LineWidth',P_par.LineWidth);
    eye.fix_cc      = plot(saccades(n).fix_pos, 'ro','LineWidth',P_par.LineWidth);
    hnd.pos_do      = plot(trial(n).x_hnd(idx_r), trial(n).y_hnd(idx_r), 'g.','LineWidth',P_par.LineWidth);
    hnd.fix_cc      = plot(reaches(n).fix_pos, 'go','LineWidth',P_par.LineWidth);
    %hnd.pos_li      = plot(trial(n).x_hnd(idx_r), trial(n).y_hnd(idx_r), 'g-','LineWidth',P_par.LineWidth);
    eye.pos_bl      = plot(trial(n).x_eye(trial(n).state <= 2 & idx_r), trial(n).y_eye(trial(n).state <= 2 & idx_r), 'k.','LineWidth',P_par.LineWidth);
    eye.tar_cc      = plot(saccades(n).tar_pos, 'ro','LineWidth',P_par.LineWidth);
    hnd.tar_cc      = plot(reaches(n).tar_pos, 'go','LineWidth',P_par.LineWidth);
    eye.tar_nc_cc   = plot(saccades(n).nct_pos, 'ko','LineWidth',P_par.LineWidth);
    hnd.tar_nc_cc   = plot(reaches(n).nct_pos, 'ko','LineWidth',P_par.LineWidth);
    
    eye.fix_ci      = plot(saccades(n).fix_rad*circle_xy + saccades(n).fix_pos, 'r','LineWidth',P_par.LineWidth -1);                   % eye fixation
    hnd.fix_ci      = plot(reaches(n).fix_rad*circle_xy + reaches(n).fix_pos, color_circle_2d,'LineWidth',P_par.LineWidth -1);       % hand fixation
    
    
    if (isfield(trial(n).hnd.tar, 'shape') && isfield(trial(n).hnd.tar(1).shape, 'mode') && strcmp(trial(n).hnd.tar(1).shape.mode,'convex')) ||...
       (isfield(trial(n).eye.tar, 'shape') && isfield(trial(n).eye.tar(1).shape, 'mode') && strcmp(trial(n).eye.tar(1).shape.mode,'convex'))
        if isnan(saccades(n).n_targets)
            saccades(n).n_targets=0;
        end
        if isnan(reaches(n).n_targets)
            reaches(n).n_targets=0;
        end
        for c_t=1:saccades(n).n_targets
        size_eye    =trial(n).eye.tar(1).pos(3);
            current_edge_color='k';
            current_face_color={'FaceColor','none'};
            if c_t==trial(n).target_selected(1)
                current_edge_color='r';
            end
            
            if c_t==1
                center=[real(saccades(n).cue_pos(c_t)),imag(saccades(n).cue_pos(c_t))];
                pointList=CalculateConvexPointList(center,size_eye,saccades(n).all_convexities(c_t),saccades(n).all_convex_sides{c_t});
                eye.tar_cc      = patch(pointList(:,1),pointList(:,2),'y','FaceColor','none','EdgeColor','m','LineWidth',P_par.LineWidth -1);
                current_face_color={};
            end
            center=[real(saccades(n).all_tar_pos(c_t)),imag(saccades(n).all_tar_pos(c_t))];
            pointList=CalculateConvexPointList(center,size_eye,saccades(n).all_convexities(c_t),saccades(n).all_convex_sides{c_t});
            eye.tar_nc_cc   = patch(pointList(:,1),pointList(:,2),'y',current_face_color{:},'EdgeColor',current_edge_color,'LineWidth',P_par.LineWidth -1);
            eye.tar_ci      = plot(saccades(n).tar_rad*circle_xy + saccades(n).all_tar_pos(c_t), 'r','LineWidth',P_par.LineWidth -1);
        end
        for c_t=1:reaches(n).n_targets
            size_hand   =trial(n).hnd.tar(1).pos(3);
        
            current_edge_color='k';
            current_face_color={'FaceColor','none'};
            if c_t==trial(n).target_selected(2)
                current_edge_color=color_circle_2d;
            end
            if c_t==1
                center=[real(reaches(n).cue_pos(c_t)),imag(reaches(n).cue_pos(c_t))];
                pointList=CalculateConvexPointList(center,size_eye,reaches(n).all_convexities(c_t),reaches(n).all_convex_sides{c_t});
                hnd.tar_cc      = patch(pointList(:,1),pointList(:,2),'y','FaceColor','none','EdgeColor','m','LineWidth',P_par.LineWidth -1);
                current_face_color={};
            end
            center=[real(reaches(n).all_tar_pos(c_t)),imag(reaches(n).all_tar_pos(c_t))];
            pointList       = CalculateConvexPointList(center,size_hand,reaches(n).all_convexities(c_t),reaches(n).all_convex_sides{c_t});
            hnd.tar_nc_cc   = patch(pointList(:,1),pointList(:,2),'y',current_face_color{:},'EdgeColor',current_edge_color,'LineWidth',P_par.LineWidth -1);
            hnd.tar_ci      = plot(reaches(n).tar_rad*circle_xy + reaches(n).all_tar_pos(c_t), 'r','LineWidth',P_par.LineWidth -1);
        end
    else
        
        eye.tar_ci      = plot(saccades(n).tar_rad*circle_xy + saccades(n).tar_pos, 'r','LineWidth',P_par.LineWidth -1);                % saccade target
        hnd.tar_ci      = plot(reaches(n).tar_rad*circle_xy + reaches(n).tar_pos, color_circle_2d,'LineWidth',P_par.LineWidth -1);      % reach target
        eye.tar_nc_ci   = plot(saccades(n).tar_rad*circle_xy + saccades(n).nct_pos, 'k','LineWidth',P_par.LineWidth -1);                % saccade target
        hnd.tar_nc_ci   = plot(reaches(n).tar_rad*circle_xy + reaches(n).nct_pos, 'k','LineWidth',P_par.LineWidth -1);                  % reach target
    end
    
    
    fix_height=nanmean(imag([saccades(n).fix_pos reaches(n).fix_pos]));
    grid on
    axis equal
    warning('off','MATLAB:hg:patch:RGBColorDataNotSupported');
    P_options('Eye and hand position','x(deg)','y(deg)',[-P_par.screen_w_deg/2 P_par.screen_w_deg/2],[fix_height-P_par.screen_h_deg/2 fix_height+P_par.screen_h_deg/2]);
    legend_handles={eye.pos_bl,eye.pos_do,eye.fix_cc,hnd.pos_do,hnd.fix_cc,eye.tar_nc_cc,hnd.tar_nc_cc};
    description_indexes=cellfun(@(x) ~isempty(x),legend_handles);
    legend_descriptions={'pre fixation eye position','eye position', 'eye allowed radius', 'hand position', 'hand target radius', 'non chosen eye tar', 'non chosen hand tar'};
    legend2=legend([legend_handles{description_indexes}],legend_descriptions(description_indexes), 'Location','SouthEast');
     newPosition = [0.8 0.7 0.1 0.2]; %x_pos y_pos width height % all in proportion to figure size
    set(legend2,'Position', newPosition,'Units', 'normalized');
    
    warning('on','MATLAB:hg:patch:RGBColorDataNotSupported');
    %
    %     subplot(4, 4, [3 7]);cla
    %     hold on
    %     %     reach_trace_3D={};
    %     %     saccade_trace_3D={};
    %
    %     for current_state=state_to_start_with:numel(states_in_order)
    %         N_previous_same_state=sum(states_in_order(1:current_state-1)==states_in_order(current_state))*2;
    %         state_samples=trial(n).state == states_in_order(current_state);
    %         state_sample_indexes=[current_state==1;diff(state_samples)~=0];
    %         %state_sample_indexes(end)=current_state==(numel(states_in_order));
    %         change_to_or_from_state=[find(state_sample_indexes); numel(state_sample_indexes)];
    %         se_idx=change_to_or_from_state([N_previous_same_state+1 N_previous_same_state+2]);
    %         p_3_h(current_state) = plot3(trial(n).x_hnd([se_idx(1):se_idx(2)]),trial(n).y_hnd([se_idx(1):se_idx(2)]),trial(n).time_axis([se_idx(1):se_idx(2)]),'-', 'Color',state_colors(current_state,:),'LineWidth', 2);
    %         %p_3_e = plot3(trial(n).x_eye([se_idx(1):se_idx(2)]),trial(n).y_eye([se_idx(1):se_idx(2)]),trial(n).time_axis([se_idx(1):se_idx(2)]),'-', 'Color',state_colors(current_state,:),'LineWidth', 2);
    %         set(p_3_h(current_state), 'LineWidth', P_par.LineWidth);
    %     end
    %     view([45 45])
    %
    %     xlabel('x(deg)','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName), ylabel('y(deg)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName), zlabel('t(s)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %     axis([P_par.ylim, P_par.ylim, 0, X_time_lim]);
    %     grid on
    %     axis square
    %
    %     title('Hand position' , 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    % %
    % %     legend1=legend(p_3_h(unique_state_indexes),(MA_STATES.LABELS{find(ismember(MA_STATES.ALL,states_in_order(state_to_start_with:end)))}),'Location', 'NorthEast');
    % %     %   set(legend1,'Position',[0.911382978723398 0.644602609727159 0.0796875 0.172597864768683]);
    % %     newPosition = [0.91 0.6 0.08 0.17]; %x_pos y_pos width height % all in proportion to figure size
    % %     set(legend1,'Position', newPosition,'Units', 'normalized');
    %     set(gca,'FontName', P_par.FontName, 'FontSize', P_par.FontSize);
    %
    %     % 3D eye
    %     subplot(4, 4, [4 8]);cla
    %
    %     hold on
    %     for current_state=state_to_start_with:numel(states_in_order)
    %         N_previous_same_state=sum(states_in_order(1:current_state-1)==states_in_order(current_state))*2;
    %         state_samples=trial(n).state == states_in_order(current_state);
    %         state_sample_indexes=[current_state==1;diff(state_samples)~=0];
    %         %state_sample_indexes(end)=current_state==(numel(states_in_order));
    %         change_to_or_from_state=[find(state_sample_indexes); numel(state_sample_indexes)];
    %         se_idx=change_to_or_from_state([N_previous_same_state+1 N_previous_same_state+2]);
    %         p_3_e = plot3(trial(n).x_eye([se_idx(1):se_idx(2)]),trial(n).y_eye([se_idx(1):se_idx(2)]),trial(n).time_axis([se_idx(1):se_idx(2)]),'-', 'Color',state_colors(current_state,:),'LineWidth', 2);
    %         set(p_3_e, 'LineWidth', P_par.LineWidth);
    %     end
    %     view([45 45])
    %
    %
    %     xlabel('x(deg)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName), ylabel('y(deg)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName), zlabel('t(s)', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %     %colormap([1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1]);
    %     axis([P_par.ylim, P_par.ylim, 0, X_time_lim]);
    %     grid on
    %     axis square
    %
    %     title('Eye position', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %     set(gca,'FontName', P_par.FontName, 'FontSize', P_par.FontSize);
    %
    %
    
    %Complete figure title definition
    print_out = sprintf('File: %s Trial: %d. Type: %s %s. Effector used: %s. Aborted: %s. ', trial(n).runname,  trial(n).n, descriptions(n).choice, descriptions(n).task, r_hand, descriptions(n).aborted);
    mtit(trial_figure,print_out, 'fontsize', 12, 'color', 'xoff', -0.05, 'yoff', 0.03, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
%    pause;
    waitforbuttonpress;
    current_key=get(gcf,'CurrentCharacter');
    if current_key == 28 || current_key == 30
        n=n-1;%set(gcf,'CurrentCharacter',[]);
    elseif current_key == 29 || current_key == 31
        n=n+1;%set(gcf,'CurrentCharacter',[]);
    elseif current_key == 27
        close(gcf) ;%set(gcf,'CurrentCharacter',[]);
        return;
    end
    %clf;
    
end
clf;

end

function monkeypsych_plot_trial_history(hist_observed_values,hist_past_values,hist_val,varargin)
figure('units','normalized','outerposition',[0 0 1 1]);

subplot(2,5,5)
max_ticks=40; %% very important value: Resolution!!
% hist_observed_values=[out_o.selected.current_hist_values];
% hist_past_values=[out_bo.selected.past_hist_values_tmp];

X=hist_past_values;
Y=hist_observed_values;
uniqueX=unique(X(~isnan(X)));
uniqueY=unique(Y(~isnan(Y)));
n_binsX=numel(uniqueX);
n_binsY=numel(uniqueY);
if n_binsX>=max_ticks
    binsX=min(uniqueX):(max(uniqueX)-min(uniqueX))/max_ticks:max(uniqueX);
else
    binsX=uniqueX;
end
if n_binsY>=max_ticks
    binsY=min(uniqueY):(max(uniqueY)-min(uniqueY))/max_ticks:max(uniqueY);
else
    binsY=uniqueY;
end

[historyplot,historyplot_normalized]=hist2Dd(X,Y,binsX,binsY);
%         n_valid_trials=sum(sum(historyplot));
historypattern=flipud(historyplot_normalized');
colormap(jet(100))
histplt=imagesc(historypattern);
colormap(jet(100))

ticks_X=1:numel(binsX);
ticks_Y=1:numel(binsY);
ticklabel_X=binsX(:);
ticklabel_Y=flipud(binsY(:));
if islogical(ticklabel_X)
    ticklabel_X=double(ticklabel_X);
end
if islogical(ticklabel_Y)
    ticklabel_Y=double(ticklabel_Y);
end





text(1,1,num2str(flipud(historyplot')))


set(gca,'Xtick',ticks_X,'Ytick',ticks_Y,'Xticklabel',ticklabel_X,'Yticklabel',ticklabel_Y)
xlabel([hist_val.past_parameter, ' ', sprintf('%u',hist_val.n_trials_past), ' trials before'],'interpreter','none');
ylabel([hist_val.current_parameter, ' in current trial'],'interpreter','none');


subplot(2,5,1:4)

if isnan(hist_val.current_value)
    timecourse_o = hist_observed_values;
else
    timecourse_o = hist_observed_values==hist_val.current_value;
end
if isnan(hist_val.past_value)
    timecourse_bo= hist_past_values;
else
    timecourse_bo= hist_past_values==hist_val.past_value;
end
smoothingwindowsize=9;
matrixsize=numel(timecourse_o);
Smoothing_matrix_gen=eye(matrixsize);
Smoothing_matrix=Smoothing_matrix_gen;
for k=1:(smoothingwindowsize-1)/2
    Smoothing_matrix=Smoothing_matrix+circshift(Smoothing_matrix_gen,k);
    Smoothing_matrix=Smoothing_matrix+circshift(Smoothing_matrix_gen,-k);
end
Smoothing_matrix(1:smoothingwindowsize-1/2,matrixsize-(smoothingwindowsize-1/2):matrixsize)=0;
Smoothing_matrix(matrixsize-(smoothingwindowsize-1/2):matrixsize,1:smoothingwindowsize-1/2)=0;

Smoothing_matrix=Smoothing_matrix./smoothingwindowsize;
timecourse_o_nonan=timecourse_o;
timecourse_bo_nonan=timecourse_bo;
timecourse_o_nonan(isnan(timecourse_o))=0;
timecourse_bo_nonan(isnan(timecourse_bo))=0;

window_time_course_o=Smoothing_matrix*timecourse_o_nonan(:);
window_time_course_bo=Smoothing_matrix*timecourse_bo_nonan(:);
window_time_course_o(isnan(timecourse_o))=NaN;
window_time_course_bo(isnan(timecourse_bo))=NaN;
smooth_time_course_o=filter_et((Smoothing_matrix*timecourse_o(:))',10);
smooth_time_course_bo=filter_et((Smoothing_matrix*timecourse_bo(:))',10);


hold on
LineWidth=3;
%plot(cumulate_o(smoothingwindowsize:end));
plot(window_time_course_o)
plot(smooth_time_course_o)

if numel(varargin)>0
    ylim=[min(window_time_course_o); max(window_time_course_o)];
    rundescriptions=varargin{1};
    plot([rundescriptions.run_ends;rundescriptions.run_ends],         ylim*ones(1,numel(rundescriptions.run_ends)) ,    'Color', [0 0 1], 'LineWidth', LineWidth);
    plot([rundescriptions.session_ends;rundescriptions.session_ends], ylim*ones(1,numel(rundescriptions.session_ends)),  'Color', [0 1 0], 'LineWidth', LineWidth);
    plot([rundescriptions.monkey_ends;rundescriptions.monkey_ends],   ylim*ones(1,numel(rundescriptions.monkey_ends)), 	'Color', [1 0 0], 'LineWidth', LineWidth);
end
xlabel('trial','interpreter','none');
ylabel([hist_val.current_parameter, ' in current trial'],'interpreter','none');

subplot(2,5,6:9)
hold on
%plot(cumulate_bo(smoothingwindowsize:end));
plot(window_time_course_bo);
plot(smooth_time_course_bo);

if numel(varargin)>0
    ylim=[min(window_time_course_bo); max(window_time_course_bo)];
    rundescriptions=varargin{1};
    plot([rundescriptions.run_ends;rundescriptions.run_ends],         ylim*ones(1,numel(rundescriptions.run_ends)) ,    'Color', [0 0 1], 'LineWidth', LineWidth);
    plot([rundescriptions.session_ends;rundescriptions.session_ends], ylim*ones(1,numel(rundescriptions.session_ends)),  'Color', [0 1 0], 'LineWidth', LineWidth);
    plot([rundescriptions.monkey_ends;rundescriptions.monkey_ends],   ylim*ones(1,numel(rundescriptions.monkey_ends)), 	'Color', [1 0 0], 'LineWidth', LineWidth);
end
xlabel('trial','interpreter','none');
ylabel([hist_val.past_parameter, ' ', sprintf('%u',hist_val.n_trials_past), ' trials before'],'interpreter','none');


end

function pointList=CalculateConvexPointList(center,a_ellipse,convexity,convex_sides)
convexity_sign=sign(convexity);
b_ellipse=abs(convexity)*a_ellipse;
b_ellipse_reference=0.3*a_ellipse;

steps_for_interpolation=100;
euclidian_distance=(-a_ellipse):2*a_ellipse/steps_for_interpolation:(a_ellipse);
%corner_positions=[-1,-1;1,-1;1,1;-1,1].*a_ellipse;

Half_circle_Area=a_ellipse^2*pi/2;
rect_b=(Half_circle_Area-a_ellipse*b_ellipse*pi*convexity_sign/2)/(2*a_ellipse);
rect_b_reference=(Half_circle_Area-a_ellipse*b_ellipse_reference*pi*convexity_sign/2)/(2*a_ellipse);
%rect_ratio=Half_circle_Area/(2*a_ellipse^2);

tmp_bow_parameter=sqrt((b_ellipse)^2.*(1-euclidian_distance'.^2/a_ellipse^2));
tmp_bow_reference=sqrt((b_ellipse_reference)^2.*(1-euclidian_distance'.^2/a_ellipse^2));

bow_vector=[euclidian_distance',(tmp_bow_parameter.*convexity_sign.*-1-rect_b)];
bow_vector_reference=[euclidian_distance',(tmp_bow_reference.*convexity_sign.*-1-rect_b_reference)];

if strcmp(convex_sides,'LR')|| strcmp(convex_sides,'R') || strcmp(convex_sides,'L')
    bow_vector=[bow_vector(:,2)*-1,bow_vector(:,1)];
    bow_vector_reference=[bow_vector_reference(:,2)*-1,bow_vector_reference(:,1)];
    %corner_positions=[corner_positions(:,1)*rect_ratio,corner_positions(:,2)];
else
    %corner_positions=[corner_positions(:,1),corner_positions(:,2)*rect_ratio];
end

switch convex_sides
    case 'T'
        pointList=[bow_vector;bow_vector_reference*-1];
    case 'B'
        pointList=[bow_vector_reference;bow_vector*-1];
    case 'TB'
        pointList=[bow_vector;bow_vector*-1];
    case 'R'
        pointList=[bow_vector;bow_vector_reference*-1];
    case 'L'
        pointList=[bow_vector_reference;bow_vector*-1];
    case 'LR'
        pointList=[bow_vector;bow_vector*-1];
end
%Position_correction=[(max(pointList(:,1))+min(pointList(:,1)))/2,(max(pointList(:,2))+min(pointList(:,2)))/2];
%pointList=pointList+repmat(center-Position_correction,size(pointList,1),1);
pointList=pointList+repmat(center,size(pointList,1),1);
end

%% Formatting and restructuring functions

function filelist_formatted = format_filelist(filelist_unformatted)
id_file=0;
filelist_formatted=repmat({''},numel(filelist_unformatted)-size(filelist_unformatted,1),1);
for id_session = 1: length(filelist_unformatted(:,1));
    d=dir([filelist_unformatted{id_session,1} filesep '*_*.mat']);
    for run_per_session = 1:numel(filelist_unformatted{id_session,2})
        run_number_string=sprintf('%.2d', filelist_unformatted{id_session,2}(run_per_session));
        for id_comp = 1:length(d)
            if strcmp(d(id_comp).name(end-5:end-4),run_number_string)
                run_name = d(id_comp).name;
                id_file=id_file+1;
            end
        end
        try
            filelist_formatted{id_file,1}=[filelist_unformatted{id_session,1} filesep run_name];
        catch
            disp(['No Run ' run_number_string ' in folder ' filelist_unformatted{id_session,1}])
        end
    end
    
end
end

function restructured=restructure_field_indexes(structure_array)
FN=fieldnames(structure_array);
for k=1:numel(FN)
    Cell_to_structure=num2cell(structure_array.(FN{k}));
    if k==1
        restructured=struct(FN{k},Cell_to_structure);
    end
    [restructured.(FN{k})]=Cell_to_structure{:};
end
end

function complex_positions = get_unique_positions_of_trial(trial,eye_or_hnd)
eye_or_hnd_tarpos=[NaN, NaN];
for n=1:numel(trial)
    if isfield(trial(n).(eye_or_hnd), 'tar') && isfield(trial(n).(eye_or_hnd).tar, 'pos') %% to debug new monkeypsysch_test
        eye_or_hnd_tarpos(n,:)=[trial(n).(eye_or_hnd).tar(1).pos(1) trial(n).(eye_or_hnd).tar(1).pos(2)];
    end
end
%
% trial_eye_or_hnd=[trial.(eye_or_hnd)];
% eye_or_hnd_tar=[trial_eye_or_hnd.tar];
% eye_or_hnd_tarpos=vertcat(eye_or_hnd_tar.pos);
unique_target_positions=unique(eye_or_hnd_tarpos(:,1:2),'rows');
complex_positions=unique_target_positions(:,1)+1i*unique_target_positions(:,2);
end

function [combined_struct] = concetenate_structure_array(structure_array)
% Concatenates all substructure arrays of different elements of a structure cell array,
% given that all substructure fields have the same number of elements (for a given element of structure_array):
% combined_struct.fields(1:N_total)=structure_array{1:N_cellelements}.fields(1:N_fieldelements);
Fnames=fieldnames(structure_array(1));
n_rows=size(structure_array,2);
%combined_struct=struct(repmat(Fnames,1,n_rows),);
for k = 1:length(Fnames)
    for m = 1:n_rows
        combined_struct(m).(Fnames{k})=vertcat(structure_array([structure_array(:,m).emptyflag]==0,m).(Fnames{k}));
        if all([structure_array(:,m).emptyflag]==1) %% doublecheck!@!
            combined_struct.(Fnames{k})=vertcat(structure_array.(Fnames{k}));
        end
    end
end
end

function [varagout] = process_varargin(the_keys,default_values,new_varargin)

%%  inputs:
%      the_keys        cell array of keys
%      default_values  default value for each key
%      new_varargin        user inputs to override the defaults
%
%  outputs:
%      creates the_keys variables in the calling program
%      with either the default values or the overrides set
%      optionally will return the_keys and data as a structure
%      if the user supplies a output argument


tmp = [];
n_key = length(the_keys);
n_def = length(default_values);
nvar  = length(new_varargin);

%  make sure we have the correct number
if (n_def ~= n_key)
    fprintf(2,'process_varargin: # of keys ~= # of default values %3d %3d\n',n_key,n_def);
    error('default values error');
end

%  set up the default values
for i=1:n_key
    tmp.(the_keys{i}) = default_values{i};
end

%  user overrides ?
i = 1;
j = 2;
while (i < nvar)
    if  any(ismember(the_keys,new_varargin{i})); %% !!!!!
        tmp.(new_varargin{i}) = new_varargin{j};
    end
    i = i + 2;
    j = j + 2;
end
varagout = tmp;
end

%% Filtering subfunctions

function [x_filt] =  filter_et(x,flen)
% assuming sampling rate 1000 Hz, 500 Hz corresponds to "1.0"
% in cheby2: 0.0 < Wst < 1.0, with 1.0 corresponding to half the sample rate.
% Thus, cutoff at 30 Hz would be Wst = 0.06;
% flen = filter length for calculating runnig ave (samples)
if numel(x)<flen
    flen=numel(x);
end
rav=ones(1,flen)./flen;
x_filt=conv(x,rav);
if flen>1
start_edge_factor=flen./[ceil(flen/2):flen-1];
start_values=x_filt(ceil(flen/2):flen-1).*start_edge_factor;
end_edge_factor=flen./[flen-1:-1:floor(flen/2)];
end_values=x_filt(length(x_filt)+2-flen:length(x_filt)-floor(flen/2)+1).*end_edge_factor;
x_filt=[start_values x_filt(flen:length(x_filt)-flen) end_values]; % Smoothed EyeX
end
end

function [new_pos_x new_pos_y] = offset_corrected(old_pos_x, old_pos_y, state_current, fixation_state_temp, fixation_x, fixation_y)

temp_pos_x=median(old_pos_x(state_current==fixation_state_temp));
temp_pos_y=median(old_pos_y(state_current==fixation_state_temp));

offset_x = abs(temp_pos_x - fixation_x);
offset_y = abs(temp_pos_y - fixation_y);

if temp_pos_x <= fixation_x
    new_pos_x=old_pos_x + offset_x;
elseif temp_pos_x > fixation_x
    new_pos_x=old_pos_x - offset_x;
else
    new_pos_x=old_pos_x;
end

if temp_pos_y <= fixation_y
    new_pos_y=old_pos_y + offset_y;
elseif temp_pos_y > fixation_y
    new_pos_y=old_pos_y - offset_y;
else
    new_pos_y=old_pos_y;
end
end

%% Statistics subfunctions

function [r,sig, slo, int] = corr_ignoring_empties(s1in,s2in,mode,outliers)
s1=s1in(~isnan(s1in)&~isnan(s2in));
s2=s2in(~isnan(s1in)&~isnan(s2in));
if numel(unique(s1))>1 && numel(unique(s2))>1
%     [r,sig] = corr([s1',s2'],'type',mode);
    [slo, int, r, sig] = beh_myregr_eye_hand(s1',s2',0,outliers);
%     r=r(1,2);
%     sig=sig(1,2);
else
    r=NaN;
    sig=NaN;
    slo=NaN;
    int=NaN;
end
end



function [residuals]=residuals_ignoring_empties(y,x)
if numel(x)<=2 || numel(y)<=2 || sum(~isnan(x) & ~isnan(y))<=1
    [residuals]=NaN(size(x));
else
    xx=x(~isnan(x) & ~isnan(y));yy=y(~isnan(x) & ~isnan(y));
     %if numel(xx)>1 && numel(yy)>2
        p=polyfit(xx,yy,1);
        residuals=y-p(1)*x-p(2);
        %[a,~,b,~]=regress(x,y);
%      else
%          [residuals]=NaN(size(x));
%     end
end
end

%% Histogram restructuring functions

function [histogram2Ddiscrete,histogram2Ddiscrete_Normalized,binsA,binsB]=hist2Dd(A,B,binsA,binsB)

if numel(A) ~= numel(B)
    error('A and B must contain the same number of elements')
else
    if nargin == 2
        A=round(1000*A(:))/1000;
        B=round(1000*B(:))/1000;
        uniqueA=unique(A);
        uniqueB=unique(B);
        n_binsA=numel(uniqueA);
        n_binsB=numel(uniqueB);
        binsA=min(uniqueA):(max(uniqueA)-min(uniqueA))/(n_binsA-1):max(uniqueA);
        binsB=min(uniqueB):(max(uniqueB)-min(uniqueB))/(n_binsB-1):max(uniqueB);
    end
    n_binsA=numel(binsA);
    n_binsB=numel(binsB);
    histogram2Ddiscrete=zeros(n_binsA,n_binsB);
    for m=1:n_binsA-1
        for n=1:n_binsB-1
            %histogram2Ddiscrete(m,n)=sum(A==binsA(m)&B==binsB(n));
            if isreal(binsA(m)) && isreal(binsB(n+1))
                histogram2Ddiscrete(m,n)=sum(binsA(m)<=A & A<binsA(m+1)& binsB(n)<=B & B<binsB(n+1));
            elseif ~isreal(binsA(m)) && ~isreal(binsB(n+1))
                histogram2Ddiscrete(m,n)=sum(binsA(m)==A & binsB(n)==B);
            end
        end
        if isreal(binsA(m)) && isreal(binsB(n+1))
            histogram2Ddiscrete(m,n_binsB)=sum(binsA(m)<=A & A<binsA(m+1) & binsB(n_binsB)<=B);
        end
    end
    for n=1:n_binsB-1
        if isreal(binsA(m)) && isreal(binsB(n+1))
            histogram2Ddiscrete(n_binsA,n)=sum(binsA(n_binsA)<=A & binsB(n)<=B & B<binsB(n+1));
        elseif ~isreal(binsA(m)) && ~isreal(binsB(n+1))
            histogram2Ddiscrete(n_binsA,n)=sum(binsA(n_binsA)==A & binsB(n)==B);
        end
    end
    if isreal(binsA(m)) && isreal(binsB(n+1))
        histogram2Ddiscrete(n_binsA,n_binsB)=sum(binsA(n_binsA)<=A & binsB(n_binsB)<=B);
    elseif ~isreal(binsA(m)) && ~isreal(binsB(n+1))
        histogram2Ddiscrete(n_binsA,n_binsB)=sum(binsA(n_binsA)==A & binsB(n_binsB)==B);
    end
    % normalizing...???
    for k=1:n_binsA
        histogram2Ddiscrete_Normalized(k,:)=histogram2Ddiscrete(k,:)./sum(histogram2Ddiscrete(k,:));
    end
end
end

%% Plot formatting subfunctions

function P_options(P_title,P_xlabel,P_ylabel,P_Xlim,P_Ylim)
global P_par;

title(P_title, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
xlabel(P_xlabel, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
ylabel(P_ylabel, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
set(gca, 'FontName', P_par.FontName, 'FontSize', P_par.FontSize, 'Xlim', P_Xlim, 'Ylim', P_Ylim);
end

function par=mtit(varargin)
%MTIT		creates a major title in a figure with many axes
%
%		MTIT
%		- creates a major title above all
%		  axes in a figure
%		- preserves the stack order of
%		  the axis handles
%
%SYNTAX
%-------------------------------------------------------------------------------
%		P = MTIT(TXT,[OPT1,...,OPTn])
%		P = MTIT(FH,TXT,[OPT1,...,OPTn])
%
%INPUT
%-------------------------------------------------------------------------------
%    FH	:	a valid figure handle		[def: gcf]
%   TXT	:	title string
%
% OPT	:	argument
% -------------------------------------------
%  xoff	:	+/- displacement along X axis
%  yoff	:	+/- displacement along Y axis
%  zoff	:	+/- displacement along Z axis
%
%		title modifier pair(s)
% -------------------------------------------
%   TPx	:	TVx
%		see: get(text) for possible
%		     parameters/values
%
%OUTPUT
%-------------------------------------------------------------------------------
% par	:	parameter structure
%  .pos :	position of surrounding axis
%   .oh	:	handle of last used axis
%   .ah :	handle of invisible surrounding axis
%   .th :	handle of main title
%
%EXAMPLE
%-------------------------------------------------------------------------------
%	subplot(2,3,[1 3]);		title('PLOT 1');
%	subplot(2,3,4); 		title('PLOT 2');
%	subplot(2,3,5); 		title('PLOT 3');
%	axes('units','inches',...
%	     'color',[0 1 .5],...
%	     'position',[.5 .5 2 2]);	title('PLOT 41');
%	axes('units','inches',...
%	     'color',[0 .5 1],...
%	     'position',[3.5 .5 2 2]);	title('PLOT 42');
%	shg;
%	p=mtit('the BIG title',...
%	     'fontsize',14,'color',[1 0 0],...
%	     'xoff',-.1,'yoff',.025);
% % refine title using its handle <p.th>
%	set(p.th,'edgecolor',.5*[1 1 1]);

% created:
%	us	24-Feb-2003		/ R13
% modified:
%	us	24-Feb-2003		/ CSSM
%	us	06-Apr-2003		/ TMW
%	us	13-Nov-2009 17:38:17

defunit='normalized';
if	nargout
    par=[];
end

% check input
if	nargin < 1
    help(mfilename);
    return;
end
if	isempty(get(0,'currentfigure'))
    disp('MTIT> no figure');
    return;
end

vl=true(size(varargin));
if	ischar(varargin{1})
    vl(1)=false;
    figh=gcf;
    txt=varargin{1};
elseif	any(ishandle(varargin{1}(:)))		&&...
        ischar(varargin{2})
    vl(1:2)=false;
    figh=varargin{1};
    txt=varargin{2};
else
    error('MTIT> invalid input');
end
vin=varargin(vl);
[off,vout]=get_off(vin{:});

% find surrounding box
ah=findall(figh,'type','axes');
if	isempty(ah)
    disp('MTIT> no axis');
    return;
end
oah=ah(1);

ou=get(ah,'units');
set(ah,'units',defunit);
ap=get(ah,'position');
if	iscell(ap)
    ap=cell2mat(get(ah,'position'));
end
ap=[	min(ap(:,1)),max(ap(:,1)+ap(:,3)),...
    min(ap(:,2)),max(ap(:,2)+ap(:,4))];
ap=[	ap(1),ap(3),...
    ap(2)-ap(1),ap(4)-ap(3)];

% create axis...
xh=axes('position',ap);
% ...and title
th=title(txt,'interpreter', 'none',vout{:});
tp=get(th,'position');
set(th,'position',tp+off);
set(xh,'visible','off','hittest','on');
set(th,'visible','on');

% reset original units
ix=find(~strcmpi(ou,defunit));
if	~isempty(ix)
    for	i=ix(:).'
        set(ah(i),'units',ou{i});
    end
end

% ...and axis' order
uistack(xh,'bottom');
axes(oah);				%#ok

if	nargout
    par.pos=ap;
    par.oh=oah;
    par.ah=xh;
    par.th=th;
end

    function	[off,vout]=get_off(varargin)
        
        % search for pairs <.off>/<value>
        
        off=zeros(1,3);
        io=0;
        for	mode={'xoff','yoff','zoff'};
            ix=strcmpi(varargin,mode);
            if	any(ix)
                io=io+1;
                yx=find(ix);
                ix(yx+1)=1;
                off(1,io)=varargin{yx(end)+1};
                varargin=varargin(xor(ix,1));
            end
        end
        vout=varargin;
    end
end
