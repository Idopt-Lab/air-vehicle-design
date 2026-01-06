% Rosenbrock's "banana function"
% It is called the banana function because of its curvature around the origin. 
% It is notorious in optimization examples because of the slow convergence most methods exhibit when trying to solve this problem.
% It has a unique minimum at the point x=[1,1] where f(x)=0
function y = rosenbrock_function(x)
    y = 100*(x(2) - x(1)^2)^2 + (1 - x(1))^2;
end