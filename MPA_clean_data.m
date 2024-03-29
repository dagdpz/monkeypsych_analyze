function MPA_clean_data(datapath,dates)
% This function cleans and equalizes collected data structure fields
% So far this includes
% * Deleting the last trial if its empty
% * Deleting the dio object from SETTINGS
% * Adding missing timing structure fields
%datapath='Y:\Data\Cornelius'
%dates=[20131223 20131227];

dir_folder_with_session_days=dir(datapath); % dir
all_files_in_base_path=[];
if numel(dates)==1
    dates(2)=dates(1);
end

ctr=1;
for k=1: length(dir_folder_with_session_days)
    X=str2num(dir_folder_with_session_days(k).name);
    if ~isempty(X) && (X==dates(1) ||  ( X<=  dates(2) && X >  dates(1)))
        all_files_in_base_path{ctr}= dir_folder_with_session_days(k).name;
        ctr=ctr+1;
    end
end
for m=1:numel(all_files_in_base_path)
    currentpath=strcat(datapath, filesep, all_files_in_base_path(m));
    %cd(currentpath{:})
    %currentfiles
    
    MPA_clean_data_per_date(currentpath{:})
end

end


function MPA_clean_data_per_date(datapath)
dir_datapath=dir(datapath);
for s=1: length(dir_datapath)
    if ismember('mat', dir_datapath(s).name)
        disp(dir_datapath(s).name);
        % load each run in one session
        load([datapath filesep dir_datapath(s).name])
        LastTrial_ind= length(trial); % take the index of last trial
        % check if the last trial is empty.... we check its state field
        
        for FN=fieldnames(SETTINGS)'
           fn=FN{:};
           if all(isobject(SETTINGS.(fn))) || (all(ishandle(SETTINGS.(fn)) & ~ismatrix(SETTINGS.(fn)) & ~ischar(SETTINGS.(fn))) && ~isempty(ishandle(SETTINGS.(fn))))
            SETTINGS=rmfield(SETTINGS,fn);
            disp(strcat('Deleting SETTINGS.', fn, 'object of file: ', dir_datapath(s).name))
               
           end
        end
