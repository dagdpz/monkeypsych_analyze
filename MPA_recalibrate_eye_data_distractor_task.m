

basefolder='Y:\Projects\Pulv_distractor_spatial_choice\behavior';
project='Pulv_oculomotor';
epoch={'Thol',5,	0.2,    0.5};

Beh_create_distractor_inactivation_filelist;


conditions={'control','inactivation'};
for c=1:numel(conditions)
    taskcase=conditions{c};  
    
    for monkeys={'Cornelius','Curius'}
        monkey=monkeys{:};
        %monkey='Cur';
        if~exist([basefolder filesep monkey],'dir')
            mkdir([basefolder filesep], monkey);
            %     save([basefolder filesep monkey filesep session{f} filesep filenames{f}],'trial');
        end
        list_pre=filelist.([monkey '_' taskcase '_pre']);
        list_post=filelist.([monkey '_' taskcase]);
        %
        % idx=strfind(list{1}{1},monkey(1:3));
        % idx=idx(end);
        % clear session filenames
        % %% correct filelist... (this is not needed any more...)
        % %% think about loading all data for the matrix, then saving only respective files...?
        % for f=1:numel(list)
        %     list{f}=[list{f}(1:idx-1) filesep list{f}(idx:end)];
        %     idx_dash=strfind(list{f},'-');
        %     list{f}=[list{f}(1:idx_dash(1)-1) list{f}(idx_dash(1):idx_dash(1)+2) list{f}(idx_dash(2):idx_dash(2)+2) list{f}(idx_dash(2)+3:end)];
        %     idx_sep=strfind(list{f},filesep);
        %     session{f}=list{f}(idx_sep(3)+1:idx_sep(4)-1);
        %     filenames{f}=list{f}(idx_sep(4)+1:end);
        % end
        
        
        clear session
        %% correct filelist... (this is not needed any more...)
        %% think about loading all data for the matrix, then saving only respective files...?
        for f=1:numel(list_pre)
            idx_sep=strfind(list_pre{f}{1},filesep);
            session{f}=list_pre{f}{1}(idx_sep(end)+1:end);
        end
        
        
        unique_sessions=unique(session);
        for s=1:numel(unique_sessions)
            ses_idx=find(ismember(session,unique_sessions(s)));
            if~exist([basefolder filesep monkey filesep unique_sessions{s}],'dir')
                mkdir([basefolder filesep monkey ], unique_sessions{s});
            end
            saccades_concatenated=[];
            out=monkeypsych_analyze_working(list_pre{s},{'display',0,'keep_raw_data',1,'completed',1,'correct_offset',0,'runs_as_batches',1});
            
            for r=1:numel(out)
                saccades=out{r}.saccades;
                states=out{r}.states;
                raw=out{r}.raw;
                for t=1:numel(saccades)
                    idx=t;
                    on=states(idx).MP_states_onset([states(idx).MP_states]==epoch{2});
                    if size(on,1)==0
                    time=[];
                    else
                    time=raw(idx).time_axis >= on+epoch{3}  & raw(idx).time_axis <= on+epoch{4};
                    end
                    av_pos(t)=median(raw(idx).x_eye(time))+1i*median(raw(idx).y_eye(time));
                    saccades(t).eyepos_at_target=av_pos(t);
                end
                if ~isempty(saccades)
                    saccades_concatenated=[saccades_concatenated; saccades];
                end
            end
            
            % compute transformation matrix for each session
            clear calibrated_pos
            saccades_concatenated(isnan([saccades_concatenated.eyepos_at_target]))=[];
            unique_positions=unique([saccades_concatenated.tar_pos]);
            unique_fixations=unique([saccades_concatenated.fix_pos]);
            unique_positions(ismember(unique_positions,unique_fixations))=[]; 
            
            [~,indexes]=unique(round(unique_positions));
            unique_positions=unique_positions(indexes);
            for p=1:numel(unique_positions)
                idx=abs([saccades_concatenated.tar_pos]-unique_positions(p))<0.6;
                calibrated_pos(p)=nanmean([saccades_concatenated(idx).eyepos_at_target]);
            end
            
            transformationType = 'pwl'; %'polynomial';
            switch transformationType
                case 'polynomial'
                    tform = fitgeotrans([real(unique_positions(:)) imag(unique_positions(:))], [real(calibrated_pos(:)) imag(calibrated_pos(:))], transformationType,2);
                otherwise
                    tform = fitgeotrans([real(unique_positions(:)) imag(unique_positions(:))], [real(calibrated_pos(:)) imag(calibrated_pos(:))], transformationType);
            end
            
            runs_in_post=list_post{s}{2};
            %runs_in_post=list_pre{s}{2};
            
            
            for r=runs_in_post
                filename=[monkey(1:3) unique_sessions{s}(1:4) '-' unique_sessions{s}(5:6) '-' unique_sessions{s}(7:8) '_' sprintf('%02d',r) '.mat'];
                load([list_pre{s}{1} filesep filename])
                for t=1:numel(trial)
                    [xy]=transformPointsInverse(tform,[trial(t).x_eye trial(t).y_eye]);
                    %[xy]=transformPointsInverse(tform,[real(calibrated_pos(:)) imag(calibrated_pos(:))]);
                    
                    trial(t).x_eye=xy(:,1);
                    trial(t).y_eye=xy(:,2);
                end
                save([basefolder filesep monkey filesep unique_sessions{s} filesep filename],'trial','SETTINGS');
            end
        end
    end
end