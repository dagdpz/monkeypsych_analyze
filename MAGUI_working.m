function MAGUI_working
get_default_key_values


batches=1;
current_batch=1;
dag_drive_IP=DAG_get_server_IP;
current_main_path='';
current_monkey='';
current_sessions={''};
current_sessions_for_runs={''};
current_runs={''};
current_file=[];
current_changed_keys={};
current_selected_key={};
%current_key_value=[];
changed_keys={};
Popup_selected_key=struct();
selected_key_value=struct();
Listbox=struct();Edit_box=struct();Checkbox=struct();radio_button=struct();radio_button2=struct();Preset_key_structure=struct();

current_XY_field='tar';
rects_xy=struct('main_paths',{});
current_rect=[];
batch(current_batch)=struct('main_paths',{struct()},'filedisplay',{struct()},'files',{{}},'keys_struct',{struct()},'current_sessions_for_runs',{{}});
filelist_formated={};
filename={};
clean_data=0;
run_protocol=0;

f = figure('Visible','off','units','normalized','outerposition',[0 0 1 1],'name','MAGUI 1.0b (flea)');
Gui_version(0,0,0)

%% Monkey selection
set_listbox('monkey','Monkey',fieldnames(batch(current_batch).filedisplay),'Add monkey','monkey_selection','browse_folder',[0.02,0.55,0.07,0.4]);
%% Session selection
set_listbox('all_sessions','All Sessions',fieldnames(batch(current_batch).filedisplay),'Add sessions','nofunction','select_sessions',[0.1,0.55,0.05,0.4]);
%% Selected Sessions
set_listbox('selected_sessions','Selected Sessions',fieldnames(batch(current_batch).filedisplay),'Remove sessions','added_session_selection','remove_sessions',[0.16,0.55,0.06,0.4]);
%% Run Selection
set_listbox('runs_in_session','Runs in session',fieldnames(batch(current_batch).filedisplay),'Add runs','run_selection','add_runs',[0.23,0.55,0.1,0.4]);
%% Selected Files
set_listbox('filesinbatch','Selected Files',batch(current_batch).files,'Remove files','file_selection','delete_file_from_batch',[0.35,0.55,0.2,0.4]);


%% batch control
uicontrol('Style','text','String','Select Batch','units','normalized','Position',[0.57,0.93,0.05,0.02]);
hbatches = uicontrol('Style','popupmenu','String',num2str(batches),'units','normalized','Position',[0.57,0.9,0.05,0.025],'Callback',@batch_selection);
uicontrol('Style','pushbutton','String','Add batch','units','normalized','Position',[0.57,0.875,0.05,0.025],'Callback',@add_batch);
uicontrol('Style','pushbutton','units','normalized','String','delete batch','Position',[0.57,0.85,0.05,0.025],'Callback',@delete_batch);

%% default keys popup box
set_preset_keys;
default_key_options=fieldnames(Preset_key_structure);
uicontrol('Style','text','units','normalized','String','Key presets','Position',[0.62,0.93,0.05,0.02]);
uicontrol('Style','popupmenu','units','normalized','String',default_key_options,'Position',[0.62,0.9,0.05,0.025],'Callback',@apply_preset_keys);
Preset_key=uicontrol('Style','edit','units','normalized','String','','Position',[0.62,0.875,0.05,0.025],'Callback',@nofunction);
uicontrol('Style','pushbutton','units','normalized','String',{'Save Keys'},'Position',[0.62,0.85,0.05,0.025],'Callback',@save_new_preset);


uicontrol('Style','pushbutton','units','normalized','String',{'--> apply selected files for all batches'},'Position',[0.57,0.75,0.1,0.05],'Callback',@apply_files_to_all_batches);
uicontrol('Style','pushbutton','units','normalized','String',{'apply keys for all batches <--'},'Position',[0.57,0.7,0.1,0.05],'Callback',@apply_keys_to_all_batches);
uicontrol('Style','pushbutton','units','normalized','String','Runnnnnnn','Position',[0.57,0.56,0.1,0.08],'Callback',@execute_mp_analyze);

positions=[0.57,0.80,0.1,0.03];
set_check_boxes ({'runs_as_batches'},{'Treat each run as batch'},positions);
uicontrol('Style','checkbox','String','Clean data first','Value',false,'units','normalized','Position',[0.57,0.67,0.1,0.03],'Callback',@check_clean_data);
uicontrol('Style','checkbox','String','Run protocol','Value',false,'units','normalized','Position',[0.57,0.64,0.1,0.03],'Callback',@check_run_protocol);

%% Selected Keys
set_listbox('changed_keys','Selected keys',{''},'delete key','select_changed_key','remove_key_value',[0.7,0.55,0.14,0.4]);

%% Selected Key Values
set_listbox('changed_key_values','Key values',{''},'delete key','nofunction','remove_key_value',[0.85,0.55,0.1,0.4]);
uicontrol('Style','pushbutton','String','delete key','units','normalized','Position',[0.7,0.55,0.25,0.0415],'Callback',@remove_key_value);


%% Calculation keys

%% Spacing
global P

% titles
P.yt = 0.5;
P.yst = 0.03;

P.ys = 0.029;
P.yspu = 0.022;
P.yd = 0.032;
P.yf = 0.45;

P.xs = 0.095;
P.xd = 0.1;
P.xf = 0.02;

P.xse= P.xs;
P.xsp= P.xs;

for idx_p=1:20
    P.x(idx_p) = P.xf + P.xd*(idx_p-1);
    P.y(idx_p) = P.yf - P.yd*(idx_p-1);
end

% 'lat_after_micstim' ????

%% XY Keys
uicontrol('Style','text','String','Fixation, cue and target position selection','units','normalized','Position',[P.x(5),P.yt,P.xs*3,P.yst]);
plot(0,0,'marker','+');
hold on
line([-30 30],[0 0]);
line([0 0],[-30 30]);
set(gca,'ylim',[-20 20],'xlim',[-30 30],'units','normalized','OuterPosition',[P.x(5),P.y(7),0.3,0.25],'ButtonDownFcn',@add_rect_info)

