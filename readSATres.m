function [summaryGraph, rejCons] = readSATres(oName, variables, combinedPag)
% function [summaryGraph, rejCons] = readSATres(oName, variables, combinedPag)
% read SAT solver result and convert to summary graph.
    fid = fopen(oName, 'r');
    tline = fgetl(fid);tline = fgetl(fid);
    tline = fgetl(fid);
    rejCons=[];
    count =0;
    while ~strcmp(tline, 'BB')
        count = count+1;
        rejCons(count) =str2num(tline(1:strfind(tline, ' ')));
        tline = fgetl(fid);
    end
    
    tline = fgetl(fid);
    if strcmp(tline, 'UNSAT')
        fprintf('Something is Wrong\n')
        summaryGraph = nan;
    else
        res = str2num(tline);
        res = res(1:end-1);
    end
    nVars = variables.nVars;
    verdict = zeros(1, max(max(variables.tails)));
    verdict(abs(res))=sign(res);
    [Xs, Ys] = find(triu(variables.direct));
    summaryGraph.graph = combinedPag.graph;
    summaryGraph.directEdges = zeros(nVars);
    summaryGraph.dashedEdges = zeros(nVars);
    for iEdge =1:length(Xs)
        X =Xs(iEdge);
        Y = Ys(iEdge);
        fbool = verdict(variables.direct(X, Y));
        if fbool == -1; summaryGraph.directEdges([X, Y], [X, Y])=0; summaryGraph.graph([X, Y], [X, Y])=0;
        elseif fbool ==1; summaryGraph.directEdges([X, Y], [X, Y])=[0 1;1 0]; 
            arrow =false; tail = false;
            if verdict(variables.tails(X, Y)) ==1
               tail = true;
               summaryGraph.graph(X, Y)=3;
            end
            if verdict(variables.arrows(X, Y)) ==1
               arrow = true;
               summaryGraph.graph(X, Y)=2;
            end
            if arrow && tail
                summaryGraph.graph(X, Y) = 4;
            end
            arrow =false; tail = false;
            if verdict(variables.tails(Y, X)) ==1
               tail = true;
               summaryGraph.graph(Y, X)=3;
            end
            if verdict(variables.arrows(Y, X)) ==1
               arrow = true;
               summaryGraph.graph(Y, X)=2;
            end
            if arrow && tail
                summaryGraph.graph(Y, X) = 4;
            end   
        else
            summaryGraph.dashedEdges([X, Y], [X, Y])=[0 1;1 0];
            arrow =false; tail = false;
            if verdict(variables.tails(X, Y)) ==1
               tail = true;
               summaryGraph.graph(X, Y)=3;
            end
            if verdict(variables.arrows(X, Y)) ==1
               arrow = true;
               summaryGraph.graph(X, Y)=2;
            end
            if arrow && tail
                summaryGraph.graph(X, Y) = 4;
            end
            arrow =false; tail = false;
            if verdict(variables.tails(Y, X)) ==1
               tail = true;
               summaryGraph.graph(Y, X)=3;
            end
            if verdict(variables.arrows(Y, X)) ==1
               arrow = true;
               summaryGraph.graph(Y, X)=2;
            end
            if arrow && tail
                summaryGraph.graph(Y, X) = 4;
            end   
        end
    end    
    fclose(fid);
end
