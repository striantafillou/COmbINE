function variables = eColliderConstraints(fName, combinedPag, variables, screen)

[Xs, Ys, Zs] =  ind2sub(size(variables.eCollider), find(variables.eCollider));

for iCollider =1:length(Xs)
    X =Xs(iCollider); Y = Ys(iCollider);Z = Zs(iCollider);
  
    % if it is a dd collider: 
    if combinedPag.dashedEdges(X, Y)==0 && combinedPag.dashedEdges(Z, Y)==0 && ...
            combinedPag.graph(X, Y)==2 && combinedPag.graph(Z, Y)==2
        clause = [variables.eCollider(X, Y, Z) 0];
        dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
        if screen
            fprintf('%s\n', num2str(clause));
        end
     continue;
    end
    if screen
        fprintf('-eCollider(%d, %d, %d) OR confounded OR direct(%d, %d)//direct(%d, %d)//arrow(%d, %d)//arrow(%d, %d)\n', X,Y,Z, X, Y, Y, Z, X, Y, Z, Y);
    end
    clause = [repmat(-variables.eCollider(X, Y, Z), [2, 1]) ...
        [variables.arrows(X, Y);variables.arrows(Z, Y)]...
        zeros(2, 1)];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d\n', clause');
    end

    clause =  [variables.tails(X,Y) variables.tails(Z, Y) variables.eCollider(X, Y, Z) 0];
    dlmwrite(fName, clause, '-append', 'newline', 'unix', 'delimiter',' ', 'precision', 10);
    if screen
        fprintf('%d %d %d %d\n', clause);
    end

end
