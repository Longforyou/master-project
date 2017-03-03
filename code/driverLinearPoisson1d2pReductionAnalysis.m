% driverLinearPoisson1d2pReductionAnalysis Some post-processing for the
% reduction modeling applied to one-dimensional linear Poisson equation 
% $-u''(x) = f(x,\mu)$ on $[a,b]$ depending on the real parameters $\mu$
% and $\nu$, with the latter incorporated in the boundary conditions assigned
% to the right extreme of the intervale.
% The reduced basis has been obtained through, e.g., SVD and the reduced solution
% has been computed through the direct method, i.e. solving the reduced model.
% Note: for the moment (01-03-2017) we just consider a uniform sampling, i.e. 
% the values for $\mu$ and $\nu$ used to compute the snapshots are placed in 
% the nodes of a Cartesian grid on $[\mu_1,\mu_2] \times [\nu_1,\nu_2]$ with 
% uniform spacing along both directions.

clc
clear variables
clear variables -global
close all

%
% User-defined settings:
% a         left boundary of the domain
% b         right boundary of the domain
% f         force field $f = f(t,\mu)$ as handle function
% mu1       lower bound for $\mu$
% mu2       upper bound for $\mu$
% nu1       lower bound for $\nu$
% nu2       upper bound for $\nu$
% BCLt      kind of left boundary condition
%           - 'D': Dirichlet, 
%           - 'N': Neumann, 
%           - 'P': periodic
% BCLv      value of left boundary condition
% BCRt      kind of right boundary condition
%           - 'D': Dirichlet, 
%           - 'N': Neumann, 
%           - 'P': periodic
% solver    solver
%           - 'FEP1': linear finite elements
%           - 'FEP2': quadratic finite elements
% reducer   method to compute the reduced basis
%           - 'SVD': Single Value Decomposition, i.e. Proper
%					 Orthogonal Decomposition (POD)
% root      path to folder where storing the output dataset

a = -1;  b = 1;  
%f = @(t,mu) gaussian(t,mu,0.2);  mu1 = -1;  mu2 = 1;  nu1 = 0;  nu2 = 1;  suffix = '';
f = @(t,mu) -(t < mu) + 2*(t >= mu);  mu1 = -1;  mu2 = 1;  nu1 = 0;  nu2 = 1;  suffix = '_ter';
BCLt = 'D';  BCLv = 0;
BCRt = 'D';
solver = 'FEP1';
reducer = 'SVD';
root = '../datasets';

%% Plot full and reduced solution for three values of $\mu$ and $\nu$. 
% This is useful to have some insights into the dependency of
% the solution on the parameters and which is best between uniform and random
% sampling method.

%
% User defined settings:
% K         number of grid points
% Nmu	    number of sampled values for $\mu$
% Nnu		number of sampled values for $\nu$
% L         rank of reduced basis
% Nte       number of testing samples

K = 100;  Nmu = 50;  Nnu = 1;  L = 3;  Nte = 50;

%
% Run
%

% Set handle to solver
if strcmp(solver,'FEP1')
    solverFcn = @LinearPoisson1dFEP1;
elseif strcmp(solver,'FEP2')
    solverFcn = @LinearPoisson1dFEP2;
end

% Get total number of snapshots
N = Nmu*Nnu;

% Select three values for $\mu$ and $\nu$
%mu = mu1 + (mu2 - mu1) * rand(3,1);
%nu = nu1 + (nu2 - nu1) * rand(3,1);
mu = [-0.455759 -0.455759 -0.455759];
nu = [0.03478 0.5 0.953269];


% Evaluate forcing term for the just set values for $\mu$
g = cell(3,1);
for i = 1:3
    g{i} = @(t) f(t,mu(i));
end

