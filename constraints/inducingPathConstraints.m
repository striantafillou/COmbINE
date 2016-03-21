function variables = inducingPathConstraints(fName, X, Y, pathVariable,curPath, iPag, variables, combine, screen)
% if screen 
%     fprintf('Constraints for  %d => [%s] in pag %d\n', pathVariable, num2str(curPath),iPag);
% end

% constraints of type -inducing(path)\vee (x\in i =>tail(p2, x)) \wedge (y\in i =>tail(pn, y))
% \wedge foreach path e-inducing(path)

%-inducing(path)\vee (x\in i =>tail(p2, x))
if combine.isManipulated(X, iPag)
    clause = [-pathVariable variables.tails(curPath(2), X) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause);
    end
end

%-inducing(path)\vee (x\in i =>tail(pn, x))
if combine.isManipulated(Y, iPag) 
    clause = [-pathVariable variables.tails(curPath(end-1), Y) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause);
    end
end   
    
% if length = 1 -inducing(path) \vee direct(X, Y) \vee( \not X\in i \wedge
% \not Y\in i \wedge confounded(X, Y);
if  length(curPath)==2 %%&& ~all.isManipulated(X, iPag) && ~all.isManipulated(X, iPag)~=1;
    clause = [-pathVariable variables.direct(X, Y) 0];  
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause);
    end
else
    % if length>1 \foreach triple -inducing(path) \vee -blocked(triple);
    nTriples = length(curPath)-2;
    curTriples = curPath(variables.pathToTriples(1:nTriples, :));
    variables.usedTriples(ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)], 'rows'))= true;
    curTripleVariables = variables.tripleVariables...
        (ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)],  'rows'));
    clause = [repmat(-pathVariable, [nTriples 1]) -curTripleVariables'  zeros(nTriples, 1)];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause');
    end
end
end


