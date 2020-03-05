function forced = MPA_detect_forced_condition(path)

load(path)
su = [trial(:).success];
ef = [trial(:).effector];
ty = [trial(:).type];
ha = [trial(:).reach_hand];
ch = [trial(:).choice];
% fh = [trial(:).force_hand];

for n_t = 1:numel(trial)
    if numel(trial(n_t).hnd.tar)>0
    hp_x(n_t) = trial(n_t).hnd.tar(1,1).pos(1);
    hp_y(n_t) = trial(n_t).hnd.tar(1,1).pos(2);
    else
    hp_x(n_t) = NaN;
    hp_y(n_t) = NaN;        
    end
    if numel(trial(n_t).eye.tar)>0
    ep_x(n_t) = trial(n_t).eye.tar(1,1).pos(1);
    ep_y(n_t) = trial(n_t).eye.tar(1,1).pos(2);
    else
    ep_x(n_t) = NaN;
    ep_y(n_t) = NaN;        
    end
end

% forced_or_not=0;
% for n_t = 1:numel(trial)-1
%     if su(n_t)
%         forced_or_not(n_t+1) = nan;
%     elseif ~su(n_t) && equal_ish(hp_x(n_t),hp_x(n_t+1)) && equal_ish(hp_y(n_t),hp_y(n_t+1)) && ...
%             equal_ish(ep_x(n_t),ep_x(n_t+1)) && equal_ish(ep_y(n_t),ep_y(n_t+1)) && ...
%             equal_ish(ef(n_t),ef(n_t+1)) && ...
%             equal_ish(ty(n_t),ty(n_t+1)) && ...
%             equal_ish(ha(n_t),ha(n_t+1)) && ...
%             equal_ish(ch(n_t),ch(n_t+1)) 
%         forced_or_not(n_t+1) = 1;
%     else
%         forced_or_not(n_t+1) = 0;
%     end
% end


forced_or_not=1;
for n_t = 1:numel(trial)-1
    if ~su(n_t) && ...
            (~equal_ish(hp_x(n_t),hp_x(n_t+1))  || ~equal_ish(hp_y(n_t),hp_y(n_t+1)) || ...
            ~equal_ish(ep_x(n_t),ep_x(n_t+1))   || ~equal_ish(ep_y(n_t),ep_y(n_t+1)) || ...
            ~equal_ish(ef(n_t),ef(n_t+1))       || ~equal_ish(ty(n_t),ty(n_t+1))     ||...
            ~equal_ish(ha(n_t),ha(n_t+1))       || ~equal_ish(ch(n_t),ch(n_t+1)))
        forced_or_not =0;
        break;
    end
end

all_unsuccessful = numel(forced_or_not(~isnan(forced_or_not)));
same = sum(forced_or_not(~isnan(forced_or_not)));
forced = equal_ish(all_unsuccessful,same);


