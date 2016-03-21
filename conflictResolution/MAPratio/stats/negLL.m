function [negLL , dnegLL] = negLL(x, a, pi0)
nlls = log(pi0+(1-pi0)*a*x.^(a-1));
negLL = -sum(nlls);

denom = pi0+(1-pi0)*a*x.^(a-1);
num = (pi0-1)*x.^(a-1)+ a*(pi0-1)*x.^(a-1).*log(x);
dnegLL =sum((num)./(denom));
end