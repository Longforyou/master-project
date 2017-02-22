% driverLinearPoisson1dReduced Given the parametrized, linear one-dimensional
% Poisson equation $-u''(x) = f(x,\mu)$ defined on $[a,b]$, this script 
% performs the following tasks:
% - computing a discrete solution (snapshot) for different values of $\mu$
% - build a reduced basis out of the ensemble of snapshots
% - solve the full and reduced discrete model for other values of $\mu$
% - compute the error between full and reduced solution
% - store the results in a Matlab dataset

clc
clear variables
clear variables -global
close all

%
% User-defined settings
%
% a         left boundary of the domain
% b         right boundary of the domain
% K         number of grid points
% f         force field $f = f(t,\mu)$ as handle function
% mu1       lower bound for $\mu$
% mu2       upper bound for $\mu$
% BCLt      kind of left boundary condition; 'D' = Dirichlet, 'N' =
%           Neumann, 'P' = periodic
% BCLv      value of left boundary condition
% BCRt      kind of right boundary condition; 'D' = Dirichlet, 'N' =
%           Neumann, 'P' = periodic
% BCRv      value of right boundary condition
% solver    handle to solver; note that the solver should be designed also 
%           for model reduction (see, e.g., LinearPoisson1dFEP1 and LinearPoisson1dFEP2)
% reducer   handle to function computing the reduced basis (see, e.g., 
%           getLinearPoisson1dSVDreducedBasis)
% N         number of snapshots
% L         rank of reduced basis
% J         number of verification values for $\mu$
% root      path to folder where storing the output dataset

a = -1;  b = 1;  
K = 100;
f = @(t,mu) gaussian(t,mu,0.2);  
mu1 = -1;  mu2 = 1;
BCLt = 'D';  BCLv = 0;
BCRt = 'D';  BCRv = 0;
solver = @LinearPoisson1dFEP1;
reducer = @getLinearPoisson1dSVDreducedBasis;
N = [10 25 50 75 100]; 
L = [3 5 8 10 15];  
J = 50;
root = '../datasets';

%
% Run
%

% Validation values for $\mu$ drawn from a random uniform distribution on 
% $[\mu_1,\mu_2]$
mu_v = mu1 + (mu2-mu1) * rand(J,1);

% Evaluate force field for validation values of $\mu$
g_v = cell(J,1);
for i = 1:J
    g_v{i} = @(t) f(t,mu_v(i));
end

for iN = 1:length(N)
    for iL = 1:length(L)
        % Compute snapshots and reduced basis
        [x, mu_t, Y_t, UL] = reducer(mu1, mu2, N(iN), L(iL), ...
            solver, a, b, K, f, BCLt, BCLv, BCRt, BCRv);
        
        % Compute the coefficients of the expansion of the snapshots in 
        % terms of the reduced basis vectors
        g_t = cell(N(iN),1);
        for i = 1:N(iN)
            g_t{i} = @(t) f(t,mu_t(i));
        end
        [x, alpha_t] = solver(a, b, K, g_t, BCLt, BCLv, BCRt, BCRv, UL);
        
        % Compute solution through full and reduced solver
        [x, u_v, alpha_v] = solver(a, b, K, g_v, BCLt, BCLv, BCRt, BCRv, UL);
        ur_v = UL * alpha_v;
        
        % Compute error between full and reduced solutions
        err = zeros(J,1);
        for i = 1:J
            err(i) = norm(u_v(:,i) - ur_v(:,i));
        end

        % Save
        filename = sprintf('%s/LinearPoisson1dFEP1_K%i_N%i_L%i_J%i.mat', ...
            root, K, N(iN), L(iL), J);
        save(filename, 'x', 'mu_t', 'Y_t', 'UL', 'alpha_t', 'mu_v', 'u_v', 'alpha_v', 'ur_v', 'err');
    end
end