%         if isfield(SETTINGS,'dio')
%             SETTINGS=rmfield(SETTINGS,'dio');
%             disp(strcat('Deleting SETTINGS.dio object of file: ', dir_datapath(s).name))
%             save([datapath filesep dir_datapath(s).name], 'task', 'SETTINGS', 'trial')
%         end
        
        if isempty(trial(1,LastTrial_ind ).state)
            disp(strcat('Deleting last empty trial of file: ', dir_datapath(s).name))
            trial= trial(1: LastTrial_ind-1);
        end
        
        if any(diff(trial(1,LastTrial_ind).tSample_from_time_start)==0)
            disp(strcat('Deleting last trial of file: ', dir_datapath(s).name, 'contaning identical time samples'))
            trial= trial(1: LastTrial_ind-1);
        end
        if ~isfield(trial(1).task,'force_conditions')
            forced=MPA_detect_forced_condition(trial);
        end

        trial=orderfields(trial);
        for t=1:length(trial)           
            
            if ~isfield(trial(t).task,'force_conditions');                trial(t).task.force_conditions=forced; end
                        
            
            if ~isfield(trial(t).task.timing,'tar_time_hold');                trial(t).task.timing.tar_time_hold=NaN; end
            if ~isfield(trial(t).task.timing,'tar_time_hold_var');        trial(t).task.timing.tar_time_hold_var=NaN; end
            
            if ~isfield(trial(t).task.timing,'del_time_hold');                trial(t).task.timing.del_time_hold=NaN; end
            if ~isfield(trial(t).task.timing,'del_time_hold_var');        trial(t).task.timing.del_time_hold_var=NaN; end
            if ~isfield(trial(t).task.timing,'cue_time_hold');                trial(t).task.timing.cue_time_hold=NaN; end
            if ~isfield(trial(t).task.timing,'cue_time_hold_var');        trial(t).task.timing.cue_time_hold_var=NaN; end
            if ~isfield(trial(t).task.timing,'mem_time_hold');                trial(t).task.timing.mem_time_hold=NaN; end
            if ~isfield(trial(t).task.timing,'mem_time_hold_var');        trial(t).task.timing.mem_time_hold_var=NaN; end
            if ~isfield(trial(t).task.timing,'tar_inv_time_hold');        trial(t).task.timing.tar_inv_time_hold=NaN; end
            if ~isfield(trial(t).task.timing,'tar_inv_time_hold_var'); trial(t).task.timing.tar_inv_time_hold_var=NaN; end
            if ~isfield(trial(t).task.timing,'tar_inv_time_to_acquire_hnd');        trial(t).task.timing.tar_inv_time_to_acquire_hnd=NaN; end
            if ~isfield(trial(t).task.timing,'tar_inv_time_to_acquire_eye');        trial(t).task.timing.tar_inv_time_to_acquire_eye=NaN; end
            
            if ~isfield(trial(t).task.timing,'fix_time_to_acquire_hnd');        trial(t).task.timing.fix_time_to_acquire_hnd=NaN; end
            if ~isfield(trial(t).task.timing,'fix_time_to_acquire_eye');        trial(t).task.timing.fix_time_to_acquire_eye=NaN; end
            if ~isfield(trial(t).task.timing,'tar_time_to_acquire_hnd');        trial(t).task.timing.tar_time_to_acquire_hnd=NaN; end
            if ~isfield(trial(t).task.timing,'tar_time_to_acquire_eye');        trial(t).task.timing.tar_time_to_acquire_eye=NaN; end
            
            if ~isfield(trial(t).task.timing,'ITI_success');              trial(t).task.timing.ITI_success=NaN; end
            if ~isfield(trial(t).task.timing,'ITI_success_var');          trial(t).task.timing.ITI_success_var=NaN; end
            if ~isfield(trial(t).task.timing,'ITI_fail');                 trial(t).task.timing.ITI_fail=NaN; end
            if ~isfield(trial(t).task.timing,'ITI_fail_var');             trial(t).task.timing.ITI_fail_var=NaN; end
            if ~isfield(trial(t).task.timing,'ITI_incorrect_completed');  trial(t).task.timing.ITI_incorrect_completed=NaN; end
            if ~isfield(trial(t).task.timing,'grace_time_hand');          trial(t).task.timing.grace_time_hand=NaN; end
            if ~isfield(trial(t).task.timing,'grace_time_eye');           trial(t).task.timing.grace_time_eye=NaN; end
            
            if ~isfield(trial(t).task.eye.fix,'color_dim');     [trial(t).task.eye.fix.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.eye.fix,'color_bright');  [trial(t).task.eye.fix.color_bright]=deal([NaN NaN NaN]);   end
            if ~isfield(trial(t).task.hnd.fix,'color_dim');     [trial(t).task.hnd.fix.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.hnd.fix,'color_bright');  [trial(t).task.hnd.fix.color_bright]=deal([NaN NaN NaN]);   end
            if ~isfield(trial(t).task.eye.tar,'color_dim');     [trial(t).task.eye.tar.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.eye.tar,'color_bright');  [trial(t).task.eye.tar.color_bright]=deal([NaN NaN NaN]);   end
            if ~isfield(trial(t).task.hnd.tar,'color_dim');     [trial(t).task.hnd.tar.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.hnd.tar,'color_bright');  [trial(t).task.hnd.tar.color_bright]=deal([NaN NaN NaN]);   end
            if ~isfield(trial(t).task.eye,'cue') || isfield(trial(t).task.eye.cue,'color_dim');     [trial(t).task.eye.cue.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.eye,'cue') || ~isfield(trial(t).task.eye.cue,'color_bright');  [trial(t).task.eye.cue.color_bright]=deal([NaN NaN NaN]);   end
            if ~isfield(trial(t).task.hnd,'cue') || ~isfield(trial(t).task.hnd.cue,'color_dim');     [trial(t).task.hnd.cue.color_dim]=deal([NaN NaN NaN]);      end
            if ~isfield(trial(t).task.hnd,'cue') || ~isfield(trial(t).task.hnd.cue,'color_bright');  [trial(t).task.hnd.cue.color_bright]=deal([NaN NaN NaN]);   end
            if numel(trial(t).eye.tar(1).reward_time)==1; trial(t).eye.tar(1).reward_time(2)=trial(t).eye.tar(1).reward_time; end
            if numel(trial(t).eye.tar(2).reward_time)==1; trial(t).eye.tar(2).reward_time(2)=trial(t).eye.tar(2).reward_time; end
            if numel(trial(t).hnd.tar(1).reward_time)==1; trial(t).hnd.tar(1).reward_time(2)=trial(t).hnd.tar(1).reward_time; end
            if numel(trial(t).hnd.tar(2).reward_time)==1; trial(t).hnd.tar(2).reward_time(2)=trial(t).hnd.tar(2).reward_time; end
            
            if isfield(trial(t).task.timing,'grace_time_eze');            trial(t).task.timing=rmfield(trial(t).task.timing,'grace_time_eze'); end
            if isempty(trial(t).reach_hand) && trial(t).effector==6 && trial(t).success==1 && ismember(trial(t).task.reach_hand,[1,2]); trial(t).reach_hand=trial(t).task.reach_hand; end
            if any(trial(t).states==13) && any (trial(t).states==12); trial(t).states(trial(t).states==12)=14; trial(t).state(trial(t).state==12)=14; end
        end
        
        if exist('task','var')
            save([datapath filesep dir_datapath(s).name], 'task', 'SETTINGS', 'trial')
        else
            save([datapath filesep dir_datapath(s).name], 'SETTINGS', 'trial')
        end
    end
