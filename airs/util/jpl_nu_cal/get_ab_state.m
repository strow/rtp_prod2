function ab_time = get_ab_state(mtime);
% 
% Output: ab_time is a int32 array of AIRS AB State for the input time mtime
% Input:  mtime is the time desired for AB state in datetime units
%   
% Example:  ab = get_ab_state(datetime(2013,2,11));  (can add hours, minutes if desired)    
   
% Don't reload ab table each time call function
persistent ab mtime_start   
if isempty(ab)
   load ab
end

if mtime >= mtime_start(end)
   ab_time = ab(end,:);
else
   k = find( mtime_start >= mtime,1) - 1;
   ab_time = ab(k,:);
end



