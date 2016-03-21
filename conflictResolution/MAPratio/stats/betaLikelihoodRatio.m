function betaLikelihoodRatio = betaLikelihoodRatio(p, a, b)
% Returns the likelihood ratio p(p|Ho)/p(p|H1) when the p-values follow the Beta(a,b)
% distribution with  for Ho

num = 1;%beta(1,1)* (p.^(1-1).*(1-p).^(1-1));
denom = (1/(beta(a,b))).*(p.^(a-1).*(1-p).^(b-1));
betaLikelihoodRatio =num./denom;
