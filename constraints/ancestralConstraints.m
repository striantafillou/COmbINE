function variables =  ancestralConstraints(fName, combinedPag, combine, variables, maxPathLength, screen)
if screen
    fprintf('---------------AncestorConstraints----------------\n');
end
nVars = variables.nVars;
nPags = combine.nPags;

[Xs, Ys] = find(variables.ancestral(:, :, 1));
for iAnc =1:length(Xs)
    X = Xs(iAnc); 
    Y = Ys(iAnc);    
    % arrow OR tail
    if combinedPag.graph(X, Y)
        clause = [variables.tails(X, Y) variables.arrows(X, Y) 0];
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter', ' ', 'precision', 10);
        if screen 
            fprintf('%d %d %d\n', clause);
        end
    end
    %no tail OR no tail
    if combinedPag.graph(X, Y) && X<Y
        clause = [-variables.tails(X, Y) -variables.tails(Y, X) 0];
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
        if screen 
            fprintf('%d %d %d\n', clause);
        end
    end
    if screen
        fprintf('-------%d-^-> %d--------\n', X, Y);
    end
    % If X is not a possible descendant of Y in the combinedPag.
    [~,pdPaths] =  getPossibleDescendingPathsMaxLength(X, Y, maxPathLength, combinedPag.graph); %if Y is a possibly descending path.
    if combinedPag.possibleDescendants(X, Y)==0 || nnz(pdPaths)==0
        clause = [ squeeze(-variables.ancestral(X, Y, :)) zeros(nPags, 1)];
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
        if screen
            fprintf('%d %d\n', clause');
        end
        continue;
    else
        nPdPaths =size(pdPaths, 1);    
        pdPathVars = variables.adVarCounter+1:variables.adVarCounter+nPdPaths;       
        variables.adVarCounter =  variables.adVarCounter+nPdPaths;
        for iPag = 1:combine.nPags    
%             if all.isLatent(X, iPag) || all.isLatent(Y, iPag)
%                 continue;
%             end
            if X<Y
                clause = [-variables.ancestral(X,Y, iPag) -variables.ancestral(Y, X, iPag) 0];
                dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ',  'precision', 10);
                if screen
                    fprintf('%d %d %d\n', clause');
                end
            end
            if screen
                fprintf('%d-^->:%d in pag %d\n', X, Y, iPag);
            end
            if combine.descendants(X, Y, iPag)
                clause = [variables.ancestral(X, Y, iPag) 0];
                dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
                if screen
                    fprintf('%d %d\n', clause');
                end
            elseif ~combine.possibleDescendants(X, Y, iPag);
                clause = [-variables.ancestral(X, Y, iPag) 0];
                dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
                if screen
                    fprintf('%d %d\n', clause');
                end
            else
                vars =false(1, nPdPaths);            
                for iPath = 1:nPdPaths
                    curPath = pdPaths(iPath, ~~pdPaths(iPath,:));
                    if isPossiblyDescending(curPath, combinedPag.graph, combine.isManipulated(:, iPag))
                        vars(iPath)=1; 
                    end
                end
                if any(vars)
                    clause = [-variables.ancestral(X, Y, iPag) pdPathVars(vars) 0];
                    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
                    if screen
                        fprintf('%s\n', num2str(clause));
                    end
                    clause = [-pdPathVars(vars)' repmat(variables.ancestral(X, Y, iPag), [length(pdPathVars(vars)),1]),...
                        zeros(length(pdPathVars(vars)), 1)];
                    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
                    if screen
                        fprintf('%d %d %d\n', clause');
                    end
                else
                    clause = [-variables.ancestral(X, Y, iPag) 0];
                    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
                    if screen
                        fprintf('%d %d\n', clause');
                    end
                end % end if any pdpath
            end % if -elseif-else search paths for iPag
        end% end for iPag         
        % now write descendant path caluses
        for iPath = 1:nPdPaths
            curPath = pdPaths(iPath, ~~pdPaths(iPath,:));    
            pathVariable = pdPathVars(iPath);
            from = curPath(1:end-1); to = curPath(2:end);
            toBeTails = variables.tails(sub2ind([nVars, nVars], to, from));
            toBeDirect = variables.direct(sub2ind([nVars, nVars], from, to));
            clause = [repmat(-pathVariable, [(length(curPath)-1)*2, 1]) [toBeDirect'; toBeTails'], zeros(2*(length(curPath)-1), 1)];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            if screen
                fprintf('%d %d %d\n', clause');
            end
            clause = [-toBeDirect -toBeTails pathVariable 0];
            dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
            if screen
                fprintf('%s\n', num2str(clause));
            end
        end
%         command = ['minisat_static.exe ',fName, ' result.txt'];
%         system(command);
%         fid3 = fopen('result.txt', 'r');
%         tline = fgetl(fid3);
%         if strcmp(tline,'UNSAT')
%             return;
%         end
    end 
end% end for iAnc


