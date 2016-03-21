function  variables = blockedConstraints(fName, iTriple, X, Y, iPag,  variables, combine, combinedPag, screen)


%The triple must always be possibly inducing in pag H_i
curTriple = variables.triples(iTriple, :);
p1 = curTriple(1);p2 = curTriple(2); p3= curTriple(3);
tripleVariable = variables.tripleVariables(iTriple);
if screen; fprintf('Var %d: blocked(%d, %d, %d)\n', tripleVariable, p1, p2, p3);end
% if ddnc(p1, p2, p3) && p2\in L the triple cannot be blocked
if  combinedPag.dashedEdges(p1, p2)==0 && combinedPag.dashedEdges(p1, p2)==0    
    if combine.isLatent(p2, iPag) && (combinedPag.graph(p1, p2)==3 || combinedPag.graph(p3, p2)==3)
        clause = [-tripleVariable 0];  
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
        if screen
            fprintf('%s 0\n', num2str(clause));
        end
        return;
    % if deCollider(p1, p2, p3) && p2 is a definite  ancestor the triple cannot be blocked
    elseif (combinedPag.graph(p1, p2)==2 && combinedPag.graph(p3, p2)==2) &&...
            (combine.descendants(p2, X, iPag)||combine.descendants(p2, Y, iPag))
        clause = [-tripleVariable 0];  
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
        if screen
            fprintf('%s 0\n', num2str(clause));
        end
        return;
    end
end
% constraints of type blocked(triple) => ...

% if p2\in L : ~blocked(triple) => eCollider(triple) \wedge
% ~blocked(triple) \vee ~eCollider(triple) \wedge 
% ~blocked(triple) \vee ~ancestral(p2, X) \wedge
% ~blocked(triple) \vee ~ancestral(p2, Y);
if variables.eCollider(p1, p2, p3)==0
    variables.adVarCounter = variables.adVarCounter +1;
    variables.eCollider(p1, p2, p3) = variables.adVarCounter;
    variables.eCollider(p3, p2, p1) = variables.adVarCounter;
end
if combine.isLatent(p2, iPag)
    clause = [repmat([-tripleVariable, -variables.direct(p1, p2) -variables.direct(p2, p3)], [3 1])...
        [variables.eCollider(p1, p2, p3); -variables.ancestral(p2, X, iPag); -variables.ancestral(p2, Y, iPag)]...
        zeros(3, 1)];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d %d %d\n', clause');
    end
    clause = [tripleVariable, variables.direct(p1, p2) 0; tripleVariable, variables.direct(p2, p3) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause');
    end
    clause = [tripleVariable, -variables.eCollider(p1, p2, p3) variables.ancestral(p2, X, iPag) variables.ancestral(p2, Y, iPag) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d %d %d\n', clause);
    end
else
   clause = [repmat([-tripleVariable, -variables.direct(p1, p2) -variables.direct(p2, p3) -variables.eCollider(p1, p2, p3)], [2 1])...
            [ -variables.ancestral(p2, X, iPag); -variables.ancestral(p2, Y, iPag)]...
            zeros(2, 1)];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d %d %d %d\n', clause');
    end
    clause = [variables.direct(p1, p2) tripleVariable 0; variables.direct(p2, p3) tripleVariable 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause');
    end
    clause = [variables.eCollider(p1, p2, p3) tripleVariable 0];    
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n',clause);
    end
    clause = [variables.ancestral(p2, X, iPag) variables.ancestral(p2, Y, iPag) tripleVariable 0];    
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d %d\n', clause);
    end
end
    
    
    

