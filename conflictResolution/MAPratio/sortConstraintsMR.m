function [summaryGraph, variables] = sortConstraintsMR(inputpags, fName, outputName, combinedPag, variables, comb, screen)
%add to file sorted constraints
summaryGraph =[];

literals = [unique(variables.direct(~~combinedPag.graph & ~combinedPag.dashedEdges));...
unique(variables.tails(combinedPag.graph==3));...
unique(variables.arrows(combinedPag.graph==2))];
if ~isempty(literals)
    clause = [literals zeros(length(literals), 1)];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ');
    if screen
        fprintf('%d %d \n', clause');
    end
end

addRows = length(literals);
comb.addRows = addRows;
[constraints, addRows, variables] = colliderConstraints(inputpags, fName, variables, comb, screen);

dlmwrite(fName, 'c END','-append', 'newline', 'unix', 'delimiter', '');

% constraints
% 1:x 2:(z) 3:y 4:iPag 5:pValue 6:colliderVar 7:MapRatio 8:edgeType: 1 for
% absent, 2 for present
% sort constraints
[~, ~, pi0hat] = mafdr(constraints(:, 5), 'method', 'bootstrap');
ahat = fminbnd(@(a) negLL(constraints(:, 5), a, pi0hat), 0,1);    
mapRatios = MAPratio(constraints(:, 5), ahat, 1, pi0hat);
present = (constraints(:, 5)< inputpags(1).fciParams.alpha)+1;
mapRatios(present ==2) = 1./mapRatios(present==2);
constraints(:, [7,8]) = [log(mapRatios) present];

[~, sortedInds] = sort(constraints(:, 7), 'descend');
priorities = constraints(sortedInds, :);


query = {' QANEG', ' QAPOS'};
mult =[-1, +1];
for iC =1:size(priorities,1)
    if priorities(iC, 2) ==0   % if constraint regards the presence/absense of an edge
        dlmwrite(fName, [num2str(iC) query{priorities(iC, 8)}],'-append', 'newline', 'unix', 'delimiter', '', 'precision', 10); 
        curVar = variables.inducing(priorities(iC, 1), priorities(iC, 3), priorities(iC, 4));
        dlmwrite(fName, curVar ,'-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10); 
        if screen
            fprintf('%d*inducing(%d, %d) in %d : %d\n', mult(priorities(iC, 8)), priorities(iC, 1),...
                priorities(iC, 3), priorities(iC, 4), curVar);
        end
    else
        dlmwrite(fName, [num2str(iC) query{2}],'-append', 'newline', 'unix', 'delimiter', '', 'precision', 10); 
        dlmwrite(fName, abs(priorities(iC, 6)) ,'-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10); 
        if screen
            fprintf('DNCorCOL(%d, %d %d) in %d : %d\n', priorities(iC, 1), priorities(iC, 2),...
                priorities(iC, 3), priorities(iC, 4), priorities(iC, 6));
        end
    end    
end
dlmwrite(fName, '0 BACKBONE' ,'-append', 'newline', 'unix', 'delimiter',''); 
v = ['1-' num2str(max(max(variables.tails)))];
dlmwrite(fName, v ,'-append', 'newline', 'unix', 'delimiter',''); 
dlmwrite(fName, '9 QUIT', '-append','newline', 'unix', 'delimiter', '');
fclose('all');

string = ['C:\cygwin\bin\bash --login -c C:/cygwin/home/striant/minisat_increment.exe <' fName ' > ' outputName ];
%string = ['minisat_increment.exe <' fName ' > ' outputName ];
system(string);
[summaryGraph, rejCons] = readSATres(outputName, variables, combinedPag);
summaryGraph.reject = priorities(rejCons, :);
summaryGraph.priorities = priorities;
summaryGraph.ahat =ahat;
summaryGraph.pi0 = pi0hat;
summaryGraph.constraints = constraints;
summaryGraph.addRows = addRows+size(constraints,1);
end
