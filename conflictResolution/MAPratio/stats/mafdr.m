function [fdr, q, pi0, rs] = mafdr(p, varargin)
%MAFDR estimates false discovery rates (FDR) of multiple hypotheses testing
% of gene expression data from a microarray experiment.
%
%   FDR = MAFDR(P) computes the FDR from the p-values P of the hypotheses
%   tests of gene expression data obtained by a microarray experiment. If P
%   is a DataMatrix object and has non-empty row names, FDR is a DataMatrix
%   object with the same row names as P and 'FDR' as column name.
%
%   Note: The false discovery rates are computed using procedures described
%   by Storey (2002), and by Benjamini and Hochberg(1995). By default the
%   positive FDR follow Storey (2002) are computed. To compute the FDR
%   using Benjamini and Hochberg (1995), you need to set the BHFDR option
%   to true.
%
%   [FDR,Q] = MAFDR(...) returns the q-value for each gene Q if using
%   Storey (2002) procedure. If input p-values P is a DataMatrix object, Q
%   is a DataMatrix object with the same row names as P and 'q-values' as
%   column name.
% 
%   [FDR,Q,PIO] = MAFDR(...) returns the estimated true null hypotheses PI0
%   if using Storey (2002) procedure.
% 
%   [FDR,Q,PIO,RS] = MAFDR(...) returns the square of correlation
%   coefficient RS if using Storey (2002) procedure and using 'polynomial'
%   method in estimating true null hypotheses PI0.
%
%   [FDR] = MAFDR(..., 'BHFDR', TF) returns the FDR adjusted p-values by
%   linear-step up (LSU) procedure originally introduced by Benjamini and
%   Hochberg(1995) if TF is set true. If this option is set true, all other
%   options except SHOWPLOT option in this function are ignored. Default is
%   false.
% 
%   MAFDR(...,'LAMBDA',L) sets the range of the tuning parameter lambda
%   used in estimating true null hypotheses PI0 by values specified, or set
%   the tuning parameter to a single value. The values must be greater than
%   0 and less than 1. If a range of values is specified, the function will
%   automatically choose the tuning parameter lambda in the estimate of
%   PI0, the minimum number of values is 4. If only one value is given,
%   lambda is set to this value. Default is set to a range
%   [0.01:0.01:0.95].
%   
%   MAFDR(...,'METHOD',METHOD) sets a method to automatically choose tuning
%   parameter lambda in the estimate of true null hypotheses PI0. METHOD
%   can be 'bootstrap'(default) or 'polynomial'(the cubic polynomial). If
%   the LAMBDA option is only given one value, then this option is ignored.
%
%   MAFDR(...,'SHOWPLOT',TF) displays the plot of estimated true null
%   hypotheses PI0 versus tuning parameter lambda with the cubic polynomial
%   fitting curve, and the plot of q-values vs. p-values if TF is set to
%   true and using Storey (2002) procedure (by default). If TF is set to
%   true, and 'BHFDR' is true, the plot of FDR adjusted p-values vs.
%   p-values is displayed. The default is false. 
% 
%   Example:
%       load prostatecancerexpdata;
%       p = mattest(dependentData, independentData, 'permute', true);
%       [fdr, q] = mafdr(p, 'showplot', true);
%   
%   See also AFFYGCRMA, AFFYRMA, GCRMA, MAIRPLOT, MALOGLOG, MAPCAPLOT,
%   MATTEST, MAVOLCANOPLOT, RMASUMMARY. 

% Copyright 2006-2008 The MathWorks, Inc.
% $Revision: 1.1.6.12 $   $Date: 2010/10/08 16:35:43 $ 

