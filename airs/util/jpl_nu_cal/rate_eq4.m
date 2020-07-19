function [y]=rate_eq4(X, t);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [y] = rate_eq(X,t);
%
% Input:
%    X = Fitting coefficients
%    t = delta time in days
%
% Output:
%    y = computed valuels
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Do the following for later flexibility
X = X';

% Calc
y  =    X(1,:) - X(2,:)*t + ...
        X(3,:).*sin(2*pi*t/365 + X(4,:))  + ...
        X(5,:).*sin(4*pi*t/365 + X(6,:)); %  + ...

