% MAIN  --  minimum snap* trajectory
%
% *snap = second derivative of acceleration
%
% For a simple pendulum:
%
% x = position
% v = velocity
% u = torque
%
% ddx = f(x,dx,u);     <-- dynamics
%
% cost = integral(  ddddx^2  );     <-- cost function
%
% subject to:
%   x(0) = 0;
%   x(1) = pi;
%   dx(0) = 0;
%   dx(1) = pi;
%
% How to pose as a standard trajectory optimization problem?
%
% dx = v1;
% dv1 = f(x,v1,u1)
%
% v2 == v1;   % <-- Key line.
% dv2 = a2;
% da2 = j2;  % jerk = derivative of acceleration
% dj2 = u2;  % snap = derivative of jerk
% cost = integral(  u2^2  );
%
%
% NOTES:
%
%   z = [x;v1;v2;a2;j2];
%   u = [u1;u2];
%
clc; clear;

%%%% Specify boundary conditions
t0 = 0;
tF = 2;

z0 = [0;0;0;0;0];
zF = [pi;0;0;0;0];

maxTorque = 5;

%%%% Pack up boundary conditions
problem.bounds.initialTime.low = t0;
problem.bounds.initialTime.upp = t0;

problem.bounds.finalTime.low = tF;
problem.bounds.finalTime.upp = tF;

problem.bounds.initialState.low = z0;
problem.bounds.initialState.upp = z0;

problem.bounds.finalState.low = zF;
problem.bounds.finalState.upp = zF;

problem.bounds.control.low = [-maxTorque; -inf];
problem.bounds.control.upp = [maxTorque; inf];

%%%% Initialize trajectory with a straight line
problem.guess.time = [t0,tF];
problem.guess.state = [z0, zF];
problem.guess.control = [zeros(2,1), zeros(2,1)];

%%%% Pack up function handles
problem.func.dynamics = @(t,z,u)(  dynamics(z,u)  );
problem.func.pathObj = @(t,z,u)(  pathObjective(u)  );
problem.func.pathCst = @(t,z,u)(  pathConstraint(z)  );

%%%% Options

method = 'chebyshev';

switch method
    case 'chebyshev'
        problem.options.method = method;
        problem.options.chebyshev.nColPts = 25;
    case 'hermiteSimpson'
        problem.options.method = method;
        problem.options.hermiteSimpson.nSegment = 15;
        problem.options.nlpOpt.MaxFunEvals = 5e4;
    otherwise
        error('invalid method')
end

%%%% Solve
soln = trajOpt(problem);


%%%% Unpack the solution

tGrid = soln.grid.time;
xGrid = soln.grid.state(1, :);
v1Grid = soln.grid.state(2, :);
v2Grid = soln.grid.state(3, :);
a2Grid = soln.grid.state(4, :);
j2Grid = soln.grid.state(5, :);
u1Grid = soln.grid.control(1, :);
dj2Grid = soln.grid.control(2, :);

t = linspace(tGrid(1), tGrid(end), 100);
z = soln.interp.state(t);
u = soln.interp.control(t);
x = z(1,:);
v1 = z(2,:);
v2 = z(3,:);
a2 = z(4,:);
j2 = z(5,:);
u1 = u(1,:);
dj2 = u(2,:);

%%%% Plot the trajectory against time
figure(1); clf;

subplot(3,2,1); hold on;
plot(t,x)
plot(tGrid,xGrid,'ko','MarkerSize',8,'LineWidth',2);
title('position (angle)')

subplot(3,2,3); hold on;
plot(t,v1)
plot(t,v2)
plot(tGrid,v1Grid,'ko','MarkerSize',8,'LineWidth',2);
plot(tGrid,v2Grid,'ko','MarkerSize',8,'LineWidth',2);
title('velocity (angular rate)')
legend('v1','v2')

subplot(3,2,5); hold on;
plot(t,u1)
plot(tGrid,u1Grid,'ko','MarkerSize',8,'LineWidth',2);
title('torque')

subplot(3,2,2); hold on;
plot(t,a2)
plot(tGrid,a2Grid,'ko','MarkerSize',8,'LineWidth',2);
title('acceleration')

subplot(3,2,4); hold on;
plot(t,j2)
plot(tGrid,j2Grid,'ko','MarkerSize',8,'LineWidth',2);
title('jerk')

subplot(3,2,6); hold on;
plot(t,dj2)
plot(tGrid,dj2Grid,'ko','MarkerSize',8,'LineWidth',2);
title('snap')





