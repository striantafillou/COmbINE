function MAPratio = MAPratio(p, alpha, beta, p0)
% Returns the likelihood ratio p(Ho|p)/p(H1|p) when the p-values follow the Beta(alpha, beta)
% distribution with alpha, beta =1 for Ho

MAPratio = betaLikelihoodRatio(p, alpha, beta)*(p0/(1-p0));
end