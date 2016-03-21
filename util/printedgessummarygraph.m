function []= printedgessummarygraph(graphstruct)
fprintf('---------------------\n')
nVars = length(graphstruct.graph);
symbolsXY = {'/', 'o', '>', '-', 'z'};
symbolsYX = {'/','o', '<', '-', 'z'};
pag = graphstruct.graph;
if isfield(graphstruct, 'headers')
    headers = graphstruct.headers;
    for X =1:nVars
        for Y =X+1:nVars
            if pag(X, Y) 
                if graphstruct.directEdges(X, Y)
                fprintf('%s %s-%s %s\n', headers{X}, symbolsYX{pag(Y, X)+1},symbolsXY{pag(X, Y)+1}, headers{Y});
                elseif graphstruct.dashedEdges(X,Y)
                   fprintf('%s %s~~%s %s\n', headers{X}, symbolsYX{pag(Y, X)+1},symbolsXY{pag(X, Y)+1}, headers{Y})
                end
            end
        end
    end
else
    for X =1:nVars
        for Y =X+1:nVars
            if pag(X, Y) 
                if graphstruct.directEdges(X, Y)
                fprintf('%d %s-%s %d\n', X, symbolsYX{pag(Y, X)+1},symbolsXY{pag(X, Y)+1}, Y);
                elseif graphstruct.dashedEdges(X,Y)
                   fprintf('%d %s~~%s %d\n', X, symbolsYX{pag(Y, X)+1},symbolsXY{pag(X, Y)+1}, Y)
                end
            end
        end
    end
end
end
