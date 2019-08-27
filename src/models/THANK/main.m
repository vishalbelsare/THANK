%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Date: August 13, 2019
% This is the main code that controls the estimation of the baseline DSGE
% model in "..." by Bilbiie, Primiceri and Tambalotti
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

% loading the relevant dataset
load DataTHANK;
y = DataTHANK;
T = length(y);

% initial guess for maximization algorithm
guess = [0.17 ... alpha
         0.05 ... iotap
         0.08 ... iotaw
         0.53 ... gamma100 ???
         0.84 ... h
         0.25 ... lambdapss ???
         0.12 ... lambdawss ???
         0.50 ... Lss ???
         0.75 ... pss
         0.10 ... Fbeta
         1.96 ... niu
         0.77 ... xip
         0.73 ... xiw
         4.95 ... chi
         2.50 ... S
         4.00 ... fp
         0.10 ... fy
         0.25 ... fdy
         0.78 ... rhoR
         0.25 ... rhoZ
         0.98 ... rhog
         0.70 ... rhomiu
         0.95 ... rholambdap
         0.98 ... rholambdaw
         0.70 ... rhob
         0.15 ... rhomp
         0.75 ... rhoARMAlambdap
         0.95 ... rhoARMAlambdaw
         0.20 ... sdR
         0.90 ... sdz
         0.35 ... sdg
         5.00 ... sdmiu
         0.15 ... sdlambdap
         0.20 ... sdlambdaw
         0.05 ... sdb
         0.30 ... theta %%% New parameters below
         1.00 ... sigm
         0.00 ... sigp
         0.00 ... tauD
         0.00]; % tauk
       
x0 = boundsINV(guess);

% posterior maximization
[fh, xh, gh, H, tct, fcount, retcodeh] = csminwel('logpostTHANK', x0, ... 
                          0.1 * eye(length(x0)), [], 10e-4, 1000, T, y);

% processing the output of the maximization
postmode = bounds(xh);
JJ       = jacobTHANK(xh);
HH       = JJ * H * JJ';

% preliminaries for the MCMC algorithm
const = .4;    % scaling constant for the inverse Hessian
M     = 2000;  % length of each of the two chains
N     = 200;   % number of discarded draws at the beginning of each chain

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Metropolis algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First chain
P1 = zeros(M,length(xh));
logpostOLD = -1e+10;
while logpostOLD == -1e+10
    P1(1,:) = mvnrnd(postmode, 4 * HH * const^2, 1);
    logpostOLD = logpostTHANK_MCMC(P1(1,:), T, y);
end

count = 0;
for i=2:M
    if i==100*floor(.01*i)
        i
        ACCrate1 = count/i
    end
    P1(i,:)=mvnrnd(P1(i-1,:),HH*const^2,1);
    logpostNEW=logpostTHANK_MCMC(P1(i,:),T,y);
    
    if logpostNEW > logpostOLD
        logpostOLD=logpostNEW;
        count=count+1;
    else
        if rand(1) < exp(logpostNEW - logpostOLD)
            logpostOLD = logpostNEW;
            count = count+1;
        else
            P1(i,:) = P1(i-1,:);
        end
    end
end
ACCrate1=count/M;

% Second chain
P2=zeros(M,length(xh));
logpostOLD=-1e+10;
while logpostOLD == -1e+10
    P2(1,:) = mvnrnd(postmode, 4 * HH * const^2, 1);
    logpostOLD = logpostTHANK_MCMC(P2(1,:), T, y);
end

% Metropolis algorithm
count=0;
for i=2:M
    if i == 100*floor(.01*i)
        i
    end
    P2(i,:) = mvnrnd(P2(i-1,:), HH * const^2, 1);
    logpostNEW = logpostTHANK_MCMC(P2(i,:), T, y);
    
    if logpostNEW > logpostOLD
        logpostOLD = logpostNEW;
        count = count+1;
    else
        if rand(1) < exp(logpostNEW - logpostOLD)
            logpostOLD = logpostNEW;
            count = count+1;
        else
            P2(i,:) = P2(i-1,:);
        end
    end
end
ACCrate2 = count/M;

% Third chain
P3 = zeros(M,length(xh));
logpostOLD = -1e+10;
while logpostOLD == -1e+10
    P3(1,:) = mvnrnd(postmode,4*HH*const^2,1);
    logpostOLD = logpostTHANK_MCMC(P3(1,:),T,y);
end

% Metropolis algorithm
count=0;
for i=2:M
    if i == 100*floor(.01*i)
        i
    end
    P3(i,:) = mvnrnd(P3(i-1,:),HH*const^2,1);
    logpostNEW = logpostTHANK_MCMC(P3(i,:),T,y);
    
    if logpostNEW > logpostOLD
        logpostOLD = logpostNEW;
        count = count + 1;
    else
        if rand(1) < exp(logpostNEW-logpostOLD) 
            logpostOLD = logpostNEW;
            count = count+1;
        else
            P3(i,:) = P3(i-1,:);
        end
    end
end
ACCrate3=count/M;

P = [P1(N+1:end,:); P2(N+1:end,:); P3(N+1:end,:)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MED=median(P)';
prctile5=prctile(P,5)';
prctile95=prctile(P,95)';
[MED prctile5 prctile95]           % parameter estimates (median and 90% CI)