Popup_selected_key.XY = uicontrol('Style','popupmenu','units','normalized','String',{'fix';'cue';'tar'},'value',3,'Position',[P.x(5),P.y(9),0.12,0.05],'Callback',@select_XY_field);
set_listbox('X_pos','X',fieldnames(batch(current_batch).filedisplay),'Remove pos','X_Y_selection','remove_XY_key',[P.x(5),0.02,0.06,0.2]);
set_listbox('Y_pos','Y',fieldnames(batch(current_batch).filedisplay),'Add key','X_Y_selection','add_XY_key',[P.x(5)+0.06,0.02,0.06,0.2]);

%% saccades
uicontrol('Style','text','String','Saccade calculation keys','units','normalized','Position',[P.x(1),P.yt,P.xs,P.yst]);

%uicontrol('Style','text','String','Considered states','units','normalized','Position',[0.32,0.4,P.xs,P.ys]);
positions=[P.x(1),P.y(1),P.xs,P.ys; P.x(1),P.y(2),P.xs,P.ys];
set_check_boxes ({'correct_offset';'downsampling'},{'correct eye position offset';'remove identical samples'},positions);

positions=[P.x(1),P.y(3),P.xse,P.ys;P.x(1),P.y(4),P.xse,P.ys;P.x(1),P.y(5),P.xse,P.ys];
set_edit_boxes ({'eyetracker_sample_rate','i_sample_rate','smoothing_samples'},{'Original sampling rate [Hz]','Interpolated sampling rate [Hz]','Interpolated samples to smooth'},positions);

positions=[P.x(1),P.y(6),P.xse,P.ys; P.x(1),P.y(7),P.xse,P.ys; P.x(1),P.y(8),P.xse,P.ys; P.x(1),P.y(9),P.xse,P.ys; P.x(1),P.y(10),P.xse,P.ys];
set_edit_boxes ({'sac_ini_t';'sac_end_t';'sac_min_dur';'sac_min_amp';'sac_max_off'},{'Onset velocity threshold [deg/s]';'End velocity threshold [deg/s]';'Minimum duration [ms]';'Minimum amplitude [deg]';'Maximum distance from target [deg]'},positions);

positions=[P.x(1),P.y(11),P.xse,P.ys; P.x(1),P.y(12),P.xse,P.ys; P.x(1),P.y(13),P.xse,P.ys];
set_edit_boxes ({'nsacc_max';'sac_int_xy';'closest_target_radius'},{'Maximum N saccades considered';'Max distance to intended target';'Radius for closest target estimation'},positions);


%% reaches
% positions=[P.x(2),P.y(1),P.xs,P.ys; P.x(2),P.y(2),P.xs,P.ys ; P.x(2),P.y(3),P.xs,P.ys];
% set_check_boxes ({'reach_1st_pos';'reach_1st_pos_in';'reach_pos_at_state_change'},{'first touched position';'first position in radius';'Last position at state change'},positions);

uicontrol('Style','text','String','Reach calculation keys','units','normalized','Position',[P.x(2),P.y(11),P.xs,P.yst]);
positions=[P.x(2),P.y(12)+0.01,P.xse,P.ys];
set_edit_boxes ({'rea_int_xy'},{'Max distance to intended target';},positions);

%% Saccade and reach definition keys
uicontrol('Style','text','String','Saccade and reach definitions','units','normalized','Position',[P.x(2),P.yt,P.xs,P.yst]);

uicontrol('Style','text','String','Saccade definitions','units','normalized','Position',[P.x(2),P.y(1),P.xs,P.ys]);
positions=[P.x(2),P.y(2)+0.01,P.xs,P.ys; P.x(2),P.y(3)+0.01,P.xs,P.ys ; P.x(2),P.y(4)+0.01,P.xs,P.ys];
set_radio_buttons({'reach_1st_pos';'reach_1st_pos_in';'reach_pos_at_state_change'},{'first touched position';'first position in radius';'Last position at state change'},positions);

uicontrol('Style','text','String','Saccade definitions','units','normalized','Position',[P.x(2),P.y(5),P.xs,P.ys]);
positions=[P.x(2),P.y(6)+0.01,P.xs,P.ys; P.x(2),P.y(7)+0.01,P.xs,P.ys ; P.x(2),P.y(8)+0.01,P.xs,P.ys; P.x(2),P.y(9)+0.01,P.xs,P.ys; P.x(2),P.y(10)+0.01,P.xs,P.ys];
saccade_definition_string_cell={'closest to the target';'biggest saccade';'last saccade in the state';'first saccade in the state';'inside any potential target of this run'};
set_radio_buttons2(repmat({'saccade_definition'},1,numel(saccade_definition_string_cell)),saccade_definition_string_cell,positions);


%% Mode keys
uicontrol('Style','text','String','Mode keys','units','normalized','Position',[P.x(3),P.yt,P.xs,P.yst]);
positions=[P.x(3),P.y(1),P.xs,P.ys;P.x(3),P.y(2),P.xs,P.ys; P.x(3),P.y(3),P.xs,P.ys; P.x(3),P.y(4),P.xs,P.ys; P.x(3),P.y(5),P.xs,P.ys; P.x(3),P.y(6),P.xs,P.ys];%; P.x(3),P.y(7),P.xs,P.ys];
set_radio_buttons(fieldnames(grouped_keys.mode),fieldnames(grouped_keys.mode),positions);

set_popup_box('evoked',fieldnames(grouped_keys.evoked),[P.x(3),P.y(7)-0.05,P.xsp,P.yspu],'Evoked saccade keys');
set_popup_box('history',fieldnames(grouped_keys.history),[P.x(3),P.y(7)-0.1,P.xsp,P.yspu],'Trial history keys');

%% Selection keys


