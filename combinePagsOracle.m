function [combinedPag, all] = combinePags_oracle(inputpags, screen)

nPags=size(inputpags,2);
nVars =  size(inputpags(1).graph, 1);
combinedPag.graph = zeros(nVars);
combinedPag.directEdges = false(nVars);
combinedPag.dashedEdges = false(nVars);
combinedPag.dnc = [];

all.pags = zeros(nVars, nVars, nPags);
% all.confounded =  2*ones(nVars, nVars, nPags);        
% all.direct = 2*ones(nVars, nVars, nPags);
all.descendants =  zeros(nVars, nVars, nPags);        
all.possibleDescendants = zeros(nVars, nVars, nPags);
all.isManipulated =  false(nVars, nPags);
all.isLatent = false(nVars, nPags);
all.pvalues = zeros(nVars, nVars, nPags);
all.manipulatedVars = {};
all.dnc ={};
all.colliders ={};
all.ddnc ={};
all.dcolliders ={};

all.nPags = nPags;

% dnc are sorted so that X<Z
for iPag = 1:nPags
    all.pags(:, :, iPag) = inputpags(iPag).graph;
    all.isManipulated(:, iPag) = inputpags(iPag).isManipulated;
    all.isLatent(:, iPag) = inputpags(iPag).isLatent;   
    all.pvalues(:, :, iPag) = inputpags(iPag).pvalues;
    all.dnc{iPag}= inputpags(iPag).dnc;
    all.colliders{iPag} = inputpags(iPag).colliders;
    all.dcolliders{iPag} = inputpags(iPag).dcolliders;
    all.ddcn{iPag}= inputpags(iPag).ddnc;    
end

combinedPag.graph = max(all.pags, [], 3);


% also add edges between: 1.variables that have NEVER been observed
% together OR 2. variables that are NEVER observed unmanipulated together
for X =1:nVars
    if ~any(~all.isLatent(X, :))%if variable not observed in any experiment
        if screen; fprintf('Skipping always latent %d\n', X); end
        continue;
    end    
    for Y = X+1:nVars
        if ~any(~all.isLatent(Y, :))%if variable not observed in any experiment
            if screen; fprintf('Skipping always latent %d\n', Y); end
        continue;
        end    
        if ~~combinedPag.graph(X, Y)
          %   if screen; fprintf('Edge %d-%d is present somewhere\n', X, Y); end
        continue;
        end    
            
        % if the variables have NEVER been observed together
        
        if ~any(~sum(all.isLatent([X, Y], :)))
            if screen;fprintf('Adding %d-%d  NEVER observed together\n', X, Y);end
            combinedPag.graph(X,Y)=1;
            combinedPag.graph(Y,X)=1;
            combinedPag.dashedEdges([X, Y], [X,Y])=[0 1; 1 0];
            % edit: these edges cannot be used for path searching, can add
            % them at the end
        elseif ~any(~sum([all.isManipulated([X, Y], :); all.isLatent([X, Y], :)]))% if variables HAVE been observed together but never non-manipulated
            areBothObserved = repmat(~sum(all.isLatent([X, Y], :)), [2, 1]);
            manipulatedBothObserved = areBothObserved.*all.isManipulated([X, Y], :);
            if ismember([1, 0], manipulatedBothObserved', 'rows') %We have observed X manipulated and Y non manipulated
                if screen;fprintf('Adding %d<-*%d  NEVER observed UNMANIPULATED together\n', X, Y);end
                combinedPag.graph(Y, X)=2;
            else
                combinedPag.graph(Y, X)=1;
            end
            if ismember([0, 1], manipulatedBothObserved', 'rows') %We have observed X manipulated and Y non manipulated
                if screen;fprintf('Adding %d*->%d  NEVER observed UNMANIPULATED together\n', X, Y);end
                combinedPag.graph(X, Y)=2;
            else 
                combinedPag.graph(X, Y)=1;
            end
            if screen;fprintf('Adding %d-%d  NEVER observed UNMANIPULATED together\n', X, Y);end       
            combinedPag.dashedEdges([X, Y], [X,Y])=[0 1; 1 0];   
        end
    end
end

combinedPag.dashedEdges(~~combinedPag.graph)=1;
combinedPag.descendants =  definiteDescendantsPag(combinedPag.graph);
combinedPag.possibleDescendants  =  possibleDescendantsPag(combinedPag.graph);

% Update descendants and possible descendants of all pags according to
% plan.
for iPag =1:nPags
    tmpPag =combinedPag.graph;
    manipulatedVars = find(all.isManipulated(:, iPag));
    [x, y] =  find(combinedPag.graph(:, find(all.isManipulated(:, iPag)))==2);
    y =  manipulatedVars(y);
    y = reshape(y, length(y), 1);
    if ~isempty(x)
        tmpPag(sub2ind(size(tmpPag), x, y))= 0;
        tmpPag(sub2ind(size(tmpPag), y, x)) = 0;
        if screen
            fprintf('%d:Removing edges into manipulatedVars: %s\n', iPag, num2str(x'));
        end
    end
    all.possibleDescendants(:, :, iPag)  =  possibleDescendantsPag(tmpPag);
    % to find definite descendants, also remove dashed edges
    tmpPag(combinedPag.dashedEdges) = 0;
    all.descendants(:, :, iPag) =  definiteDescendantsPag(tmpPag);
end
end