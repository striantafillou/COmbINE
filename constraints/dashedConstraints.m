function variables = dashedConstraints(fName, combinedPag, variables, combine, maxPathLength,screen)
nPags =combine.nPags;
[Xs, Ys] = find(triu(combinedPag.graph));
for iEdge = 1:length(Xs)
    X = Xs(iEdge);
    Y = Ys(iEdge);
    if screen
        fprintf('--------------%d-%d---------\n', X, Y)
    end
    pindpaths = getPossibleInducingPathsMaxLength(X, Y, combinedPag.graph,combinedPag.dnc, sum(combine.isLatent, 2), maxPathLength, 0);
    %if nnz(pindpaths)   %  auto den paizei ama to getpossibleminducingpath epistrefei kai to x-y
    nPaths = size(pindpaths,1);    
    for iPag =1:nPags
        if combine.isLatent(X, iPag)|| combine.isLatent(Y, iPag)
            continue;
        end
        variables.triples = []; 
        pathInds = false(1, nPaths);
        pathVariables = zeros(1, nPaths);
        for iPath =1:nPaths
            curPath = pindpaths(iPath, ~~pindpaths(iPath, :));
            if  isPossiblyInducing(curPath, combine.isLatent(:, iPag), combine.isManipulated(:, iPag),...
                    combinedPag.graph, combinedPag.dnc,  combine.possibleDescendants(:,:, iPag))
                pathInds(iPath)=true;
                variables.adVarCounter = variables.adVarCounter+1;
                pathVariables(iPath) = variables.adVarCounter;
                if length(curPath)>2;
                    variables.triples = [variables.triples;curPath(variables.pathToTriples(1:length(curPath)-2, :))];
                end
            end
        end
        nTriples = size(variables.triples, 1);
        if nTriples>0
            sortEndPoints = sort(variables.triples(:, [1 3]),2);
            variables.triples  = [sortEndPoints(:, 1) variables.triples(:, 2) sortEndPoints(:, 2)];
            variables.triples = unique(variables.triples, 'rows');
            nTriples = size(variables.triples, 1);
            variables.tripleVariables = variables.adVarCounter+1:variables.adVarCounter+nTriples;
            variables.adVarCounter = variables.adVarCounter+nTriples;
            variables.usedTriples = false(nTriples, 1);
        end
        for iPath =1:nPaths
            if pathInds(iPath)
                curPath = pindpaths(iPath, ~~pindpaths(iPath, :));
                if screen; fprintf('inducing([%s], %d)\n', num2str(curPath), iPag); end
                 variables = inducingPathConstraints(fName, X, Y, pathVariables(iPath),curPath, iPag, variables, combine,  screen);
                 variables = nonInducingPathConstraints(fName, X, Y, pathVariables(iPath),curPath, iPag, variables, combine, screen);
            end
        end    
        if ~any(pathInds)
            clause = [-variables.inducing(X, Y, iPag) 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            if screen
                fprintf('%d %d\n', clause');
            end
        else
            % constraints: -inducing(X, Y, iPag) \vee p1 ....pn
            if screen
                fprintf('inducing(%d, %d, %d) => 3p: inducing(p)\n', X, Y, iPag)
            end
            clause = [-variables.inducing(X, Y, iPag) pathVariables(pathInds) 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ','precision', 10);
            if screen
                fprintf('%s\n', num2str(clause));
            end
            %constraints: inducing(X, Y, iPag) \vee -p1...-pn
            nPosIndPaths = length(pathVariables(pathInds));
            clause = [repmat(variables.inducing(X, Y, iPag), [nPosIndPaths 1]) -pathVariables(pathInds)' zeros(nPosIndPaths, 1)];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            if screen
                fprintf('%d %d %d\n', clause');
            end
        end
        % now write triple constraints.
        if screen && nTriples>0
            fprintf('Triple Variables %d  to %d\n', X, Y)
        end
        for iTriple =1:nTriples
            if variables.usedTriples(iTriple)
                tripleVariable = variables.tripleVariables(iTriple);
                variables = blockedConstraints(fName, iTriple, X, Y, iPag,  variables, combine, combinedPag, screen);
            end
        end % end for iTriple
    end% end for iPag
%     a =    system('minisat_static.exe xm.cnf result.txt');
%     if a==20
%         return;
%     end
end% end if exists possibly inducing path
end