% References: 
% [1] J.D. Storey. "A direct approach to false discovery rates",
%     Journal of the Royal Statistical Society, B (2002), 64(3),
%     pp.479-498.
% [2] J.D. Storey, and R. Tibshirani. "Statistical significance for
%     genomewide studies", Proc.Nat.Acad.Sci. 2003, 100(16), pp. 9440-9445.
% [3] J.D. Storey, J.E. Taylor and D. Siegmund. "Strong control,
%     conservative point estimation, and simultaneous conservative
%     consistency of false discovery rates: A unified approach", Journal of
%     the Royal Statistical Society, B (2004), 66, pp. 187-205.
% [4] Y.Benjamini, Y.Hochberg. "Controlling the false discovery rate: a
%     practical and powerful approach to multiple testing. Journal of the
%     Royal Statistical Society, B (1995), 57, pp.289-300.

% Check the inputs
bioinfochecknargin(nargin,1,mfilename);

if isa(p, 'bioma.data.DataMatrix')
    rownames = p.RowNames;
    p = p.(':')(':');
else
    rownames = [];
end

if ~isnumeric(p) || ~isreal(p) || ~isvector(p)
    error('Bioinfo:mafdr:PValuesNotNumericAndRealVector',...
            'p-values must be numeric and real vector.')
end

% Initialization
bhflag = false;
showplotflag = false;
lambda = (0.01:0.01:0.95);
bootflag = true;

% deal with the various inputs
if nargin > 1
    if rem(nargin,2) == 0
        error('Bioinfo:mafdr:IncorrectNumberOfArguments',...
            'Incorrect number of arguments to %s.',mfilename);
    end
    okargs = {'bhfdr', 'lambda', 'method', 'showplot'};
    for j=1:2:nargin-2
        pname = varargin{j};
        pval = varargin{j+1};
        k = find(strncmpi(pname, okargs,length(pname)));
        if isempty(k)
            error('Bioinfo:mafdr:UnknownParameterName',...
                'Unknown parameter name: %s.',pname);
        elseif length(k)>1
            error('Bioinfo:mafdr:AmbiguousParameterName',...
                'Ambiguous parameter name: %s.',pname);
        else
            switch(k)
                case 1 % BH FDR
                    bhflag = bioinfoprivate.opttf(pval,okargs{k},mfilename);
                case 2 % lambda
                    if ~isnumeric(pval) && isvector(pval) 
                        error('Bioinfo:mafdr:LambdaMustBeNumericAndVector',...
                            'Lambda values must be numeric vector.');
                    end
                    
                    if any(pval <= 0 ) || any(pval >= 1)
                        error('Bioinfo:mafdr:badLambdaValues',...
                            'Lambda values must be greater than 0 and less than 1');
                    end
                    
                    lambda = pval;
                    if numel(lambda)> 1 && numel(lambda) <4
                        error('Bioinfo:mafdr:badLambdaRange',...
                            'The minimum number of values in the range is 4.')
                    end
                    
                    if numel(lambda)> 1
                        lambda = sort(lambda);
                        if ~all(diff(lambda))
                            error('Bioinfo:mafdr:badLambdaValues',...
                                'Two consecutive values in LAMBDA cannot be equal.')
                        end
                    end

                case 3 %lambda method
                    if ischar(pval)
                        okmethods = {'bootstrap', 'polynomial'};
                        nm = strmatch(lower(pval), okmethods);
                        if isempty(nm)
                            error('Bioinfo:mafdr:MethodNameNotValid',...
                                      'METHOD must be ''bootstrap'' or ''polynomial''.');
                        elseif length(nm) > 1
                            error('Bioinfo:mafdr:AmbiguousMethodName',...
                                      'Ambiguous METHOD name: %s.',pval);
                        else
                            bootflag = (nm==1);
                        end
                    else
                        error('Bioinfo:mafdr:MethodNameNotValid',...
                            'METHOD must be ''spline'' or ''bootstrap''.');
                    end    
                case 4 % showplot
                    showplotflag = bioinfoprivate.opttf(pval,okargs{k},mfilename);
            end
        end
    end
end

q=[];
pi0=[];
rs = [];
if bhflag
    fdr = bhfdr(p);
    
    if ~isempty(rownames)
       fdr = bioma.data.DataMatrix(fdr, rownames, {'FDR'});
    end
    
    if showplotflag
        if isempty(rownames)
            showBHplot(p,fdr)
        else
            showBHplot(p,fdr.(':')(':'))
        end
    end
