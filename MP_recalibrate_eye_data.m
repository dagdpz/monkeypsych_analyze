

basefolder='C:\Users\lschneider\Desktop';
project='Pulv_oculomotor';
epoch={'Thol',5,	0.2,    0.5};

load(['Y:\Projects\' project '\ephys\paper\behaviour_filelist.mat'])


conditions={'_dPulv_PT0_Msac_opt','_dPulv_PT0_Vsac_opt'};
for c=1:numel(conditions)
taskcase=conditions{c};
folder_to_save_to=[basefolder filesep project taskcase];
if~exist(folder_to_save_to,'dir')
   mkdir([basefolder filesep], [project taskcase]);
   %     save([folder_to_save_to filesep monkey filesep session{f} filesep filenames{f}],'trial'); 
end

for monkeys={'Cur','Lin'}
    monkey=monkeys{:};
%monkey='Cur';
if~exist([folder_to_save_to filesep monkey],'dir')
   mkdir([folder_to_save_to filesep], monkey);
   %     save([folder_to_save_to filesep monkey filesep session{f} filesep filenames{f}],'trial'); 
end
list=filelist.([monkey taskcase]);

idx=strfind(list{1},monkey);
idx=idx(end);
clear session filenames
%% correct filelist... (this is not needed any more...)
%% think about loading all data for the matrix, then saving only respective files...?
for f=1:numel(list)
    list{f}=[list{f}(1:idx-1) filesep list{f}(idx:end)];
    idx_dash=strfind(list{f},'-');
    list{f}=[list{f}(1:idx_dash(1)-1) list{f}(idx_dash(1):idx_dash(1)+2) list{f}(idx_dash(2):idx_dash(2)+2) list{f}(idx_dash(2)+3:end)]; 
    idx_sep=strfind(list{f},filesep);
    session{f}=list{f}(idx_sep(3)+1:idx_sep(4)-1);
    filenames{f}=list{f}(idx_sep(4)+1:end);
end

unique_sessions=unique(session);
for s=1:numel(unique_sessions)
    ses_idx=find(ismember(session,unique_sessions(s)));
    if~exist([folder_to_save_to filesep monkey filesep unique_sessions{s}],'dir')
        mkdir([folder_to_save_to filesep monkey ], unique_sessions{s});
    end
    saccades_concatenated=[];
    for f=ses_idx
        out=monkeypsych_analyze_working(list(f),{'display',0,'keep_raw_data',1,'success',1,'correct_offset',0});
        saccades=out{1}.saccades;
        states=out{1}.states;
        raw=out{1}.raw;
        for t=1:numel(saccades)
            idx=t;
            on=states(idx).MP_states_onset([states(idx).MP_states]==epoch{2});
            time=raw(idx).time_axis >= on+epoch{3}  & raw(idx).time_axis <= on+epoch{4}; 
            av_pos(t)=median(raw(idx).x_eye(time))+1i*median(raw(idx).y_eye(time));
            saccades(t).eyepos_at_target=av_pos(t);
        end
        if ~isempty(saccades)
        saccades_concatenated=[saccades_concatenated; saccades];
        end
    end
    
    % compute transformation matrix for each session
    clear calibrated_pos
    unique_positions=unique([saccades.tar_pos]);
    for p=1:numel(unique_positions)
        idx=[saccades.tar_pos]==unique_positions(p);
        calibrated_pos(p)=nanmean([saccades(idx).eyepos_at_target]);
    end
    
    transformationType = 'polynomial';
    switch transformationType
        case 'polynomial'
            tform = fitgeotrans([real(unique_positions(:)) imag(unique_positions(:))], [real(calibrated_pos(:)) imag(calibrated_pos(:))], transformationType,2);
        otherwise
            tform = fitgeotrans([real(unique_positions(:)) imag(unique_positions(:))], [real(calibrated_pos(:)) imag(calibrated_pos(:))], transformationType);
    end
    
    
    for f=ses_idx
        load(list{f})
        for t=1:numel(trial)
            [xy]=transformPointsInverse(tform,[trial(t).x_eye trial(t).y_eye]);
            trial(t).x_eye=xy(:,1);
            trial(t).y_eye=xy(:,2);
        end
        save([folder_to_save_to filesep monkey filesep session{f} filesep filenames{f}],'trial','SETTINGS');
    end
end
end
end