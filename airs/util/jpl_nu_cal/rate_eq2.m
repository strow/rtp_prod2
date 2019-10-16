function [y]=rate_eq2(X, t);
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
y  = X(1,:) - X(2,:).*exp(-t.*X(3,:)/365) + ...
        X(4,:).*sin(2*pi*t/365 + X(5,:))  + ...
        X(6,:).*sin(4*pi*t/365 + X(7,:))  + ...
        X(8,:).*sin(6*pi*t/365 + X(9,:)) ;%  + ...