uicontrol('Style','text','String','Selection keys','units','normalized','Position',[P.x(4),P.yt,P.xs,P.yst]);
positions=[P.x(4),P.y(1),P.xsp,P.ys; P.x(4),P.y(2),P.xsp,P.ys; P.x(4),P.y(3),P.xsp,P.ys; P.x(4),P.y(4),P.xsp,P.ys];
set_edit_boxes ({'max_radius';'aborted_state';'demanded_hand';'trial_set'},{'max_radius';'aborted_state';'demanded_hand';'trial_set'},positions);
set_popup_box('simple_selective',fieldnames(grouped_keys.simple_selective),[P.x(4),P.y(6),P.xsp,P.yspu],'Selective keys');




%% Plotting keys

positions=[P.x(8),P.y(1),P.xsp,P.ys];
set_edit_boxes ({'summary'},{'summary'},positions);

%uicontrol('Style','text','String','Plotting keys','units','normalized','Position',[0.65,P.y(1),0.25,P.yst]);
positions=[P.x(8),P.yt,P.xs,P.yst; P.x(8),P.y(2),P.xs,P.ys; P.x(8),P.y(3),P.xs,P.ys; P.x(8),P.y(4),P.xs,P.ys; P.x(8),P.y(5),P.xs,P.ys; P.x(8),P.y(6),P.xs,P.ys; P.x(8),P.y(7),P.xs,P.ys];
set_check_boxes ({'display';'show_trial_ini';'show_run_ends';'show_trial_number';'show_only_one_sac_per_trial';'show_trace';'show_sliding'},...
    {'Display summary plots';'Show initial acquisition';'Lines to separate runs';'Trial numbers in 2D plot';'Plot one saccade per trial';'Connect saccades per trial';'Connect touch pos per trial'},positions);

positions=[P.x(8),P.y(8),P.xsp,P.ys; P.x(8),P.y(9),P.xsp,P.ys; P.x(8),P.y(10),P.xsp,P.ys; P.x(8),P.y(11),P.xsp,P.ys];
set_edit_boxes ({'additional_description';'marker_parameter';'fill_parameter';'fill_value'},{'Additional plot title ';'Parameter to code with markers';'Parameter coded with filling';'Value to fill'},positions);

%% Inferential Plotting keys
%uicontrol('Style','text','String','Inferential plotting keys','units','normalized','Position',[0.65,0.25,0.25,P.yst]);
positions=[P.x(9),P.yt,P.xs,P.yst; P.x(9),P.y(1),P.xs,P.ys; P.x(9),P.y(2),P.xs,P.ys; P.x(9),P.y(3),P.xs,P.ys];
set_check_boxes ({'inferential_on';'boxplot_on';'multicomparison';'scatter_on'},...
    {'Enable inferential plots';'Boxplots';'Multicomparison';'Scatterplot'},positions);
positions=[P.x(9),P.y(4),P.xsp,P.ys; P.x(9),P.y(5),P.xsp,P.ys; P.x(9),P.y(6),P.xsp,P.ys];
set_edit_boxes ({'inf_structure';'inf_field';'counting_field'},{'Structure for inferential comparison';'Field for inferential comparison';'Counting (Optional output)'},positions);

%% all keys
set_popup_box('all_keys',fieldnames(all_keys),[P.x(6)+0.04,P.y(9),P.xsp+P.xsp/3,P.yspu],'Didnt find the desired key? Check this...');


%ha = axes('Units','pixels','Position',[50,60,200,185]);

update_keys;
disable_enable_keys;
movegui(f,'center')

%f.Visible = 'on';
set(f,'Visible','on');


%% intialize read available keys
    function get_default_key_values
        full_string_array=DAG_read_file_parts('monkeypsych_analyze_working.m','%%%Start_keys','%%%End_keys');
        all_keys=struct();
        grouped_keys=struct('mode',{{}},'complex_selective',{{}},'simple_selective',{{}},'calcoptions',{{}},'history',{{}},'plotoptions',{{}},'evoked',{{}},'inferential',{{}});
        
        default_key_values=struct();
        keys=struct();
        eval(full_string_array);
        FNK=fieldnames(keys);
        %FND=fieldnames(default_key_values);
        %idx=0;
        for FN_idx=1:numel(FNK)
            sub_FN=keys.(FNK{FN_idx});
            for key_idx=1:numel(sub_FN)
                all_keys.(sub_FN{key_idx})=default_key_values.(FNK{FN_idx}){key_idx};
                grouped_keys.(FNK{FN_idx}).(sub_FN{key_idx})=default_key_values.(FNK{FN_idx}){key_idx};
            end
        end
    end