else
    lambda = lambda(:);
    [fdr, q, pi0_all, pi0, cs, rs] = storeyFDR(p, lambda, bootflag);
    if ~isempty(rownames)
       fdr = bioma.data.DataMatrix(fdr, rownames, {'FDR'});
       q = bioma.data.DataMatrix(q, rownames, {'q-values'});
    end
    
    if showplotflag
        if isempty(rownames)
            showplots(lambda, p, q, pi0_all, pi0, cs)
        else
            showplots(lambda, p, q.(':')(':'), pi0_all, pi0, cs)
        end
    end
end

%--------------- Helper functions ----------------------%
function [fdr, q, pi0_all, pi0, cs, rs] = storeyFDR(p, lambda, bootflag)
% Compute pFDR and q-values using Storey and Tibshirani procedures
% estimate the proportion of genes that are truly null with a tuning
% parameter lambda.

m = numel(p);
pi0_all = estimatePI0(p, lambda);
cs = [];
rs = [];

% find the true pi0 from a range of lambda
if numel(lambda) > 1
    nan_idx = isnan(pi0_all);
    if bootflag
        pi0 = bootstrapchooser(pi0_all(~nan_idx), lambda(~nan_idx), p);
    else
        [pi0, cs, rs] = polychooser(pi0_all(~nan_idx), lambda(~nan_idx));
    end
else
    pi0 = pi0_all;
end

if pi0 <= 0
    error('Bioinfo:mafdr:BadEstimatedPI0Value',...
        'The estimated PI0 is less than or equals 0. Please check the p-values are valid or try a different lambda method.');
end

% Estimate the positive FDR for each gene
[~, idx] = sort(p);
v = m * p;
r = zeros(size(v));
r(idx) = 1:m;

fdr = pi0 * v./r;

% Calculate the q-value for each gene
qord = fdr(idx);

while 1
    i = find(diff(qord) < 0);
    if isempty(i)
        break;
    end
    qord(i) = qord(i+1);
end
q(idx) = qord;
q=q(:);

%------------------------------------------------------------
function [pi0,cs, rs] = polychooser(pi0_all, lambda)
% Choosing lambda for the estimate of pi0 using cubic polynomial of pi0 on
% lambda. Also returns the goodness of fit r^2, r-correlation coefficient.

[cs, s] = polyfit(lambda, pi0_all, 3);

% Compute pi0
d = diff(polyval(cs,lambda)) ./diff(lambda);
[mind, idx] = min(abs(d));
if mind < 0.005
    pi0 = polyval(cs, lambda(idx));
else
    pi0 = polyval(cs, max(lambda));
end

if pi0 > 1
     warning('Bioinfo:mafdr:PoorEstimatedPI0Value',...
        ['The estimated PI0 is greater than 1. Please check the p-values are valid or try a different lambda method',...
         '\nPI0 is set to 1.']);
end
pi0 = min(pi0, 1);

% compute r^2 - rs
sd = std(pi0_all);
n = numel(lambda) - 1;
rs = 1 - s.normr^2/(n*sd^2);

if rs < 0.90 
    warning('Bioinfo:mafdr:PoorCubicPolynomialFit',...
        'The goodness of fit r^2 is %0.4f. Please check the p-values are valid or try a different lambda method.', rs);
end


%--------------------------------------------------------
function pi0 = bootstrapchooser(pi0, lambda, p)
% Storey+Taylor+Siegmund(2004)
% Choosing lambda for the estimate of pi0 using bootstrap sampling on
% p-values. 
min_pi0 = min(pi0);

B = 100; % number of bootstrap replicates
m = numel(p);
n = numel(lambda);

% Get the indices of resampling, and extract these from the data
inds = unidrnd(m, m, B);
p_boot = p(inds);

mse = zeros(n,1);

% Bootstrap, and compute MSE
for i = 1:B
    pi0_boot = estimatePI0(p_boot(:,i), lambda);
    mse = mse + (pi0_boot - min_pi0).^2;