end

end

function forced = MPA_detect_forced_condition(trial)

su = [trial(:).success];
ef = [trial(:).effector];
ty = [trial(:).type];
ch = [trial(:).choice];
% fh = [trial(:).force_hand];

trialtask=[trial(:).task];
ha = [trialtask.reach_hand];

for n_t = 1:numel(trial) % this loop is not easy to avoid unfortunately
    if numel(trial(n_t).hnd.tar)>0 && isfield(trial(n_t).hnd.tar(1,1),'pos')
        hp_x(n_t) = trial(n_t).hnd.tar(1,1).pos(1);
        hp_y(n_t) = trial(n_t).hnd.tar(1,1).pos(2);
    else
        hp_x(n_t) = NaN;
        hp_y(n_t) = NaN;
    end
    if numel(trial(n_t).eye.tar)>0 && isfield(trial(n_t).eye.tar(1,1),'pos')
        ep_x(n_t) = trial(n_t).eye.tar(1,1).pos(1);
        ep_y(n_t) = trial(n_t).eye.tar(1,1).pos(2);
    else
        ep_x(n_t) = NaN;
        ep_y(n_t) = NaN;
    end
end

forced_or_not=1;
for n_t = 1:numel(trial)-1 % this loop could be avoided in future versions
    if ~su(n_t) && (...
            ~equal_ish(hp_x(n_t),hp_x(n_t+1))   || ~equal_ish(hp_y(n_t),hp_y(n_t+1)) || ...
            ~equal_ish(ep_x(n_t),ep_x(n_t+1))   || ~equal_ish(ep_y(n_t),ep_y(n_t+1)) || ...
            ~equal_ish(ef(n_t),ef(n_t+1))       || ~equal_ish(ty(n_t),ty(n_t+1))     ||...
            ~equal_ish(ha(n_t),ha(n_t+1))       || ~equal_ish(ch(n_t),ch(n_t+1)))
        forced_or_not =0;
        break;
    end
end

% all_unsuccessful = numel(forced_or_not(~isnan(forced_or_not)));
% same = sum(forced_or_not(~isnan(forced_or_not)));
% forced = equal_ish(all_unsuccessful,same);

forced=double(nansum(forced_or_not)==sum(~isnan(forced_or_not)));
end

function equal_or_not = equal_ish(testValue1,testValue2)
if isnan(testValue1) && isnan(testValue2)
   equal_or_not = true; %% important, because this might screw up things if used in a different context
elseif islogical(testValue1) || islogical(testValue2)
   equal_or_not= testValue1==testValue2;
else
subtraction_abs = abs(testValue1 - testValue2);
equal_or_not = (subtraction_abs <= eps(testValue1)) && (subtraction_abs <= eps(testValue2));    
end
end