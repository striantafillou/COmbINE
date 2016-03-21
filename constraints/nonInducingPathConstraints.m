function variables =nonInducingPathConstraints(fName, X, Y, pathVariable,curPath, iPag, variables, combine, screen)
% if debug
%     fprintf('Constraints for  %d <=[%s] in pag %d\n', pathVariable, num2str(curPath),iPag);
% end

% constraints of type -[(x\in i =>tail(p2, x)) \wedge (y\in i =>tail(pn, y))
% \wedge foreach triple -blocked(triple)] \vee e-inducing(path)
% if length = 1 -inducing(path) \vee direct(X, Y) \vee( \not X\in i \wedge
% \not Y\in i \wedge confounded(X, Y);
if  length(curPath)==2 %&& all.isManipulated(X, iPag)~=1 && all.isManipulated(X, iPag)~=1;
    clause = [-variables.tails(curPath(2), X)*combine.isManipulated(X, iPag)...
    -variables.tails(curPath(end-1), Y)*combine.isManipulated(Y, iPag)...
    -variables.direct(X, Y) pathVariable];
    clause = [clause(~~clause) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%s\n', num2str(clause));
    end
%     clause = [variables.endpoints(curPath(2), X)*all.isManipulated(X, iPag)...
%     variables.endpoints(curPath(end-1), Y)*all.isManipulated(Y, iPag) pathVariable];
%     clause = [clause(~~clause) 0];
%     dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ');
%     if screen
%         fprintf('%s\n', num2str(clause));
%     end
else
    % if length>1 \foreach triple -inducing(path) \vee blocked(triple);
    nTriples = length(curPath)-2;
    curTriples = curPath(variables.pathToTriples(1:nTriples, :));
    variables.usedTriples(ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)], 'rows'))= true;
    curTripleVariables = variables.tripleVariables...
        (ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)],  'rows'));
    clause = [-variables.tails(curPath(2), X)*combine.isManipulated(X, iPag)...
    -variables.tails(curPath(end-1), Y)*combine.isManipulated(Y, iPag) curTripleVariables pathVariable];
    clause = [clause(~~clause) 0];  
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%s\n', num2str(clause));
    end
end

end


