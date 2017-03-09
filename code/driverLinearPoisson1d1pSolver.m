% driverLinearPoisson1d1pSolver Driver for solving the linear one-dimensional 
% Poisson equation $-u''(x) = f(x,\mu)$ on $[a,b]$ depending on the real
% parameter $\mu$. Linear or quadratic finite elements can be used.

clc
clear variables
clear variables -global
%close all

%
% User-defined settings
%

a = -1;  b = 1;
K = 200;

%mu = -0.8;  sigma = 0.2;  f = @(t) gaussian(t,mu,sigma);
%mu = 0.1;  f = @(t) mu * t .* ((-mu <= t) & (t <= mu));
%mu = 4;  f = @(t) (t-1).^mu;
%f = @(t) 50 * t .* cos(2*pi*t);
%mu = 0.25;  f = @(t) 2 * atan(mu * t/2);
%v = @(t) 1 + 0*t;
%mu = 0.5;  f = @(t) 2*(t >= mu) - 1*(t < mu);

mu = 0.9;  nu = 3;
%v = @(t) nu*(t < 0) + (nu + nu*t).*(t >= 0);
%v = @(t) 1*(t < nu) + 4*(t >= nu);
%v = @(t) gaussian(t,0,nu);
%v = @(t) 1 + (t+1).^nu;
v = @(t) 2 + sin(nu*pi*t);
%f = @(t) - mu*(t < 0) + 2*mu*(t >= 0);
%f = @(t) -gaussian(t,-mu,0.8) + gaussian(t,mu,0.8);
f = @(t) 2*(t >= mu) - 1*(t < mu);
%f = @(t) gaussian(t,mu,0.1);

BCLt = 'D';  BCLv = 0;
BCRt = 'D';  BCRv = 0;

%
% Run
%

% Solve
[x,u1] = HeterogeneousViscosityLinearPoisson1dFEP1_f(a, b, K, v, f, BCLt, BCLv, BCRt, BCRv);

% Plot
%figure;
hold on;
plot(x,u1);
title('Solution to Poisson equation')
xlabel('$x$')
ylabel('$u(x)$')
grid on
%axis equal
xlim([a b])