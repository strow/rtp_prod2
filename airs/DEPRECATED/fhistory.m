numEvents = size(p.FunctionHistory,2);
for n = 1:numEvents
    name = p.FunctionTable(p.FunctionHistory(2,n)).FunctionName;
    
    if p.FunctionHistory(1,n) == 0
        disp(['Entered ' name]);
    else
        disp(['Exited ' name]);
    end
end