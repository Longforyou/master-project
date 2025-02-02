% A script for testing various components of the finite element solver for
% two-dimensional Poisson.

clc
clear variables
clear variables -global
close all

%% Preliminar test: function vs handle function

x = randn(1e6,1);

tstart = tic;
for i = 1:1e6
    y = 1;
end
dt = toc(tstart);
fprintf('Direct function: %5.5f\n',dt)

fun = @(t) 1;
tstart = tic;
for i = 1:1e6
    y = fun(x(i));
end
dt = toc(tstart);
fprintf('Handle function: %5.5f\n',dt)

tstart = tic;
for i = 1:1e6
    if isfloat(1)
        y = 1;
    end
end
dt = toc(tstart);
fprintf('%5.5f\n',dt)

%% Test buildMesh2d and plotMesh2d

close all

%[mesh,model] = buildMesh2d('rectangle');
%[mesh,model] = buildMesh2d('rectangle', 'base',2, 'height',3);
%[mesh,model] = buildMesh2d('rectangle', 'base',2, 'height',3, 'angle',pi/4);
[mesh_r,mesh,opt] = buildMesh2d('quadrilateral', 'A',[1 0]', 'B',[2 1]', 'C',[1 1.01]', 'D',[0 1]');

%plotMesh2d(mesh_r, 'title','Reference domain')
%plotMesh2d(mesh, 'title','Physical domain')

%% Test first version of LinearPoisson2dFEP1

%[mesh,u] = LinearPoisson2dFEP1('rectangle', 'base',2, 'height',3, 'angle',-pi/4);
%plotMesh2d(mesh)

%% Test full version of LinearPoisson2dFEP1

clc

%[mesh,u] = LinearPoisson2dFEP1(@K1, @f1, 'D',@BC1, 'D',@BC1, 'D',@BC1, 'D',@BC1, ...
%     'rectangle', 'base',10, 'height',10, 'angle',pi/10);
%[mesh,u] = LinearPoisson2dFEP1(@K1, @f2, 'D',@BC2, 'D',@BC0, 'D',@BC2, 'D',@BC0, ...
%    'rectangle', 'origin',[1 0]', 'Hmax',0.04);
[mesh_r,mesh,u] = LinearPoisson2dFEP1(@identity, @doublesincos, 'D',@sincos, 'D',@sincos, 'D',@sincos, 'D',@sincos, ...
    'quad', 'A',[0 0], 'B',[2*pi 0], 'C',[2*pi 2*pi], 'D',[0 2*pi], 'Hmax',0.01);

close all
plotSolution2d(mesh,u)

%% Test convergence

close all

h = [0.016 0.008 0.004 0.002 0.001];
err = zeros(numel(h),1);

for i = 1:numel(h)
    [mesh_r,mesh,u] = LinearPoisson2dFEP1(@identity, @doublesincos, 'D',@sincos, 'D',@sincos, 'D',@sincos, 'D',@sincos, ...
        'quad', 'A',[0 0], 'B',[2*pi 0], 'C',[2*pi 2*pi], 'D',[0 2*pi], 'Hmax',h(i));
    %[mesh,u] = LinearPoisson2dFEP1(@identity, @unitperiodsinx2, 'D',@unitperiodsinx, ...
    %    'D',@unitperiodsinx, 'D',@unitperiodsinx, 'D',@unitperiodsinx, ...
    %    'rectangle', 'Hmax',h(i));
    plotSolution2d(mesh,u)
    err(i) = getDiscreteContinuousErrorL2(mesh,u,@sincos);
    %err(i) = getDiscreteContinuousErrorL2(mesh,u,@unitperiodsinx);
end

%% Test map from reference square to quadrangle

close all

% Define vertices of physical domain
xa = 0;  ya = 0;
xb = 3;  yb = 1.5;
xc = 1;  yc = 4;
xd = -1; yd = 3;

% Build mesh on reference domain
mesh_r = buildMesh2d('rectangle');
plotMesh2d(mesh_r, 'title','Reference domain')

% Build map
M = [xb-xa xd-xa xa-xb+xc-xd xa; yb-ya yd-ya ya-yb+yc-yd ya];
s = repmat([xa ya]', 1, mesh_r.getNumNodes());  

% Map mesh from reference to physical domain and plot
nodes = mesh_r.nodes;  elems = mesh_r.elems;
nodes_ext = [nodes; nodes(1,:).*nodes(2,:); ones(1,mesh_r.getNumNodes())];
mesh = mesh2d(M*nodes_ext+s,elems);
plotMesh2d(mesh, 'title','Physical domain')
