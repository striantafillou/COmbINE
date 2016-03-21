function [constraints, addRows, variables] = colliderConstraints(inputpags, fName, variables, comb, screen)
nPags =comb.nPags;
addRows = comb.addRows;
nVars =variables.nVars;
constraints =nan(nVars, 8);
counter =0;
for iPag =1:nPags
    pValues = triu(inputpags(iPag).pvalues);
    [x, y] = find(pValues>0);
    pValues = pValues(pValues>0);
    n = length(pValues);
    constraints(counter+1:counter+n, 1:6) = [x  zeros(n, 1) y iPag*ones(n, 1)  pValues nan*ones(n, 1)];
    counter =counter+n;
    nDncs = size(comb.dnc{iPag},1);  
    if nDncs>0
        constraints(counter+1:counter+nDncs, 1:6) = [comb.dnc{iPag} iPag*ones(nDncs, 1)...
            comb.pvalues(sub2ind([nVars nVars nPags], comb.dnc{iPag}(:, 1),  comb.dnc{iPag}(:, 3), iPag*ones(nDncs, 1))) ones(nDncs, 1)];%pvalues
        for i =1:nDncs
            % definite non-collider Constraints dnc(x, y, z, iPag) ->
            % inducing(x, y, iPag) \wedge inducing (y, z, iPag) \wedge \neg
            % inducing(x, z, iPag) \wedge (ancestral(y, x)\vee ancestral(y,
            % z)
            x  = constraints(counter+i, 1);y = constraints(counter+i, 2);z = constraints(counter+i, 3);
            constraints(counter+i, 6) = variables.adVarCounter+1;            
            variables.adVarCounter= variables.adVarCounter+1;            
            clause = [-constraints(counter+i, 6)  variables.inducing(x, y, iPag) 0;
                       -constraints(counter+i, 6) variables.inducing(y, z, iPag) 0;
                       -constraints(counter+i, 6) -variables.inducing(x, z, iPag) 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            clause =[ -constraints(counter+i, 6) variables.ancestral(y, x, iPag) variables.ancestral(y, z, iPag) 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            addRows = addRows+4;
            if screen
                fprintf('DNC %d:  %d-%d-%d:\n', variables.adVarCounter, x, y, z)
                fprintf('%d %d %d %d %d %d %d\n', clause');
            end            
        end
        counter = counter+nDncs;
    end
    nColliders = size(comb.colliders{iPag},1);
    if nColliders>0
        constraints(counter+1:counter+nColliders, 1:6) = [comb.colliders{iPag} iPag*ones(nColliders, 1)...
            comb.pvalues(sub2ind([nVars nVars nPags], comb.colliders{iPag}(:, 1),  comb.colliders{iPag}(:, 3), iPag*ones(nColliders, 1))) -1*ones(nColliders, 1)];
        for i =1:nColliders
            x  = constraints(counter+i, 1);y = constraints(counter+i, 2);z = constraints(counter+i, 3);
            constraints(counter+i, 6) = -(variables.adVarCounter+1);            
            variables.adVarCounter = variables.adVarCounter+1;
            clause = [-constraints(counter+i, 6)  variables.inducing(x, y, iPag) 0;
                       -constraints(counter+i, 6) variables.inducing(y, z, iPag) 0;
                       -constraints(counter+i, 6) -variables.inducing(x, z, iPag) 0;
                       -constraints(counter+i, 6) -variables.ancestral(y, x, iPag) 0;
                       -constraints(counter+i, 6) -variables.ancestral(y, z, iPag) 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            addRows = addRows+5;
            if screen
                fprintf('COL %d:  %d-%d-%d:\n', variables.adVarCounter, x, y, z)
                fprintf('%d %d %d %d %d %d \n', clause');
            end
        end
        counter = counter+nColliders;
    end
    %you need to do the same for definite discriminating (non) colliders
end
end
