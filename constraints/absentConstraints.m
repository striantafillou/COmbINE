function variables= absentConstraints(fName,combinedPag, variables, combine, maxPathLength, screen)
nPags =combine.nPags;
[Xs, Ys] = find(triu(~combinedPag.graph,1));
for iEdge = 1:length(Xs)
    X = Xs(iEdge);
    Y = Ys(iEdge);
    if screen
        fprintf('--------------%d-%d---------\n', X, Y)
    end
    pindpaths = getPossibleInducingPathsMaxLength(X, Y, combinedPag.graph,combinedPag.dnc,  sum(combine.isLatent, 2), maxPathLength,0);
    if nnz(pindpaths)
        nPaths = size(pindpaths, 1);
        for iPag =1:nPags
            if combine.isLatent(X, iPag) || combine.isLatent(Y, iPag)
                continue;
            end
            variables.triples = []; 
            isPind = false(nPaths);
            for iPath =1:nPaths
                curPath = pindpaths(iPath, ~~pindpaths(iPath, :));
                if  isPossiblyInducing(curPath, combine.isLatent(:, iPag), combine.isManipulated(:, iPag),...
                    combinedPag.graph, combinedPag.dnc, combine.possibleDescendants(:,:, iPag))
                    isPind(iPath)=true;
                    if length(curPath)>2;
                        variables.triples = [variables.triples;curPath(variables.pathToTriples(1:length(curPath)-2, :))];
                    end
                end
            end % end for iPath
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
                if isPind(iPath)                    
                    curPath = pindpaths(iPath, ~~pindpaths(iPath, :));
                    if screen
                        fprintf('-inducing(%s) in %d\n', num2str(curPath),iPag);
                    end
                    nPathTriples = length(curPath)-2;
                    curTriples = curPath(variables.pathToTriples(1:nPathTriples, :));
                    variables.usedTriples(ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)],  'rows'))= true;
                    curTripleVariables = variables.tripleVariables...
                        (ismember(variables.triples, [curTriples; curTriples(:, 3) curTriples(:, 2) curTriples(:,1)],  'rows'));
                    clause = [variables.inducing(X, Y, iPag) variables.arrows(curPath(2), X)*combine.isManipulated(X, iPag)...
                        variables.arrows(curPath(end-1), Y)*combine.isManipulated(Y, iPag) curTripleVariables];
                    clause = [clause(~~clause) 0];
                    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ',  'precision', 10);
                    if screen
                        fprintf('%s\n', num2str(clause));
                    end
                end
            end
            for iTriple =1:nTriples
                if variables.usedTriples(iTriple)
                    %tripleVariable = variables.tripleVariables(iTriple);
                    variables = blockedConstraints(fName, iTriple, X, Y, iPag,  variables, combine, combinedPag, screen);
                end            
            end % end for iTriple
%             a =    system('minisat_static.exe xm.cnf result.txt');
%             if a==20
%                 return;
%             end

        end% end for iPag
    end
end
end