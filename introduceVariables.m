function variables = introduceVariables(combinedPag, combine,screen)
nVars = length(combinedPag.graph);
nPags =combine.nPags;
variables.adVarCounter =0;

%variables.endpoints = zeros(nVars, nVars);
variables.arrows = zeros(nVars, nVars);
variables.tails = zeros(nVars, nVars);


variables.direct = zeros(nVars, nVars);
variables.eCollider = zeros(nVars, nVars, nVars);
variables.inducing =  zeros(nVars, nVars, nPags);
variables.ancestral = zeros(nVars, nVars, nPags);
variables.nVars =nVars;
variables.pathToTriples =[(1:nVars-2)' (2:nVars-1)' (3:nVars)'];

nEdges = nnz(combinedPag.graph)/2;
variables.direct(triu(~~combinedPag.graph)) = variables.adVarCounter+1:variables.adVarCounter+nEdges;
variables.direct = variables.direct+variables.direct';
variables.adVarCounter = variables.adVarCounter+nEdges;


variables.arrows(~~combinedPag.graph)= variables.adVarCounter+1:variables.adVarCounter+2*nEdges;
variables.adVarCounter = variables.adVarCounter+2*nEdges;

variables.tails(~~combinedPag.graph)= variables.adVarCounter+1:variables.adVarCounter+2*nEdges;
variables.adVarCounter = variables.adVarCounter+2*nEdges;

for X = 1:nVars
    for Y = X+1:nVars        
 %       if combinedPag.dashedEdges(X, Y)       
%             if ~hasPosIndPath(X, Y, combinedPag.graph, combinedPag.dnc, combinedPag.possibleDescendants, sum(all.isLatent, 2), debug)
%                 combinedPag.dashedEdges([X, Y], [X, Y])=0;            
%                 fprintf('Edges %d-%d is direct\n', X, Y);
%             end
        variables.inducing(X, Y, :)  =  variables.adVarCounter+1:variables.adVarCounter+nPags;
        variables.inducing(Y, X, :)  =  variables.adVarCounter+1:variables.adVarCounter+nPags;  
        if screen
            fprintf('Variables %s: Inducing(%d, %d, iPag)\n', num2str(variables.adVarCounter+1:variables.adVarCounter+nPags), X, Y)
        end
        variables.adVarCounter = variables.adVarCounter+nPags;            

        variables.ancestral(X, Y, :) =  variables.adVarCounter+1:variables.adVarCounter+nPags;        
        if screen
            fprintf('Variables %s: %d-^-> %d, iPag)\n', num2str(variables.adVarCounter+1:variables.adVarCounter+nPags), X, Y)
        end
        variables.adVarCounter =  variables.adVarCounter+nPags; 
        variables.ancestral(Y, X, :) =  variables.adVarCounter+1:variables.adVarCounter+nPags;
        if screen
            fprintf('Variables %s: %d-^-> %d, iPag)\n', num2str(variables.adVarCounter+1:variables.adVarCounter+nPags), Y, X)
        end
        variables.adVarCounter =  variables.adVarCounter+nPags;
        
    end
end
