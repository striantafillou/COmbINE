function [Sta, Cri, p_val, Cri_appr, p_appr] = UInd_test(x, y, alpha, width)
% To test if x and y are unconditionally independent.
% INPUT:
%   The number of rows of x and y is the sample size.
%   alpha is the significance level (we suggest 1%).
%   width contains the kernel width.
% Output:
%   Cri: the critical point at the p-value equal to alpha obtained by bootstrapping.
%   Sta: the statistic Tr(K_{\ddot{X}|Z} * K_{Y|Z}).
%   p_val: the p value obtained by bootstrapping.
%   Cri_appr: the critical value obtained by Gamma approximation.
%   p_apppr: the p-value obtained by Gamma approximation.
% If Sta > Cri, the null hypothesis (x is independent from y) is rejected.
% Copyright (c) 2010-2011  Kun Zhang, Jonas Peters.
% All rights reserved.  See the file COPYING for license terms.

% Controlling parameters
Approximate = 1;
Bootstrap = 0;

T = length(y); % the sample size
% Num_eig = floor(T/4); % how many eigenvalues are to be calculated?
Num_eig = floor(T/2);
T_BS = 5000;
lambda = 1E-3; % the regularization paramter  %%%%Problem
Thresh = 1E-6;
% normalize the data
x = x - mean(x); x = x/std(x);
y = y - mean(y); y = y/std(y);
Cri = []; Sta = []; p_val = []; Cri_appr = []; p_appr = [];

if width ==0
    if T < 200
        width = 0.8;
    elseif T < 1200
        width = 0.5;
    else
        width = 0.3;
    end
%    width = sqrt(2)*medbw(x, 1000); %use median heuristic for the band width.
end
theta = 1/(width^2); % I use this parameter to construct kernel matices. Watch out!! width = sqrt(2) sigma  AND theta= 1/(2*sigma^2)

H =  eye(T) - ones(T,T)/T; % for centering of the data in feature space
% Kx = kernel([x z], [x z], [theta,1]); Kx = H * Kx * H;
% Kx = kernel([x z/2], [x z/2], [theta,1]); Kx = H * Kx * H;
% Ky = kernel([y z], [y z], [theta,1]); %Ky = Ky * H;
Kx = kernel([x], [x], [theta,1]); Kx = H * Kx * H; %%%%Problem
Ky = kernel([y], [y], [theta,1]); Ky = H * Ky * H;  %%%%Problem
Sta = trace(Kx * Ky);


% calculate the eigenvalues
% Due to numerical issues, Kx and Ky may not be symmetric:
[eig_Kx, eivx] = eigdec((Kx+Kx')/2,Num_eig);
[eig_Ky, eivy] = eigdec((Ky+Ky')/2,Num_eig);
% calculate Cri...
% first calculate the product of the eigenvalues
eig_prod = stack( (eig_Kx * ones(1,Num_eig)) .* (ones(Num_eig,1) * eig_Ky'));
II = find(eig_prod > max(eig_prod) * Thresh);
eig_prod = eig_prod(II); %%% new method

if Bootstrap
    % use mixture of F distributions to generate the Null dstr
    if length(eig_prod) * T < 1E6
        %     f_rand1 = frnd(1,T-2-df, length(eig_prod),T_BS);
        %     Null_dstr = eig_prod'/(T-1) * f_rand1;
        f_rand1 = chi2rnd(1,length(eig_prod),T_BS);        
        Null_dstr = eig_prod'/T * f_rand1; %%%%Problem        
    else
        % iteratively calcuate the null dstr to save memory
        Null_dstr = zeros(1,T_BS);
        Length = max(floor(1E6/T),100);
        Itmax = floor(length(eig_prod)/Length);
        for iter = 1:Itmax
            %         f_rand1 = frnd(1,T-2-df, Length,T_BS);
            %         Null_dstr = Null_dstr + eig_prod((iter-1)*Length+1:iter*Length)'/(T-1) * f_rand1;
            f_rand1 = chi2rnd(1,Length,T_BS);
            Null_dstr = Null_dstr + eig_prod((iter-1)*Length+1:iter*Length)'/T * f_rand1;
            
        end
        Null_dstr = Null_dstr + eig_prod(Itmax*Length+1:length(eig_prod))'/T *... %%%%Problem
            chi2rnd(1, length(eig_prod) - Itmax*Length,T_BS);
        %         frnd(1,T-2-df, length(eig_prod) - Itmax*Length,T_BS);
    end
    %         % use chi2 to generate the Null dstr:
    %         f_rand2 = chi2rnd(1, length(eig_prod),T_BS);
    %         Null_dstr = eig_prod'/(TT(epoch)-1) * f_rand2;
    sort_Null_dstr = sort(Null_dstr);
    Cri = sort_Null_dstr(ceil((1-alpha)*T_BS));
    p_val = sum(Null_dstr>Sta)/T_BS;
end

Cri_appr = -1;
p_appr = -1;
if Approximate
    mean_appr = trace(Kx) * trace(Ky) /T;
    var_appr = 2* trace(Kx*Kx) * trace(Ky*Ky)/T^2;
    k_appr = mean_appr^2/var_appr;
    theta_appr = var_appr/mean_appr;
    Cri_appr = gaminv(1-alpha, k_appr, theta_appr);
    p_appr = 1-gamcdf(Sta, k_appr, theta_appr);
end