end

% Find the minimum MSE. 
minmse_idx = (mse == min(mse));
pi0 = min(pi0(minmse_idx));

if isempty(pi0)
    warning('Empty pi0\n');
    pi0 =0.95;
end
if  pi0 > 1 
     warning('Bioinfo:mafdr:PoortstimatedPI0Value',...
        ['The estimated PI0 is greater than 1. Please check the p-values are valid or try a different lambda method',...
         '\nPI0 is set to 0.95']);
     pi0 =0.95;
end

pi0=min(pi0,1);

%----------------------------------------------------------
function pi0 = estimatePI0(p, lambda)
% Storey+Tibshirani (2002)
% p - p-values
% lambda - tuning parameter

[F, p0] = ecdf(p);
pi0 = interp1q(p0, 1-F, lambda) ./ (1-lambda);

%------------------------------------------------------------
function showplots(lambda, p, q, pi0_all, pi0, cs)
if numel(lambda) ==1
    max_lambda = max(0.95,lambda);
    min_lambda = min(0.01,lambda);
    lambda_x = (min_lambda:0.02:max_lambda)';
    pi0_y = estimatePI0(p, lambda_x);
    lambda_pi0 = lambda;
else
    lambda_x = lambda;
    pi0_y = pi0_all;
    max_lambda = max(lambda);
    min_lambda = min(lambda);
    lambda_pi0 = max(lambda);
end

% add the smoother line
if isempty(cs)
    idx = isnan(pi0_y);
    cs = polyfit(lambda_x(~idx),pi0_y(~idx),3);
end

lambda_xx = linspace(min_lambda, max_lambda, 101);
pi0_yy = polyval(cs, lambda_xx);

miny = min(pi0_all) - 0.1;

% % xx = [lambda_pi0, lambda_pi0;lambda_pi0,1];
% % yy = [miny+0.01, pi0; pi0, pi0];
xx = [0, 1];
yy = [pi0, pi0];

subplot(2,1,1)
l1 = plot(lambda_x, pi0_y, 'r.'); %#ok
hold on;
l2 = plot(lambda_xx, pi0_yy, 'b-', 'LineWidth', 2);

l3 = plot(lambda_pi0, pi0, 'ko', 'LineWidth',2);
ylim([miny, 1]);

hl = legend([l2, l3], 'cubic polynomial fit', 'testing');
legend_str = {'cubic polynomial fit', '$\hat\pi_0$'};
set(hl, 'interpreter', 'latex','string', legend_str);

plot(xx(:), yy(:), 'k:');
hx = xlabel('');
hy = ylabel('');
ht = title('');
set([hx hy ht], 'interpreter', 'latex', 'FontSize', 12)
set(hx,'string', '$\lambda$');
set(hy, 'string', '$\hat\pi_0(\lambda)$')
set(ht, 'string', ['$\hat\pi_0$=', sprintf('%.4f', pi0)]) 
hold off
set(gca,'Tag','PI0vslambdaAxes')
subplot(2,1,2)
[p, idx]= sort(p);
q=q(idx);
plot(p,q);
xlabel('p-value','FontSize', 12 )
ylabel('q-value', 'FontSize', 12)
set(gca,'Tag','pvsqAxes')

%------------
function fdr = bhfdr(p)
% Compute the fdr using BH Linear step-up procedure

m = numel(p);
[p_ord, idx] = sort(p);

% Find cutoffs starts from end
fdr_ord = zeros(m,1, class(p));
fdr_ord(m) = p_ord(m);

for k = m-1:-1:1
    fdr_ord(k) = p_ord(k)*m/k;
    if fdr_ord(k) > fdr_ord(k+1)
        fdr_ord(k) = fdr_ord(k+1);
    end
end
fdr(idx) = fdr_ord;
fdr= fdr(:);

%------------------------------------------------------------
function showBHplot(p,fdr)
[p, idx]= sort(p);
fdr = fdr(idx);
plot(p, fdr);
xlabel('p-value')
ylabel('FDR adjusted p-value')












    


