% driverNonLinearPoisson1d2pNeuralNetwork Consider the one-dimensional 
% nonlinear equation $-(v(u) u'(x))' = f(x,\mu,\nu)$ in the unknown 
% $x \in [a,b]$, where $\mu$ and $\nu$ are real parameters. Note that these 
% parameters may enter also the boundary conditions. 
% Given a reduced basis $U$ of rank L and some training reduced solutions, 
% we train a neural network to approximate the nonlinear map
% $[\mu,\nu] \mapsto \boldsymbol{\alpha}$, where $\boldsymbol{\alpha}$ are 
% the coefficients of the expansion of the reduced solution in terms of the
% reduced basis vectors.

clc
clear variables 
clear variables -global
close all

%
% User-defined settings:
% a             left boundary of the domain
% b             right boundary of the domain
% K             number of grid points
% v             viscosity $v = v(u)$ as handle function
% dv            derivative of the viscosity as handle function
% f             force field $f = f(t,\mu,\nu)$ as handle function
% mu1           lower bound for $\mu$
% mu2           upper bound for $\mu$
% nu1           lower bound for $\nu$
% nu2           upper bound for $\nu$
% suffix        suffix for data file name
% BCLt          kind of left boundary condition
%               - 'D': Dirichlet, 
%               - 'N': Neumann, 
%               - 'P': periodic
% BCLv          left boundary condition as handle function in mu and nu
% BCRt          kind of right boundary condition
%               - 'D': Dirichlet, 
%               - 'N': Neumann, 
%               - 'P': periodic
% BCRv          right boundary condition as handle function in mu and nu
% solver        solver
%               - 'FEP1': linear finite elements; the resulting nonlinear
%                         system is solved via the Matlab built-in fucntion fsolve
%               - 'FEP1Newton': linear finite elements; the resulting
%                               nonlinear system is solved via Newton's method
% reducer       method to compute the reduced basis
%               - 'SVD': Single Value Decomposition 
% sampler       how the values for $\mu$ amd $\nu$ should have been sampled 
%               for the computation of the reduced basis:
%               - 'unif': uniformly distributed on $[\mu_1,\mu_2] \times [\nu_1,\nu_2]$
%               - 'rand': drawn from a uniform random distribution on 
%               $[\mu_1,\mu_2] \times [\nu_1,\nu_2]$
% Nmu           number of snapshot values for $\mu$
% Nnu           number of snapshot values for $\nu$
% L             rank of reduced basis
% sampler_tr    how the training values for $\mu$ should be selected:
%               - 'unif': uniformly distributed on $[\mu_1,\mu_2]$
%               - 'rand': drawn from a uniform random distribution on $[\mu_1,\mu_2]$
% Nmu_tr_v      number of training patterns for $\mu$
% Nnu_tr_v      number of training patterns for $\nu$
% Nte           number of testing values for $\mu$ and $\nu$
% valPercentage ratio between number of validation and training values for 
%               $\mu$ and $\nu$
% root          path to folder where storing the output dataset
% H             number of hidden neurons
% nruns         number of re-training for each network architecture
% transferFcn   transfer function
%               - 'logsig': logarithimc sigmoid
%               - 'tansig': tangential sigmoid
% trainFcn      training algorithm
%               - 'trainlm' : Levenberg-Marquardt
%               - 'trainscg': scaled conjugate gradient
%               - 'trainbfg': quasi-Newton method
%               - 'trainbr' : Bayesian regularization
% showWindow    TRUE to open training window, FALSE otherwise
% tosave        TRUE to store the results in a Matlab dataset, FALSE otherwise

a = -pi;  b = pi;  K = 100;

% Suffix ''
v = @(u) u.^2;  dv = @(u) 2*u;
f = @(t,mu,nu) nu.*nu.*mu.*mu.*(2+sin(mu.*t)).*(-2*nu.*cos(mu.*t).^2 + ...
    2*nu.*sin(mu.*t) + nu.*sin(mu.*t).^2);
mu1 = 1;  mu2 = 3;  nu1 = 1;  nu2 = 3;  suffix = '';

BCLt = 'D';  BCLv = @(mu,nu) nu.*(2+sin(mu*a));
BCRt = 'D';  BCRv = @(mu,nu) nu.*(2+sin(mu*b));
solver = 'FEP1';
reducer = 'SVD';
sampler = 'unif';
Nmu = 25;  Nnu = 25;  N = Nmu*Nnu;  L = 8;
root = '../datasets';

H = 15:2:25;  nruns = 8;
sampler_tr_v = {'unif'};
Nmu_tr_v = [5 10 15 20 25 50];  Nnu_tr_v = [5 10 15 20 25 50];  
valPercentage = 0.3;  Nte = 100;
transferFcn = 'tansig';
trainFcn = {'trainlm'};
showWindow = false;
tosave = true;

%
% Run
%

% Set handle to solver function
if strcmp(solver,'FEP1')
    solverFcn = @NonLinearPoisson1dFEP1;
    rsolverFcn = @NonLinearPoisson1dFEP1Reduced;
elseif strcmp(solver,'FEP1Newton')
    solverFcn = @NonLinearPoisson1dFEP1Newton;
    rsolverFcn = @NonLinearPoisson1dFEP1ReducedNewton;
end

% Determine total number of training and validating samples
Ntr_v = Nmu_tr_v .* Nnu_tr_v;

% Load data for training
datafile = sprintf(['%s/NonLinearPoisson1d2pSVD/' ...
    'NonLinearPoisson1d2p_%s_%s%s_a%2.2f_b%2.2f_%s_%s_' ...
    'mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_K%i_Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
    root, solver, reducer, sampler, a, b, BCLt, BCRt, mu1, mu2, ...
    nu1, nu2, K, Nmu, Nnu, N, L, Nte, suffix);
load(datafile);

% Grid spacing
dx = (b-a) / (K-1);

%
% Create validation data set; its size is usually dependent on the number
% of training patterns
%

% Determing number of validation patterns
Nva_v = ceil(valPercentage * Ntr_v);

% Determine validation values for $\mu$ and $\nu$
mu_va = mu1 + (mu2-mu1) * rand(max(Nva_v),1);
nu_va = nu1 + (nu2-nu1) * rand(max(Nva_v),1);

% Evaluate force field at the validation values
g_va = cell(max(Nva_v),1);
parfor i = 1:max(Nva_v)
    g_va{i} = @(t) f(t,mu_va(i),nu_va(i));
end

% Compute reduced solution
%alpha_va = zeros(L,max(Nva_v));
u_va = zeros(K,max(Nva_v));
parfor i = 1:max(Nva_v)
    [x,u_va(:,i)] = solverFcn(a, b, K, v, dv, g_va{i}, BCLt, ...
        BCLv(mu_va(i),nu_va(i)), BCRt, BCRv(mu_va(i),nu_va(i)));
end
alpha_va = VL'*u_va;

%
% Create test data set; first check whether data are already available
%

Nte_opt = 200;

filename = sprintf(['%s/NonLinearPoisson1d2pNN/' ...
 	'testingdata_' ...
    'a%2.2f_b%2.2f_%s_%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_' ...
    'K%i_Nmu%i_Nnu%i_N%i_L%i_Nte%i%s.mat'], ...
    root, a, b, BCLt, BCRt, mu1, mu2, nu1, nu2, K, ...
    Nmu, Nnu, N, L, Nte_opt, suffix);
if (exist(filename,'file') == 2)
	load(filename);
	Nte = Nte_opt;
else
    % Load random data
    load(strcat(root,'/random_numbers.mat'));

    % Determine values for $\mu$ and $\nu$
    mu_te = mu1 + (mu2-mu1) * random_on_reference_interval_first(1:Nte_opt);
    nu_te = nu1 + (nu2-nu1) * random_on_reference_interval_second(1:Nte_opt);

    % Evaluate force field at the test values
    g_te = cell(Nte_opt,1);
    parfor i = 1:Nte_opt
        g_te{i} = @(t) f(t,mu_te(i),nu_te(i));
    end

    % Compute reduced solution
    u_te = zeros(K,Nte_opt);
    parfor i = 1:Nte_opt
        [x,u_te(:,i)] = solverFcn(a, b, K, v, dv, g_te{i}, BCLt, ...
            BCLv(mu_te(i),nu_te(i)), BCRt, BCRv(mu_te(i),nu_te(i)));
    end
    alpha_te = VL'*u_te;

    % Set Nte
    Nte = Nte_opt;
    
    % Save data for future runs
    save(filename, 'mu_te', 'nu_te', 'u_te', 'alpha_te')
end

%
% Train the neural network
%

for s = 1:length(sampler_tr_v)
    for n = 1:length(Ntr_v)
        Ntr = Ntr_v(n);   Nva = Nva_v(n);  sampler_tr = sampler_tr_v{s};
        if (strcmp(sampler_tr,'unif'))
            Nmu_tr = Nmu_tr_v(n);  Nnu_tr = Nnu_tr_v(n);
        elseif (strcmp(sampler_tr,'rand'))
            Nmu_tr = Ntr;  Nnu_tr = Ntr;
        end            

        % Define ratio for training, validation and test data sets
        trainRatio = Ntr / (Ntr + Nva + Nte);  
        valRatio = Nva / (Ntr + Nva + Nte);
        testRatio = 1 - trainRatio - valRatio;

        %
        % Compute training patterns and teaching inputs; first check whether
        % data are already available
        %
        
        filename = sprintf(['%s/NonLinearPoisson1d2pNN/' ...
			'trainingdata_%s_' ...
			'a%2.2f_b%2.2f_%s_%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_' ...
			'K%i_Nmu%i_Nnu%i_N%i_L%i_Nmu_tr%i_Nnu_tr%i_Ntr%i%s.mat'], ...
			root, sampler_tr, a, b, BCLt, BCRt, mu1, mu2, nu1, nu2, ...
            K, Nmu, Nnu, N, L, Nmu_tr, Nnu_tr, Ntr, suffix);
        if (exist(filename,'file') == 2)
			load(filename);
		else
            % Get training patterns
            if (strcmp(sampler_tr,'unif'))
                mu_tr = linspace(mu1, mu2, Nmu_tr);
                mu_tr = repmat(mu_tr, Nnu_tr, 1);  mu_tr = mu_tr(:);
                nu_tr = linspace(nu1, nu2, Nnu_tr)';
                nu_tr = repmat(nu_tr, Nmu_tr, 1);
            elseif (strcmp(sampler_tr,'rand'))
                mu_tr = mu1 + (mu2-mu1) * rand(Ntr,1);
                nu_tr = nu1 + (nu2-nu1) * rand(Ntr,1);
            end

            % Evaluate force field for training patterns
            g_tr = cell(Ntr,1);
            parfor i = 1:Ntr
                g_tr{i} = @(t) f(t,mu_tr(i),nu_tr(i));
            end

            % Get teaching input
            u_tr = zeros(K,Ntr);
            parfor i = 1:Ntr
                [x,u_tr(:,i)] = ...
                    solverFcn(a, b, K, v, dv, g_tr{i}, ...
                    BCLt, BCLv(mu_tr(i),nu_tr(i)), ...
                    BCRt, BCRv(mu_tr(i),nu_tr(i)));
            end
            alpha_tr = VL'*u_tr;
            
            % Save data for future runs
            save(filename, 'mu_tr', 'nu_tr', 'u_tr', 'alpha_tr')
        end

        %
        % Train
        %

        % Try different training algorithms to determine the optimal one, i.e. the
        % one yielding the minimum error
        err_opt_local = inf * ones(length(H),length(trainFcn));
        err_opt = inf;
        net_opt_local = cell(length(H),length(trainFcn));
        tr_opt_local = cell(length(H),length(trainFcn));

        for t = 1:length(trainFcn)
            % Try different number of hidden neurons to find the optimal network
            % architecture; for each architecture, re-training the network different
            % times and store the minimum test error
            err = inf * ones(length(H),1);

            for h = 1:length(H)
                % Create the feedforward neural network
                net = feedforwardnet([H(h) H(h)],trainFcn{t});
                net = configure(net, [mu_tr'; nu_tr'], alpha_tr);
                %net = cascadeforwardnet(H(h),trainFcn{t});

                % Set transfer (activation) function for hidden neurons
                net.layers{1}.transferFcn = transferFcn;

                % Set data division function
                net.divideFcn = 'divideblock';

                % Set ratio for training, validation and test data sets
                net.divideParam.trainRatio = trainRatio;
                net.divideParam.valRatio = valRatio;
                net.divideParam.testRatio = testRatio;

                % Set maximum number of consecutive fails
                net.trainParam.max_fail = 6;
                
                % Set parameters for Levenberg-Marquardt algorithm
                %net.trainParam.mu = 1;
                %net.trainParam.mu_dec = 0.8;
                %net.trainParam.mu_inc = 1.5;
                
                % Set regularization coefficient
                %net.performParam.regularization = 0.5;
                
                % Set performance function
                net.performFcn = 'mse';
                
                % Set tolerance on error for training data set
                %net.trainParam.goal = 1e-3;
                
                % Set options for training window
                net.trainParam.showWindow = showWindow;

                for p = 1:nruns
                    % Initialize the network
                    net = init(net);

                    % Train the network and test the results on test set
                    [net, tr] = train(net, ...
                        [mu_tr' mu_va(1:Nva)' mu_te'; nu_tr' nu_va(1:Nva)' nu_te'], ...
                        [alpha_tr alpha_va(:,1:Nva) alpha_te]);
                    
                    % Get average error on test data set
                    e = 0;
                    for r = 1:Nte
                        alpha = net([mu_te(r) nu_te(r)]');
                        e = e + norm(u_te(:,r) - VL*alpha);
                    end
                    e = e/Nte;

                    % Keep the error if it is the minimum so far
                    if (e < err_opt_local(h,t))  % Local checks
                        err_opt_local(h,t) = e;
                        net_opt_local{h,t} = net;
                        tr_opt_local{h,t} = tr;         
                        if (e < err_opt)  % Global checks
                            err_opt = e;
                            col_opt = t;
                            row_opt = h;
                        end
                    end
                end
            end
        end

        % Save data
        if tosave
            filename = sprintf(['%s/NonLinearPoisson1d2pNN/' ...
                'NonLinearPoisson1d2p_%s_%s%s_NN%s_' ...
                'a%2.2f_b%2.2f_%s_%s_mu1%2.2f_mu2%2.2f_nu1%2.2f_nu2%2.2f_' ...
                'K%i_Nmu%i_Nnu%i_N%i_L%i_Nmu_tr%i_Nnu_tr%i_Ntr%i_Nva%i_Nte%i_2L%s.mat'], ...
                root, solver, reducer, sampler, sampler_tr, a, b, BCLt, ...
                BCRt, mu1, mu2, nu1, nu2, K, Nmu, Nnu, N, L, ...
                Nmu_tr, Nnu_tr, Ntr, Nva, Nte, suffix);
            save(filename, 'datafile', 'H', 'nruns', 'trainFcn', 'Ntr', ...
                'Nva', 'Nte', 'err_opt_local', 'net_opt_local', ...
                'tr_opt_local', 'row_opt', 'col_opt');
        end

        % Print information about optimal parameters
        fprintf(['Number of training patterns: %i (%i for mu, %i for nu)\n' ...
            'Optimal training algorithm: %s\nOptimal number of hidden neurons: %i\n' ...
            'Minimum test error: %5E\n\n'], ...
            Ntr, Nmu_tr, Nnu_tr, trainFcn{col_opt}, H(row_opt), err_opt);
    end
end