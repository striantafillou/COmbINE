function inputpags = generateInputPags(datasets, fciParams, screen)
% function inputpags = generateInputPags(datasets, fciParams, screen)
% runs FCI on the datasets and creates the pags to be input to the
% constraint generation algorithm.

nPags = length(datasets);
for iPag =1:nPags    
    pag = FCI(datasets(iPag), 'test', fciParams.test, 'alpha', fciParams.alpha, 'maxK', fciParams.maxK, 'pdsep', fciParams.pdSepStage,...
       'cons',  fciParams.cons, 'verbose', screen);
    pag.isLatent= datasets(iPag).isLatent;
    pag.isManipulated = datasets(iPag).isManipulated;
    pag.fciParams =fciParams;
    inputpags(iPag) = pag;  
end
end