addpath(genpath(pwd)); addpath(genpath('..\causal_graphs'));
clc

clear all;clc;
%cd('C:\Users\striant\Documents\CODE\COmbINE\')
%addpath(genpath('C:\Users\striant\Documents\CODE\COmbINE\'));

%inca_example
graph = zeros(4);
graph(1, 2)=1; graph(2, 3) =1; graph(3, 4) =1;
isLatent = [0 1 0 0; 0 0 1 0]; isLatent = ~~isLatent;
isManipulated = [0 0 0 0; 0 0 0 0]; isManipulated = ~~isManipulated;


screen =false;

[nExperiments, nVars]=size(isLatent);
% fci parameters
fciParams.alpha = 0.1;
fciParams.pdSepStage =0;
fciParams.test ='msep';
fciParams.maxK =4;
fciParams.cons = true;
fName = 'sat.cnf'; 
outputName = 'out.txt'; 


mpl = nVars-1;


[GT.graph, GT.arrows, GT.tails]= dag2smm(graph,sum(isLatent)==nExperiments); 
for iExp =1:nExperiments
    datasets(iExp).isLatent = isLatent(iExp, :);
    datasets(iExp).isManipulated = isManipulated(iExp,:);
    datasets(iExp).data = manipulatesmm(GT.graph, isManipulated(iExp, :));
    datasets(iExp).isAncestor = definiteDescendantsPag(GT.graph);
    datasets(iExp).type = 'oracle';
end

      
[summaryGraph, inputpags, combinedPag] = COmbINE(datasets, fciParams, mpl, fName, outputName, screen);
%

printedgessummarygraph(summaryGraph)

% ---------------------
% 1 o~~o 2
% 1 o~~o 3
% 2 o-o 3
% 2 o~~o 4
% 3 o~~o 4
% This should be the output. If not, there is sth wrong with the SAT
% solver. 

%%

graph = zeros(6);
graph(3, 1) =1; graph(2, 3) =1; graph(3, 4) =1; graph(4, 5) =1; graph(6, 5) =1;
isLatent = false(4, 6); isLatent(1, [3, 5]) =true; isLatent(2, [1:2]) =true; isLatent(3, 5:6)=true; isLatent(4, 3:6) =true;
isManipulated  = false(4, 6); isManipulated(3, 3)=true; isManipulated(4, 2)=true;
screen =false;

[nExperiments, nVars]=size(isLatent);
% fci parameters
fciParams.alpha = 0.1;
fciParams.pdSepStage =0;
fciParams.test ='msep';
fciParams.maxK =4;
fciParams.cons = true;
fName = 'sat.cnf'; 
outputName = 'out.txt'; 

mpl = nVars-1;


[GT.graph, GT.arrows, GT.tails]= dag2smm(graph, sum(isLatent)==nExperiments); 
for iExp =1:nExperiments
    datasets(iExp).isLatent = isLatent(iExp, :);
    datasets(iExp).isManipulated = isManipulated(iExp,:);
    datasets(iExp).data = manipulatesmm(GT.graph, isManipulated(iExp, :));
    datasets(iExp).isAncestor = definiteDescendantsPag(GT.graph);
    datasets(iExp).type = 'oracle';
end


[summaryGraph, inputpags, combinedPag] = COmbINE(datasets, fciParams, mpl, fName, outputName, screen);
%

printedgessummarygraph(summaryGraph);