% Load data and get full and reduced solutions for uniform sampling
filename = sprintf(['%s/LinearPoisson1d2p_%s_%sunif_a%2.2f_b%2.2f_%s%2.2f_%s_' ...
    'mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
    root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, nu1, nu2, K, ...
    Nmu, Nnu, N, L, Nte, suffix);
load(filename);
[x, u1, alpha1_unif] = solverFcn(a, b, K, g{1}, BCLt, BCLv, BCRt, nu(1), UL);
ur1_unif = UL * alpha1_unif;
[x, u2, alpha2_unif] = solverFcn(a, b, K, g{2}, BCLt, BCLv, BCRt, nu(2), UL);
ur2_unif = UL * alpha2_unif;
[x, u3, alpha3_unif] = solverFcn(a, b, K, g{3}, BCLt, BCLv, BCRt, nu(3), UL);
ur3_unif = UL * alpha3_unif;

%{
% Load data and get reduced solutions for random sampling
filename = sprintf(['%s/LinearPoisson1d2p_%s_%srand_a%2.2f_b%2.2f_%s%2.2f_%s_' ...
    'mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_Nmu%i_Nnu%i_N%i_L%i_Nte%i.mat'], ...
    root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, nu1, nu2, K, ...
    N, N, N, L, Nte);
load(filename);
[x, alpha1_rand] = solverFcn(a, b, K, g{1}, BCLt, BCLv, BCRt, nu(1), UL);
ur1_rand = UL * alpha1_rand;
[x, alpha2_rand] = solverFcn(a, b, K, g{2}, BCLt, BCLv, BCRt, nu(2), UL);
ur2_rand = UL * alpha2_rand;
[x, alpha3_rand] = solverFcn(a, b, K, g{3}, BCLt, BCLv, BCRt, nu(3), UL);
ur3_rand = UL * alpha3_rand;

%
% Plot distribution of sampling values for $\mu$ and $\nu$ when drawn from 
% a uniform distribution
%

% Open a new window
figure(1);

% Plot distribution for $\mu$
bin = 20;
subplot(1,2,1);
hold off
histogram(mu_tr,bin);
hold on
plot([mu1 mu2], Nmu/bin * [1 1], 'g')
plot(mu, zeros(size(mu)), 'rx', 'Markersize', 10);
title('Distribution of $\mu$')
xlabel('$\mu$')
legend('Random sampling', 'Uniform sampling', 'Test values', 'location', 'best')
grid on
xlim([mu1 mu2])

% Plot distribution for $\nu$
bin = 20;
subplot(1,2,2);
hold off
histogram(nu_tr,bin);
hold on
plot([nu1 nu2], Nnu/bin * [1 1], 'g')
plot(nu, zeros(size(nu)), 'rx', 'Markersize', 10);
title('Distribution of $\nu$')
xlabel('$\nu$')
legend('Random sampling', 'Uniform sampling', 'Test values', 'location', 'best')
grid on
xlim([nu1 nu2])
%}

%
% Compare solutions for three values of $\mu$
%

% Open a new window
figure(2);
hold off

% Plot and set the legend
plot(x(1:1:end), u1(1:1:end), 'b')
hold on
plot(x(1:1:end), ur1_unif(1:1:end), 'b--', 'Linewidth', 2)
%plot(x(1:1:end), ur1_rand(1:1:end), 'b:', 'Linewidth', 2)
plot(x(1:1:end), u2(1:1:end), 'r')
plot(x(1:1:end), ur2_unif(1:1:end), 'r--', 'Linewidth', 2)
%plot(x(1:1:end), ur2_rand(1:1:end), 'r:', 'Linewidth', 2)
plot(x(1:1:end), u3(1:1:end), 'g')
plot(x(1:1:end), ur3_unif(1:1:end), 'g--', 'Linewidth', 2)
%plot(x(1:1:end), ur3_rand(1:1:end), 'g:', 'Linewidth', 2)

% Define plot settings
str_leg = sprintf('Full and reduced solution to Poisson equation ($k = %i$, $n = %i$, $l = %i$)', ...
    K, N, L);
title(str_leg)
xlabel('$x$')
ylabel('$u$')
legend(sprintf('$\\mu = %f$, $\\nu = %f$, full', mu(1), nu(1)), ...
    sprintf('$\\mu = %f$, $\\nu = %f$, reduced (uniform)', mu(1), nu(1)), ...
    ... %sprintf('$\\mu = %f$, $\\nu = %f$, reduced (random)', mu(1), nu(1)), ...
    sprintf('$\\mu = %f$, $\\nu = %f$, full', mu(2), nu(2)), ...
    sprintf('$\\mu = %f$, $\\nu = %f$, reduced (uniform)', mu(2), nu(2)), ...
    ... %sprintf('$\\mu = %f$, $\\nu = %f$, reduced (random)', mu(2), nu(2)), ...
    sprintf('$\\mu = %f$, $\\nu = %f$, full', mu(3), nu(3)), ...
    sprintf('$\\mu = %f$, $\\nu = %f$, reduced (uniform)', mu(3), nu(3)), ...
    ... %sprintf('$\\mu = %f$, $\\nu = %f$, reduced (random)', mu(3), nu(3)), ...
    'location', 'best')
grid on

%% A complete sensitivity analysis on the sampling method, the number of
% snapshots and the rank of the reduced basis: plot the maximum and average 
% error versus number of basis functions for different number of snapshots.
% In particular, in each plot we fix the number of samples for $\nu$ and we
% compare the error curves for different numbers of sampled values of $\mu$

%
% User defined settings:
% K     number of grid points
% Nmu   number of sampled values for $\nu$ (no more than four values)
% Nnu   number of sampled values for $\mu$
% L     rank of reduced basis

K = 100;  Nmu = [5 10 20 50];  Nnu = [5 10 50];  L = 1:25;  Nte = 50;

%
% Run
% 

for k = 1:length(Nnu)
    % Get total number of samples
    N = Nmu * Nnu(k);
    
    % Get error accumulated error for all values of L and for even distribution 
    % of snapshot values of $\mu$
    err_max_unif = zeros(length(L),length(Nmu));
    err_avg_unif = zeros(length(L),length(Nmu));
    for i = 1:length(L)
        for j = 1:length(Nmu)
            filename = sprintf(['%s/LinearPoisson1d2p_%s_%sunif_a%2.2f_b%2.2f_' ...
                '%s%2.2f_%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_' ...
                'Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
                root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, ...
                nu1, nu2, K, Nmu(j), Nnu(k), N(j), L(i), Nte, suffix);
            load(filename);
            err_max_unif(i,j) = max(err_svd_abs);
            err_avg_unif(i,j) = sum(err_svd_abs)/Nte;
        end
    end
    
    %{
    % Get error accumulated error for all values of L and for random distribution 
    % of shapshot values for $\mu$
    err_rand = zeros(length(L),length(Nmu));
    for i = 1:length(L)
        for j = 1:length(Nmu)
            filename = sprintf(['%s/LinearPoisson1d2p_%s_%srand_a%2.2f_b%2.2f_' ...
                '%s%2.2f_%s_mu1%2.2f_mu2%2.2f_mu1%2.2f_mu2%2.2f_K%i_' ...
                'Nmu%i_Nnu%i_N%i_L%i_Nte%i.mat'], ...
                root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, ...
                nu1, nu2, K, N(j), N(j), N(j), L(i), Nte);
            load(filename);
            err_rand(i,j) = sum(err_svd_abs);
        end
    end
    %}
    
    %
    % Maximum error
    %
    
    % Open a new window
    figure(2+2*k-1);
    hold off

    % Plot data and dynamically update legend
    marker_unif = {'bo-', 'rs-', 'g^-', 'mv-'};
    %marker_rand = {'bo:', 'rs:', 'g^:', 'mv:'};
    str_leg = 'legend(''location'', ''best''';
    for j = 1:length(Nmu)
        semilogy(L', err_max_unif(:,j), marker_unif{j});
        hold on
        %semilogy(L', err_rand(:,j), marker_rand{j});
        str_unif = sprintf('''$n_{\\mu} = %i$, uniform''', Nmu(j));
        %str_rand = sprintf('''$n_{\\mu} = %i$, random''', Nmu(j));
        str_leg = strcat(str_leg, ', ', str_unif);
        %str_leg = sprintf('%s, %s, %s', str_leg, str_unif, str_rand);
    end
    str_leg = sprintf('%s)', str_leg);
    eval(str_leg)

    % Define plot settings
    str_leg = sprintf('Maximum error $\\epsilon_{max}$ ($k = %i$, $n_{\\nu} = %i$, $n_{te} = %i$)', ...
        K, Nnu(k), Nte);
    title(str_leg)
    xlabel('$l$')
    ylabel('$\epsilon_{max}$')
    grid on    
    xlim([min(L)-1 max(L)+1])
    
    %
    % Average error
    %
    
    % Open a new window
    figure(2+2*k);
    hold off

    % Plot data and dynamically update legend
    marker_unif = {'bo-', 'rs-', 'g^-', 'mv-'};
    %marker_rand = {'bo:', 'rs:', 'g^:', 'mv:'};
    str_leg = 'legend(''location'', ''best''';
    for j = 1:length(Nmu)
        semilogy(L', err_avg_unif(:,j), marker_unif{j});
        hold on
        %semilogy(L', err_rand(:,j), marker_rand{j});
        str_unif = sprintf('''$n_{\\mu} = %i$, uniform''', Nmu(j));
        %str_rand = sprintf('''$n_{\\mu} = %i$, random''', Nmu(j));
        str_leg = strcat(str_leg, ', ', str_unif);
        %str_leg = sprintf('%s, %s, %s', str_leg, str_unif, str_rand);
    end
    str_leg = sprintf('%s)', str_leg);
    eval(str_leg)

    % Define plot settings
    str_leg = sprintf('Average error $\\epsilon_{avg}$ ($k = %i$, $n_{\\nu} = %i$, $n_{te} = %i$)', ...
        K, Nnu(k), Nte);
    title(str_leg)
    xlabel('$l$')
    ylabel('$\epsilon_{avg}$')
    grid on    
    xlim([min(L)-1 max(L)+1])
end

%% A complete sensitivity analysis on the sampling method, the number of
% snapshots and the rank of the reduced basis: plot the maximum and average
% error versus number of basis functions for different number of snapshots.
% In particular, in each plot we fix the number of samples for $\mu$ and we
% compare the error curves for different numbers of sampled values of $\nu$

%
% User defined settings:
% K     number of grid points
% Nmu   number of sampled values for $\mu$ 
% Nnu   number of sampled values for $\nu$ (no more than four values)
% L     rank of reduced basis

K = 100;  Nmu = [10 25 50];  Nnu = [5 10 25 50];  L = 1:25;  Nte = 50;

%
% Run
% 

for k = 1:length(Nmu)
    % Get total number of samples
    N = Nnu * Nmu(k);
    
    % Get error accumulated error for all values of L and for even distribution 
    % of snapshot values of $\mu$
    err_max_unif = zeros(length(L),length(Nnu));
    err_avg_unif = zeros(length(L),length(Nnu));
    for i = 1:length(L)
        for j = 1:length(Nnu)
            filename = sprintf(['%s/LinearPoisson1d2p_%s_%sunif_a%2.2f_b%2.2f_' ...
                '%s%2.2f_%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_' ...
                'Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
                root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, ...
                nu1, nu2, K, Nmu(k), Nnu(j), N(j), L(i), Nte, suffix);
            load(filename);
            err_max_unif(i,j) = max(err_svd_abs);
            err_avg_unif(i,j) = sum(err_svd_abs)/Nte;
        end
    end
    
    %{
    % Get error accumulated error for all values of L and for random distribution 
    % of shapshot values for $\mu$
    err_rand = zeros(length(L),length(Nnu));
    for i = 1:length(L)
        for j = 1:length(Nnu)
            filename = sprintf(['%s/LinearPoisson1d2p_%s_%srand_a%2.2f_b%2.2f_' ...
                '%s%2.2f_%s_mu1%2.2f_mu2%2.2f_mu1%2.2f_mu2%2.2f_K%i_' ...
                'Nmu%i_Nnu%i_N%i_L%i_Nte%i.mat'], ...
                root, solver, reducer, a, b, BCLt, BCLv, BCRt, mu1, mu2, ...
                nu1, nu2, K, N(j), N(j), N(j), L(i), Nte);
            load(filename);
            err_rand(i,j) = sum(err_svd_abs);
        end
    end
    %}
    
    %
    % Maximum error
    %
    
    % Open a new window
    figure(8+2*k-1);
    hold off

    % Plot data and dynamically update legend
    marker_unif = {'bo-', 'rs-', 'g^-', 'mv-'};
    %marker_rand = {'bo:', 'rs:', 'g^:', 'mv:'};
    str_leg = 'legend(''location'', ''best''';
    for j = 1:length(Nmu)
        semilogy(L', err_max_unif(:,j), marker_unif{j});
        hold on
        %semilogy(L', err_rand(:,j), marker_rand{j});
        str_unif = sprintf('''$n_{\\nu} = %i$, uniform''', Nnu(j));
        %str_rand = sprintf('''$n_{\\nu} = %i$, random''', Nnu(j));
        str_leg = strcat(str_leg, ', ', str_unif);
        %str_leg = sprintf('%s, %s, %s', str_leg, str_unif, str_rand);
    end
    str_leg = sprintf('%s)', str_leg);
    eval(str_leg)

    % Define plot settings
    str_leg = sprintf('Maximum error $\\epsilon_{max}$ ($k = %i$, $n_{\\mu} = %i$, $n_{te} = %i$)', ...
        K, Nmu(k), Nte);
    title(str_leg)
    xlabel('$l$')
    ylabel('$\epsilon_{max}$')
    grid on    
    xlim([min(L)-1 max(L)+1])
    
    %
    % Average error
    %
    
    % Open a new window
    figure(8+2*k);
    hold off

    % Plot data and dynamically update legend
    marker_unif = {'bo-', 'rs-', 'g^-', 'mv-'};
    %marker_rand = {'bo:', 'rs:', 'g^:', 'mv:'};
    str_leg = 'legend(''location'', ''best''';
    for j = 1:length(Nmu)
        semilogy(L', err_avg_unif(:,j), marker_unif{j});
        hold on
        %semilogy(L', err_rand(:,j), marker_rand{j});
        str_unif = sprintf('''$n_{\\nu} = %i$, uniform''', Nnu(j));
        %str_rand = sprintf('''$n_{\\nu} = %i$, random''', Nnu(j));
        str_leg = strcat(str_leg, ', ', str_unif);
        %str_leg = sprintf('%s, %s, %s', str_leg, str_unif, str_rand);
    end
    str_leg = sprintf('%s)', str_leg);
    eval(str_leg)

    % Define plot settings
    str_leg = sprintf('Average error $\\epsilon_{avg}$ ($k = %i$, $n_{\\mu} = %i$, $n_{te} = %i$)', ...
        K, Nmu(k), Nte);
    title(str_leg)
    xlabel('$l$')
    ylabel('$\epsilon_{avg}$')
    grid on    
    xlim([min(L)-1 max(L)+1])
end

%% Plot maximum and average error versus number of sampled values for $\mu$
% Fix both the number of samples for $\nu$ and the the rank of the basis

%
% User defined settings:
% K         number of grid points
% Nmu       number of sampled values for $\mu$ (row vector)
% L         rank of reduced basis (row vector, no more than four values)
% Nte       number of testing samples

K = 100;  N = [10 25 50 75 100];  L = [1 3 6 8];  Nte = 50;

%
% Run
%

% Get accumulated error for any combination of N and L
err_unif = zeros(length(L),length(N));
err_rand = zeros(length(L),length(N));
for i = 1:length(L)
    for j = 1:length(N)
        % Uniform sampling
        filename = sprintf('%s/LinearPoisson1d1p_%s_%sunif_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N(j), L(i), Nte);
        load(filename);
        err_unif(i,j) = sum(err_svd_abs);
        
        % Random sampling
        filename = sprintf('%s/LinearPoisson1d1p_%s_%srand_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N(j), L(i), Nte);
        load(filename);
        err_rand(i,j) = sum(err_svd_abs);
    end
end

% Open a new window
figure(3);
hold off

% Plot and dynamically update the legend
marker_unif = {'bo-', 'rs-', 'g^-', 'mv-'};
marker_rand = {'bo--', 'rs--', 'g^--', 'mv--'};
str_leg = sprintf('legend(''location'', ''best''');
for i = 1:length(L)
    semilogy(N, err_unif(i,:), marker_unif{i});
    hold on
    semilogy(N, err_rand(i,:), marker_rand{i});
    str_unif = sprintf('''L = %i, uniform''', L(i));
    str_rand = sprintf('''L = %i, random''', L(i));
    str_leg = strcat(str_leg, ', ', str_unif, ', ', str_rand);
end
str_leg = strcat(str_leg, ')');

% Define plot settings
str = sprintf('Accumulated error $\\epsilon$ ($k = %i$, $n_{te} = %i$)', ...
    K, Nte);
title(str)
xlabel('$n$')
ylabel('$\epsilon$')
grid on
eval(str_leg);



%% Fix the sampling method and plot full and reduced solution for three 
% testing values of $\mu$ (This is actually really similar to the first
% setcion, yet here only one sampling method is considered)

%
% User defined settings:
% K         number of grid points
% N         number of shapshots
% L         rank of reduced basis
% Nte       number of testing samples
% sampler   how the shapshot values for $\mu$ should be sampled:
%           - 'unif': uniformly distributed on $[\mu_1,\mu_2]$
%           - 'rand': drawn from a uniform random distribution on $[\mu_1,\mu_2]$

K = 100;  N = 10;  L = 2;  Nte = 50;
sampler = 'rand';

%
% Run
%

% Load data
filename = sprintf('%s/LinearPoisson1d1p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N, L, Nte);
load(filename);

% Select the three solutions to plot
idx = randi(Nte,3,1);

% Open a new window
figure(5);
hold off

% Plot and set the legend
plot(x(1:1:end), u_te(1:1:end,idx(1)), 'b')
hold on
plot(x(1:1:end), ur_te(1:1:end,idx(1)), 'b:', 'Linewidth', 2)
plot(x(1:1:end), u_te(1:1:end,idx(2)), 'r')
plot(x(1:1:end), ur_te(1:1:end,idx(2)), 'r:', 'Linewidth', 2)
plot(x(1:1:end), u_te(1:1:end,idx(3)), 'g')
plot(x(1:1:end), ur_te(1:1:end,idx(3)), 'g:', 'Linewidth', 2)

% Define plot settings
str_leg = sprintf('Full and reduced solution to Poisson equation ($k = %i$, $n = %i$, $l = %i$)', ...
    K, N, L);
title(str_leg)
xlabel('$x$')
ylabel('$u$')
legend(sprintf('$\\mu = %f$, full', mu_te(idx(1))), sprintf('$\\mu = %f$, reduced', mu_te(idx(1))), ...
    sprintf('$\\mu = %f$, full', mu_te(idx(2))), sprintf('$\\mu = %f$, reduced', mu_te(idx(2))), ...
    sprintf('$\\mu = %f$, full', mu_te(idx(3))), sprintf('$\\mu = %f$, reduced', mu_te(idx(3))), ...
    'location', 'best')
grid on

%% Fix the sampling method and the number of snapshots and perform a sensitivity 
% analysis on the pointwise error as the rank of the reduced basis varies

%
% User defined settings:
% K         number of grid points
% N         number of shapshots
% L         rank of reduced basis
% sampler   how the shapshot values for $\mu$ should be selected:
%           - 'unif': uniformly distributed on $[\mu_1,\mu_2]$
%           - 'rand': drawn from a uniform random distribution on $[\mu_1,\mu_2]$

K = 100;  N = 10;  L = [3 5 8 10];  Nte = 50;
sampler = 'unif';

%
% Plot a specific solution
%

% Select the solution to plot
idx = randi(Nte,1);

% Open a new plot window
figure(6);
hold off

% Load data, plot and update legend
str_leg = 'legend(''location'', ''best''';
for i = 1:length(L)
    filename = sprintf('%s/LinearPoisson1d1p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N, L(i), Nte);
    load(filename);
    plot(x(1:1:end), ur_te(1:1:end,idx));
    hold on
    stri = sprintf('''$l = %i$''', L(i));
    str_leg = sprintf('%s, %s', str_leg, stri);
end
plot(x(1:1:end), u_te(1:1:end,idx));
str_leg = sprintf('%s, ''Full'')', str_leg);
eval(str_leg)

% Define plot settings
str_leg = sprintf('Full and reduced solution to Poisson equation ($k = %i$, $n = %i$, $\\mu = %f$)', ...
    K, N, mu_te(idx));
title(str_leg)
xlabel('$x$')
ylabel('$u$')
grid on


%
% Plot error versus $\mu$
%

% Open a new plot window
figure(7);
hold off

% Load data, plot and update legend
marker = {'o-', 's-', '^-', 'x-'};
str_leg = 'legend(''location'', ''best''';
for i = 1:3 %i = 1:length(L)
    filename = sprintf('%s/LinearPoisson1d1p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N, L(i), Nte);
    load(filename);
    [mu_te,I] = sort(mu_te);
    err_svd_rel = err_svd_rel(I);
    plot(mu_te, err_svd_rel, marker{mod(i,4)+1});
    hold on
    stri = sprintf('''$l = %i$''', L(i));
    str_leg = sprintf('%s, %s', str_leg, stri);
end
str_leg = sprintf('%s)', str_leg);
eval(str_leg)

% Define plot settings
str_leg = sprintf('Relative error between full and reduced solution to Poisson equation ($k = %i$, $n = %i$)', ...
    K, N);
title(str_leg)
xlabel('$\mu$')
ylabel('$\left\Vert u - u^l \right\Vert / \left\Vert u \right\Vert$')
grid on

%% Fix the sampling method and the rank of the reduced basis and perform a 
% sensitivity analysis on the pointwise error as the number of snapshots varies

%
% User defined settings:
% K         number of grid points
% N         number of shapshots
% L         rank of reduced basis
% Nte       number of testing samples
% sampler   how the shapshot values for $\mu$ should be selected:
%           - 'unif': uniformly distributed on $[\mu_1,\mu_2]$
%           - 'rand': drawn from a uniform random distribution on $[\mu_1,\mu_2]$

K = 100;  N = [10 25 50 100];  L = 8;  Nte = 50;
sampler = 'rand';

%
% Plot a specific solution
%

% Select the solution to plot
idx = randi(J,1);

% Open a new plot window
figure(8);
hold off

% Load data, plot and update legend
str_leg = 'legend(''location'', ''best''';
for i = 1:length(N)
    filename = sprintf('%s/LinearPoisson1d1p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N(i), L, Nte);
    load(filename);
    plot(x(1:1:end), ur_te(1:1:end,idx));
    hold on
    stri = sprintf('''$n = %i$''', N(i));
    str_leg = sprintf('%s, %s', str_leg, stri);
end
plot(x(1:1:end), u_te(1:1:end,idx));
str_leg = sprintf('%s, ''Full'')', str_leg);
eval(str_leg)

% Define plot settings
str_leg = sprintf('Full and reduced solution to Poisson equation ($k = %i$, $l = %i$, $\\mu = %f$)', ...
    K, L, mu_te(idx));
title(str_leg)
xlabel('$x$')
ylabel('$u$')
grid on

%
% Plot error versus $\mu$
%

% Open a new plot window
figure(9);
hold off

% Load data, plot and update legend
marker = {'o-', 's-', '^-', 'x-'};
str_leg = 'legend(''location'', ''best''';
for i = 1:length(N)
    filename = sprintf('%s/LinearPoisson1d1p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_%s%2.2f_mu1%2.2f_mu2%2.2f_K%i_N%i_L%i_Nte%i.mat', ...
            root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, BCRv, mu1, mu2, K, N(i), L, Nte);
    load(filename);
    [mu_te,I] = sort(mu_te);
    err_svd_rel = err_svd_rel(I);
    plot(mu_te, err_svd_rel, marker{mod(i,4)+1});
    hold on
    stri = sprintf('''$n = %i$''', N(i));
    str_leg = sprintf('%s, %s', str_leg, stri);
end
str_leg = sprintf('%s)', str_leg);
eval(str_leg)

% Define plot settings
str_leg = sprintf('Relative error between full and reduced solution to Poisson equation ($k = %i$, $l = %i$)', ...
    K, L);
title(str_leg)
xlabel('$\mu$')
ylabel('$\left\Vert u - u^l \right\Vert / \left\Vert u \right\Vert$')
grid on

%% Plot basis functions

%
% User defined settings:
% K         number of grid points
% Nmu       number of sampled values for $\mu$
% Nnu       number of sampled values for $\nu$
% L         rank of reduced basis
% Nte       number of testing samples
% sampler   how the shapshot values for $\mu$ should be selected:
%           - 'unif': uniformly distributed on $[\mu_1,\mu_2]$
%           - 'rand': drawn from a uniform random distribution on $[\mu_1,\mu_2]$

K = 100;  Nmu = 20;  Nnu = 10;  L = 5;  Nte = 50;
sampler = 'unif';

%
% Run
%  

% Load data
N = Nmu*Nnu;
filename = sprintf(['%s/LinearPoisson1d2p_%s_%s%s_a%2.2f_b%2.2f_%s%2.2f_' ...
    '%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
    root, solver, reducer, sampler, a, b, BCLt, BCLv, BCRt, mu1, mu2, ...
    nu1, nu2, K, Nmu, Nnu, N, L, Nte, suffix);
load(filename);

% Plot basis functions
for l = 1:L
    figure(9+l);
    plot(x,UL(:,l),'b')
    title('Basis function')
    xlabel('$x$')
    str = sprintf('$\\psi^%i$', l);
    ylabel(str);
    grid on
end