%% Session selection functions
    function nofunction(source,eventdata)
    end
    function set_listbox(listbox_fieldname,title,listbox_string,button_string,callback_listbox,callback_button,position)
        button_height=max(position(4)*0.05,0.02);
        uicontrol('Style','text','String',title,'units','normalized','Position',[position(1) position(2)+position(4)-(button_height) position(3) button_height]);
        Listbox.(listbox_fieldname) = uicontrol('Style','listbox','String',listbox_string,'units','normalized',...
            'max',1000,'min',0,'Position',[position(1) position(2)+2*button_height position(3) position(4)-(3*button_height)],'Callback',eval(['@' callback_listbox]));
        uicontrol('Style','pushbutton','String',button_string,'units','normalized',...
            'Position',[position(1) position(2) position(3) 2*button_height],'Callback',eval(['@' callback_button]));
    end
    function monkey_selection(source,~)
        val = get(source,'value');
        str = get(source,'String');
        current_monkey=str{val};
        update_all_sessions_listbox
        current_sessions=fieldnames(batch(current_batch).filedisplay.(current_monkey));
        set(Listbox.selected_sessions,'String',current_sessions,'value',1:numel(current_sessions))
        select_sessions([],[])
    end
    function browse_folder(~,eventdata)
        browsed_folder_complete_path                            = uigetdir([dag_drive_IP 'Data' filesep],['Select monkey ' num2str(current_batch)]);
        fileseps_idx                                            =strfind(browsed_folder_complete_path,filesep);
        current_monkey                                          =browsed_folder_complete_path((fileseps_idx(end)+1):end);
        current_main_path                                       =browsed_folder_complete_path(1:(fileseps_idx(end)));
        batch(current_batch).filedisplay.(current_monkey)       =struct();
        batch(current_batch).main_paths.(current_monkey)         =current_main_path;
        %update_all_sessions_listbox
        monkey_list                                             =get(Listbox.monkey,'String');
        set(Listbox.monkey,'String',[monkey_list; {current_monkey}],'value',numel(monkey_list)+1);
        monkey_selection(Listbox.monkey,eventdata)
    end
    function select_sessions(~,~)
        val = get(Listbox.all_sessions,'value');
        str = get(Listbox.all_sessions,'String');
        current_sessions = [get(Listbox.selected_sessions,'String'); cellfun(@(x) ['S_' x],str(val),'UniformOutput',false)];
        current_sessions=unique(current_sessions);
        for session_idx=1:numel(current_sessions)
            batch(current_batch).filedisplay.(current_monkey).([current_sessions{session_idx}])={};
        end
        set(Listbox.selected_sessions,'String',fieldnames(batch(current_batch).filedisplay.(current_monkey)),'value',[1:numel(current_sessions)]);
        update_runs_in_sessions_listbox
    end
    function added_session_selection(source,~)
        val = get(source,'value');
        str = get(source,'String');
        current_sessions = str(val);
        update_runs_in_sessions_listbox
    end
    function remove_sessions(~,~)
        val = get(Listbox.selected_sessions,'value');
        str = get(Listbox.selected_sessions,'String');
        current_sessions = str(~val);
        sessions_to_remove = str(val);
        runs_to_remove=get(Listbox.runs_in_session,'String');
        current_sessions_for_removed_runs={};
        for n=1:numel(sessions_to_remove)
            batch(current_batch).filedisplay.(current_monkey)=rmfield(batch(current_batch).filedisplay.(current_monkey),sessions_to_remove{n});
            subfolderdir=dir([current_main_path current_monkey filesep sessions_to_remove{n}(3:end) filesep '*.mat']);
            current_sessions_for_removed_runs=[current_sessions_for_removed_runs repmat(sessions_to_remove(n),1,numel(subfolderdir))];
            runs_in_session=runs_to_remove(strcmp(current_sessions_for_removed_runs,sessions_to_remove(n)));
            filenames_with_path=cellfun(@(x)  [current_main_path current_monkey filesep sessions_to_remove{n}(3:end) filesep x],runs_in_session,'uniformoutput',false);
            batch(current_batch).files(ismember(batch(current_batch).files,filenames_with_path))=[];
        end
        set(Listbox.selected_sessions,'String',fieldnames(batch(current_batch).filedisplay.(current_monkey)),'value',[1:numel(current_sessions)]);
        set(Listbox.filesinbatch,'String',batch(current_batch).files,'value',1);
        update_runs_in_sessions_listbox
    end
    function run_selection(source,~)
        val = get(source,'value');
        str = get(source,'String');
        current_runs = str(val);
    end
    function add_runs(~,~)
        current_sessions_for_runs=batch(current_batch).current_sessions_for_runs(get(Listbox.runs_in_session,'value'));
        for n=1:numel(current_sessions)
            runs_in_session=current_runs(strcmp(current_sessions_for_runs,current_sessions(n)));
            batch(current_batch).filedisplay.(current_monkey).(current_sessions{n})=runs_in_session;
            filenames_with_path=cellfun(@(x)  [current_main_path current_monkey filesep current_sessions{n}(3:end) filesep x],runs_in_session,'uniformoutput',false);
            batch(current_batch).files=[batch(current_batch).files; filenames_with_path(~ismember(filenames_with_path,batch(current_batch).files))];
        end
        set(Listbox.filesinbatch,'String',batch(current_batch).files,'value',1);
    end
    function update_all_sessions_listbox
        subfolderdir=dir([current_main_path current_monkey]);
        subfolderlist={subfolderdir([subfolderdir.isdir]).name};
        if ~isempty(subfolderlist)
            subfolderlist([1 2])=[];
        end;
        set(Listbox.all_sessions,'String',subfolderlist,'value',[]);
    end
    function update_runs_in_sessions_listbox
        set(Listbox.runs_in_session,'String',{},'value',[]);
        current_sessions_for_runs={};
        for n=1:numel(current_sessions)
            subfolderdir=dir([current_main_path current_monkey filesep current_sessions{n}(3:end) filesep '*.mat']);
            current_sessions_for_runs=[current_sessions_for_runs repmat(current_sessions(n),1,numel(subfolderdir))];
            batch(current_batch).filedisplay.(current_monkey).(current_sessions{n})={subfolderdir.name};
            set(Listbox.runs_in_session,'String',[get(Listbox.runs_in_session,'String'); {subfolderdir.name}'],'value',1:(numel(get(Listbox.runs_in_session,'String'))+numel(subfolderdir)));
        end
        batch(current_batch).current_sessions_for_runs=current_sessions_for_runs;
        run_selection(Listbox.runs_in_session,[]);
    end
%% current inputs display !!

    function file_selection(source,~)
        val = get(source,'value');
        current_file=val;
    end
    function delete_file_from_batch(~,~)
        batch(current_batch).files(current_file)=[];
        set(Listbox.filesinbatch,'String',batch(current_batch).files,'value',[]);
    end
    function select_changed_key(source,~)
        changed_key_list=get(source,'String');
        N_key_to_change=get(source,'value');
        current_changed_keys=changed_key_list(N_key_to_change);
        set(Listbox.changed_key_values,'value',N_key_to_change);
    end

    function remove_key_value(~,~)
        for KN_idx=1:numel(current_changed_keys)
            current_changed_key=current_changed_keys(KN_idx);
            batch(current_batch).keys_struct=rmfield(batch(current_batch).keys_struct,current_changed_key);
            changed_keys(strcmp(changed_keys,current_changed_key))=[];
        end
        update_changed_keys;
    end
    function update_changed_keys
        new_value=numel(fieldnames(batch(current_batch).keys_struct));
        set(Listbox.changed_keys,'String',fieldnames(batch(current_batch).keys_struct),'Value',new_value);
        key_values_displayed=calc_current_key_values;
        set(Listbox.changed_key_values,'String',key_values_displayed,'Value',new_value);
    end
%% Preset keys
    function save_new_preset(source,~)
        preset_keyname=get(Preset_key,'String');
        fieldnames_to_add=fieldnames(batch(current_batch).keys_struct);
        fieldnamevalues_to_add=calc_current_key_values;
        string_to_add=['Preset_key_structure.' preset_keyname '=struct('];
        for k=1:numel(fieldnames_to_add)
            if isstr(fieldnamevalues_to_add{k})
            string_to_add=[string_to_add fieldnames_to_add{k} ',{' '''' fieldnamevalues_to_add{k} '''' '},'];
            else
            string_to_add=[string_to_add fieldnames_to_add{k} ',{' num2str(fieldnamevalues_to_add{k}) '},'];                
            end
        end
        string_to_add=[string_to_add(1:end-1) '};'];
        a=1;
    end
    function apply_preset_keys(source,~)
        Default_keys_list=get(source,'String');
        Default_key_to_apply=Default_keys_list{get(source,'value')};
        batch(current_batch).keys_struct=Preset_key_structure.(Default_key_to_apply);
        update_keys;
        %         update_changed_keys;
        %         disable_enable_keys;
    end
    function set_preset_keys
        %%_PRESET_KEYS
        Preset_key_structure.Version1=struct('runs_as_batches',{1},'keep_raw_data',{1},'saccade_definition',{1},'nsacc_max',{2},'sac_ini_t',{40},'sac_end_t',{25},'reach_1st_pos_in',1,'reach_1st_pos',0,'reach_pos_at_state_change',0);
        Preset_key_structure.Version2=struct('runs_as_batches',{0},'keep_raw_data',{0},'saccade_definition',{4},'nsacc_max',{3},'sac_ini_t',{400},'sac_end_t',{100},'reach_1st_pos_in',0,'reach_1st_pos',1,'reach_pos_at_state_change',0);
        %%_PRESET_KEYS_END
    end

%% Display of selected keys
    function key_values_displayed=calc_current_key_values
        key_values_displayed={};
        FN=fieldnames(batch(current_batch).keys_struct);
        for k=1:numel(FN)
            if iscell(batch(current_batch).keys_struct.(FN{k}))
                key_values_displayed=[key_values_displayed; {[batch(current_batch).keys_struct.(FN{k}){:} ', ']}];
            elseif ismatrix(batch(current_batch).keys_struct.(FN{k}))
                if size(batch(current_batch).keys_struct.(FN{k}),1)==1
                    key_values_displayed=[key_values_displayed; {num2str(batch(current_batch).keys_struct.(FN{k}))}];
                else
                    key_values_displayed=[key_values_displayed; {num2str(reshape(batch(current_batch).keys_struct.(FN{k})',1,numel(batch(current_batch).keys_struct.(FN{k}))))}];
                end
            elseif ischar(batch(current_batch).keys_struct.(FN{k}))
                key_values_displayed=[key_values_displayed; {batch(current_batch).keys_struct.(FN{k})}];
            else
                key_values_displayed=[key_values_displayed; {eval(['' batch(current_batch).keys_struct.(FN{k}) ''])}];
            end
        end
    end



%% batch control
    function batch_selection(source,~)
        val = get(source,'value');
        current_batch=val;
        update_batches;
    end
    function add_batch(~,~)
        previous_batch=current_batch;
        batches=1:numel(batches)+1;
        current_batch=batches(end);
        batch(current_batch)=struct('main_paths',{struct(batch(previous_batch).main_paths)},'filedisplay',{struct(batch(previous_batch).filedisplay)},'files',{{}},'keys_struct',{struct()},'current_sessions_for_runs',{{}});
        update_batches
    end
    function delete_batch(~,~)
        batch(current_batch)=[];
        batches=1:numel(batches)-1;
        current_batch=batches(end);
        update_batches
    end
    function update_batches
        set(hbatches,'String',num2cell(batches));
        set(hbatches,'value',current_batch);
        set(Listbox.filesinbatch,'String',batch(current_batch).files,'value',[]);
        
        update_all_sessions_listbox
        current_sessions=fieldnames(batch(current_batch).filedisplay.(current_monkey));
        set(Listbox.selected_sessions,'String',current_sessions,'value',1:numel(current_sessions))
        
        update_runs_in_sessions_listbox
        update_keys
    end
    function update_keys
        set(Listbox.changed_keys,'String',fieldnames(batch(current_batch).keys_struct),'value',[]);
        key_values_displayed=calc_current_key_values;
        set(Listbox.changed_key_values,'String',key_values_displayed,'value',[]);
        
        keynames=fieldnames(all_keys);
        for KN_idx=1:numel(keynames)
            if isfield(batch(current_batch).keys_struct,keynames{KN_idx})
                keyval=batch(current_batch).keys_struct.(keynames{KN_idx});
            else
                keyval=all_keys.(keynames{KN_idx});
            end
            if isfield(Edit_box, keynames{KN_idx})
                set(Edit_box.(keynames{KN_idx}),'String',num2str(keyval));
            end
            if isfield(Checkbox, keynames{KN_idx})
                set(Checkbox.(keynames{KN_idx}),'Value',keyval);
            end
            if isfield(radio_button, keynames{KN_idx})
                set(radio_button.(keynames{KN_idx}),'Value',keyval);
            end
            if isfield(radio_button2, keynames{KN_idx})
                for k=1:numel(radio_button2.(keynames{KN_idx}))
                    set(radio_button2.(keynames{KN_idx})(k),'Value',0);
                end
                set(radio_button2.(keynames{KN_idx})(keyval),'Value',keyval);
            end
            
        end
    end
    function apply_files_to_all_batches(~,~)
        for batch_index=batches
            batch(batch_index).files=batch(current_batch).files;
        end
    end
    function apply_keys_to_all_batches(~,~)
        for batch_index=batches
            batch(batch_index).keys_struct=batch(current_batch).keys_struct;
        end
    end


%% Key modification !
%% key radiobuttons
    function set_radio_buttons (keynames,keydescriptions,positions)
        grouposition=[min(positions(:,1)) min(positions(:,2)) max(positions(:,1)+positions(:,3))-min(positions(:,1)) max(positions(:,2)+positions(:,4))-min(positions(:,2))];
        bg=uibuttongroup('Visible','off','units','normalized','Position',grouposition,'SelectionChangeFcn',@radio_button_selection);
        positions(:,1)=(positions(:,1)-grouposition(:,1))./(grouposition(:,3));
        positions(:,2)=(positions(:,2)-grouposition(:,2))./(grouposition(:,4));
        positions(:,3)=positions(:,3)./grouposition(:,3);
        positions(:,4)=positions(:,4)./grouposition(:,4);
        
        for KN_idx=1:numel(keynames)
            radio_button.(keynames{KN_idx})=uicontrol(bg,'Style','radiobutton','String',keydescriptions{KN_idx},'tag',keynames{KN_idx},...
                'units','normalized','Position',positions(KN_idx,:),'HandleVisibility','off','UserData',KN_idx);
        end
        set(bg,'Visible','on')
    end
    function set_radio_buttons2 (keynames,keydescriptions,positions)
        grouposition=[min(positions(:,1)) min(positions(:,2)) max(positions(:,1)+positions(:,3))-min(positions(:,1)) max(positions(:,2)+positions(:,4))-min(positions(:,2))];
        bg=uibuttongroup('Visible','off','units','normalized','Position',grouposition,'SelectionChangeFcn',@radio_button_selection2);
        positions(:,1)=(positions(:,1)-grouposition(:,1))./(grouposition(:,3));
        positions(:,2)=(positions(:,2)-grouposition(:,2))./(grouposition(:,4));
        positions(:,3)=positions(:,3)./grouposition(:,3);
        positions(:,4)=positions(:,4)./grouposition(:,4);
        
        for KN_idx=1:numel(keynames)
            radio_button2.(keynames{KN_idx})(KN_idx)=uicontrol(bg,'Style','radiobutton','String',keydescriptions{KN_idx},'tag',keynames{KN_idx},...
                'units','normalized','Position',positions(KN_idx,:),'HandleVisibility','off','UserData',KN_idx);
        end
        set(bg,'Visible','on')
    end
    function radio_button_selection(~,callbackdata)
        checked_key_name=get(callbackdata.NewValue,'Tag');
        unchecked_key_name=get(callbackdata.OldValue,'Tag');
        batch(current_batch).keys_struct.(checked_key_name)=1;
        batch(current_batch).keys_struct.(unchecked_key_name)=0;
        update_changed_keys;
        disable_enable_keys;
    end
    function radio_button_selection2(~,callbackdata)
        checked_key_name=get(callbackdata.NewValue,'Tag');
        new_value=get(callbackdata.NewValue,'UserData');
        batch(current_batch).keys_struct.(checked_key_name)=new_value;
        update_changed_keys;
        disable_enable_keys;
    end

%% keys checkboxes
    function set_check_boxes (keynames,keydescriptions,positions)
        for KN_idx=1:numel(keydescriptions)
            Checkbox.(keynames{KN_idx}) = uicontrol('Style','checkbox','Tag',keynames{KN_idx},'String',keydescriptions{KN_idx},'Value',all_keys.(keynames{KN_idx}),...
                'units','normalized','Position',positions(KN_idx,:),'Callback',@check_key);
        end
    end
    function check_key(source,~)
        checked_key_name=get(source,'Tag');
        batch(current_batch).keys_struct.(checked_key_name)=1*(get(source,'Value') == get(source,'Max'));
        update_changed_keys;
        disable_enable_keys;
    end

%% key edit boxes
    function set_edit_boxes (keynames,keydescriptions,positions)
        for KN_idx=1:numel(keynames)
            c_pos=positions(KN_idx,:);
            Edit_box.(keynames{KN_idx}) = uicontrol('Style','edit','units','normalized','String',num2str(all_keys.(keynames{KN_idx})),...
                'Position',[c_pos(1)+c_pos(3)*0.66, c_pos(2),  c_pos(3)*0.34,c_pos(4)],'Tag',keynames{KN_idx},'Callback',@apply_edit_box_key);
            description_positions=[c_pos(1:2), c_pos(3)*0.66, c_pos(4)];
            uicontrol('Style','text','String',keydescriptions{KN_idx},'units','normalized','Position',description_positions);
        end
    end
    function apply_edit_box_key(source,~)
        key_name=get(source,'tag');
        key_value=get(source,'String');
        key_value_num=str2num(key_value);
        if ~isempty(key_value_num)
            batch(current_batch).keys_struct.(key_name)=  key_value_num;
        else
            batch(current_batch).keys_struct.(key_name)=  key_value;
        end
        update_changed_keys;
        disable_enable_keys;
    end

%% key popup_boxes
    function set_popup_box(key_group_name,displayed_content,position,title)
        Popup_selected_key.(key_group_name) = uicontrol('Style','popupmenu','units','normalized','String',displayed_content,...
            'tag',key_group_name,'Position',[position(1:2),position(3)*0.75,position(4)],'Callback',@select_key);
        selected_key_value.(key_group_name) = uicontrol('Style','edit','units','normalized','String','',...
            'Position',[position(1)+position(3)*0.75,position(2),position(3)*0.25,position(4)],'tag',key_group_name,'Callback',@apply_popup_key_value);
        %uicontrol('Style','pushbutton','String','Add key value','units','normalized','tag',key_group_name,'Position',[position(1)+position(3)+0.03,position(2),0.05,position(4)],'Callback',@apply_key_value);
        
        uicontrol('Style','text','String',title,'units','normalized','Position',[position(1),position(2)+position(4),position(3),0.025]);
    end

    function apply_popup_key_value(source,~)
        isnonumber=false;
        tag=get(source,'tag');
        key_list=get(Popup_selected_key.(tag),'String');
        N_key_to_change=get(Popup_selected_key.(tag),'value');
        
        current_changed_key=key_list{N_key_to_change};
        changed_keys=[changed_keys,current_changed_key];
        current_key_value=get(selected_key_value.(tag),'String');
        
        try str2num(current_key_value);
            current_key_value=str2num(current_key_value);
        catch 
            isnonumber=true;
        end
        if iscell(current_key_value)
            current_key_value=eval(current_key_value{1});
        end
        batch(current_batch).keys_struct.(current_changed_key)=current_key_value;
        
        %batch(current_batch).display_of_changed_keys=[batch(current_batch).display_of_changed_keys; current_key_value]; % !!!!!
        update_changed_keys;
        disable_enable_keys;
    end

    function select_key(source,~)
        % Determine the selected data set.
        %       str = source.String;
        %       val = source.Value;
        
        str = get(source,'string');
        val = get(source,'value');
        tag = get(source,'tag');
        current_selected_key.(tag)=str{val};
        if strcmp(tag,'all_keys')
            set(selected_key_value.(tag),'String',all_keys.(current_selected_key.(tag)));
        else
            set(selected_key_value.(tag),'String',grouped_keys.(tag).(current_selected_key.(tag)));
        end
    end

%% X_Y_selection
    function select_XY_field(source,~)
        str=get(source,'String');
        val=get(source,'value');
        current_XY_field=str{val};
    end
    function add_rect_info(current_axes,~)
        
        rect =  getrect(current_axes);% rect=[xmin ymin width height]
        current_rect=numel(rects_xy)+1;
        rects_xy(current_rect).x=round([rect(1) rect(1)+rect(3)].*100)./100;
        rects_xy(current_rect).y=round([rect(2) rect(2)+rect(4)].*100)./100;
        rects_xy(current_rect).handle=rectangle('Position',rect);
        update_X_Y;
    end

    function X_Y_selection(source,~)
        current_rect=get(source,'value');
        update_X_Y;
    end
    function add_XY_key(~,~)
        batch(current_batch).keys_struct.(strcat(current_XY_field, '_range_x'))=batch(current_batch).X_pos;
        batch(current_batch).keys_struct.(strcat(current_XY_field, '_range_y'))=batch(current_batch).Y_pos;
        update_changed_keys;
    end
    function remove_XY_key(~,~)
        set(rects_xy(current_rect).handle,'visible','off');
        rects_xy(current_rect)=[];
        current_rect=numel(rects_xy);
        update_X_Y;
    end
    function update_X_Y
        batch(current_batch).X_pos=vertcat(rects_xy.x);
        batch(current_batch).Y_pos=vertcat(rects_xy.y);
        set(Listbox.X_pos,'String',{num2str(batch(current_batch).X_pos)});
        set(Listbox.Y_pos,'String',{num2str(batch(current_batch).Y_pos)});
        set(Listbox.X_pos,'value',current_rect);
        set(Listbox.Y_pos,'value',current_rect);
    end

%% disable and enable
    function disable_enable_keys
        enabled.history=get(radio_button.trial_history_mode,'Value');
        enabled.plots=get(Checkbox.display,'Value');
        enabled.inferential=get(Checkbox.inferential_on,'Value');
        enabled.summary_plots=str2double(get(Edit_box.summary,'String'))>0;
        enabled.trial_plots=str2double(get(Edit_box.summary,'String'))==0;
        enabled.sac_amp_criterion=find(cell2mat(get(radio_button2.saccade_definition,'Value')))==1;
        enabled.sac_dist_criterion=find(cell2mat(get(radio_button2.saccade_definition,'Value')))==2;
        
        if ~enabled.plots
            enabled.summary_plots=false;
            enabled.trial_plots=false;
        end
        
        
        fields_to_enable.history={'history'};
        fields_to_enable.plots={'show_trial_ini';'show_run_ends';'show_trial_number';'show_only_one_sac_per_trial';'show_trace';'show_sliding'; ...
            'additional_description';'marker_parameter';'fill_parameter';'fill_value';'additional_description';'marker_parameter';'fill_parameter';'fill_value'};
        fields_to_enable.inferential={'boxplot_on';'multicomparison';'scatter_on';'inf_structure';'inf_field';'counting_field';'inf_structure';'inf_field';'counting_field'};
        fields_to_enable.summary_plots={'show_run_ends';'show_trial_number';'show_only_one_sac_per_trial';'show_trace';'show_sliding'; ...
            'additional_description';'marker_parameter';'fill_parameter';'fill_value';'additional_description';'marker_parameter';'fill_parameter';'fill_value'};
        fields_to_enable.trial_plots={'show_trial_ini'};
        fields_to_enable.sac_amp_criterion={'sac_min_amp'};
        fields_to_enable.sac_dist_criterion={'sac_max_off'};
        
        FN_E=fieldnames(enabled);
        for idx_enable=1:numel(FN_E)
            if enabled.(FN_E{idx_enable})
                on_or_off= 'on';
            else
                on_or_off= 'off';
            end
            FN=fields_to_enable.(FN_E{idx_enable});
            for FN_idx=1:numel(FN)
                if ismember(FN{FN_idx},fieldnames(Checkbox))
                    set(Checkbox.(FN{FN_idx}),'enable',on_or_off);
                end
                if ismember(FN{FN_idx},fieldnames(Edit_box))
                    set(Edit_box.(FN{FN_idx}),'enable',on_or_off);
                end
                if ismember(FN{FN_idx},fieldnames(Popup_selected_key))
                    set(Popup_selected_key.(FN{FN_idx}),'enable',on_or_off);
                end
            end
        end
        %% Plotting keys
        
        % %'summary',
        %
        % positions=[P.x(8),P.y(1),P.xsp,P.ys];
        % set_edit_boxes ({'summary'},{'summary'},positions);
        %
        % %uicontrol('Style','text','String','Plotting keys','units','normalized','Position',[0.65,P.y(1),0.25,P.yst]);
        % positions=[P.x(8),P.yt,P.xs,P.yst; P.x(8),P.y(2),P.xs,P.ys; P.x(8),P.y(3),P.xs,P.ys; P.x(8),P.y(4),P.xs,P.ys; P.x(8),P.y(5),P.xs,P.ys; P.x(8),P.y(6),P.xs,P.ys; P.x(8),P.y(7),P.xs,P.ys];
        % set_check_boxes ({'display';'show_trial_ini';'show_run_ends';'show_trial_number';'show_only_one_sac_per_trial';'show_trace';'show_sliding'},...
        %     {'Display summary plots';'show_trial_ini';'show_run_ends';'show_trial_number';'show_only_one_sac_per_trial';'show_trace';'show_sliding'},positions);
        %
        % positions=[P.x(8),P.y(8),P.xsp,P.ys; P.x(8),P.y(9),P.xsp,P.ys; P.x(8),P.y(10),P.xsp,P.ys; P.x(8),P.y(11),P.xsp,P.ys];
        % set_edit_boxes ({'additional_description';'marker_parameter';'fill_parameter';'fill_value'},{'additional_description';'marker_parameter';'fill_parameter';'fill_value'},positions);
        %
        % %% Inferential Plotting keys
        % %uicontrol('Style','text','String','Inferential plotting keys','units','normalized','Position',[0.65,0.25,0.25,P.yst]);
        % positions=[P.x(9),P.yt,P.xs,P.yst; P.x(9),P.y(1),P.xs,P.ys; P.x(9),P.y(2),P.xs,P.ys; P.x(9),P.y(3),P.xs,P.ys];
        % set_check_boxes ({'inferential_on';'boxplot_on';'multicomparison';'scatter_on'},...
        %     {'Enable Inferential plots';'Boxplots';'Multicomparison';'Scatterplot'},positions);
        % positions=[P.x(9),P.y(4),P.xsp,P.ys; P.x(9),P.y(5),P.xsp,P.ys; P.x(9),P.y(6),P.xsp,P.ys];
        % set_edit_boxes ({'inf_structure';'inf_field';'counting_field'},{'inf_structure';'inf_field';'counting_field'},positions);
        
        
    end

    function Gui_version(~, ~, ~)
        
        ha = axes('units','normalized', ...
            'position',[0 0 1 1]);
        uistack(ha,'bottom');
        I=imread('Flea.jpg');
        hi = imagesc(I);
        colormap gray
        set(ha,'handlevisibility','off', ...
            'visible','off')
    end
%% RUN!
    function check_clean_data(source,~)
        clean_data=get(source,'Value');
    end
    function check_run_protocol(source,~)
        run_protocol=get(source,'Value');
    end
    function execute_mp_analyze(~,~)
        
        if clean_data || run_protocol
            all_files=vertcat(batch.files);
            for b=1:numel(batches)
                mainpath(b).monkeys=fieldnames(batch(b).main_paths);
                for FN=1:numel(mainpath(b).monkeys)
                    mainpath(b).paths{FN}=batch(b).main_paths.(mainpath(b).monkeys{FN});
                end
            end
            all_paths=vertcat(mainpath.paths);
            [unique_monkeys unique_idx]=unique(vertcat(mainpath.monkeys));
            unique_paths=all_paths(unique_idx);
            for n=1:numel(all_files)
                for m=1:numel(unique_monkeys)
                    if strfind(all_files{n},unique_monkeys{m})
                        all_monkeys{n}=unique_monkeys{m};
                        continue
                    end
                end
                all_dates{n}=str2num(all_files{n}([end-16 end-15 end-14 end-13 end-11 end-10 end-8 end-7]));
            end
            for m=1:numel(unique_monkeys)
                to_run(m).monkey=unique_monkeys{m};
                to_run(m).path=unique_paths{m};
                monkey_idx=cellfun(@(x) ~isempty(x),strfind(all_monkeys,unique_monkeys{m}));
                to_run(m).dates=[min([all_dates{monkey_idx}]) max([all_dates{monkey_idx}])];
            end
        end
        if run_protocol
            for m=1:numel(m)
                DAG_protocol_update(to_run(m).monkey,to_run(m).dates)
            end
        elseif clean_data
            for m=1:numel(m)
                monkeypsych_clean_data([to_run(m).path to_run(m).monkey],to_run(m).dates)
            end
        end
        
        clear filelist_formated keys_formated
        for batch_index=1:numel(batch)
            for fileidx=1:numel(batch(batch_index).files)
                filename=batch(batch_index).files{fileidx};
                filesep_idxes=strfind(filename,filesep);
                filelist_formated{batch_index}{fileidx,1}=filename(1:filesep_idxes(end)-1);
                filelist_formated{batch_index}{fileidx,2}=str2double(filename(end-5:end-4));
            end
            keys_formated{batch_index}={};
            keys=fieldnames(batch(batch_index).keys_struct);
            for keyidx=1:numel(keys)
                keys_formated{batch_index}=[keys_formated{batch_index}, keys{keyidx}];
                keys_formated{batch_index}=[keys_formated{batch_index}, batch(batch_index).keys_struct.(keys{keyidx})];
            end
        end
        
        complete_MPA_input=[filelist_formated;keys_formated];
        complete_MPA_input=complete_MPA_input(:);
        [out_comp]=monkeypsych_analyze_working(complete_MPA_input{:});
        
        assignin('base','batches',batch)
        assignin('base','MP_output',out_comp)
    end
end


