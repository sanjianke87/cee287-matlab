function PartA()
%PartA Design the base isolation system for the 9 story building
%   analysed in assignment #5
    addpath('./functions'); clc

    gravity = 386.1; % in/s^2
    targetDrift = 0.5/100; % 0.5%
    designSds = 1.5;
    designSd1 = 1.0;
    designR = 1.0;
    designCd = 1.0;
    designI = 1.0;
    
    isolatorDamping1 = 0.1; % First mode damping of 10% 
    isolatorDamping2 = 0.035; % Second mode damping ratio of 3.5%
    isolatorDamping3 = 0.035; % Third mode damping ratio of 3.5%
    
    % Define the height of each floor in the building 
    % The vector is defined from the bottom to top, starting at 0'
    nfloors = 9;
    hroof = 118; 
    heights = linspace(0,hroof,nfloors+1);
    
    % Set the building parameters as we they were defined
    % in homework 5, and redefined in homework 8.
    W = 1800; % kips/in
    mass = W/386.1; % At each floor
    stiffness = 1700; % At each floor
    nfloors = 9;
    nmodes = 1;
    
    % Get the stiffness and mass matrix of the equivalent structure
    % Compute the mode shape for the first mode of vibration 
    [M, K] = computeMatrices(nfloors,mass,stiffness);
    [~,T,sphi,~] = eigenvalueAnalysis(nfloors,nmodes,mass,stiffness);
    
    % Use the modal analysis to compute the equivalent lateral stiffness
    % and mass of the structure. These parameters will be normalization
    % dependant but the ratio of them will be unique. 
    alpha = 0.8; 
    beta = 1/9;
    
    fprintf('Part A:\n')
    ks = sphi(:,1)'*K*sphi(:,1);
    ms = sphi(:,1)'*M*sphi(:,1);
    ki = alpha*ks;
    mi = beta*ms;
    
    fprintf('Equivalent Stiffness, ks = %.4f [kips/in per unit mass]\n',ks);
    fprintf('Equivalent Mass, ms = %.4f [kips.s^2/in per unit mass]\n',ms);
    fprintf('Isolator Stiffness, ki = %.4f [kips/in per unit mass]\n',ki);
    fprintf('Isolator Mass, mi = %.4f [kips.s^2/in per unit mass]\n',mi);
    
    % Analyze the equivalent 2DOF structure with the following properties
    % ks,ms,ki,mi. First a modal analysis is conducted to find the period
    % of each mode. Then another modal analysis is conducted to find the 
    % displacement and drift at each floor.
    w1squared = (ms*ks*(1+alpha)+beta*ms*ks - sqrt((ms*ks*(1+alpha)+beta*ms*ks)^2 - 4*alpha*beta*ms^2*ks^2))/(2*beta*ms^2);
    w2squared = (ms*ks*(1+alpha)+beta*ms*ks + sqrt((ms*ks*(1+alpha)+beta*ms*ks)^2 - 4*alpha*beta*ms^2*ks^2))/(2*beta*ms^2);
    
    T1 = 2*pi/sqrt(w1squared);
    T2 = 2*pi/sqrt(w2squared);
    
    gamma1 = (-ms*w1squared+ks)/ks;
    gamma2 = (-ms*w2squared+ks)/ks;
    
    phi1 = [1, gamma1]';
    phi2 = [1, gamma2]';
    
    Gamma1 = (1+gamma1*beta)/(1+gamma1^2*beta);
    Gamma2 = (1+gamma2*beta)/(1+gamma2^2*beta);
    
    E1 = 0.1;
    E2 = 0.035;
    
    a1 = 1.303 + 0.436*log(E1);
    a2 = 1.303 + 0.436*log(E2);
    
    B1 = 1 - a1*T1^0.3/(T1+1)^0.65;
    B2 = 1 - a2*T2^0.3/(T2+1)^0.65;
    
    An1 = B1*designSd1/T1;
    An2 = B2*designSd1;
    
    Uj1 = Gamma1*phi1*An1*gravity/w1squared;
    Uj2 = Gamma2*phi2*An2*gravity/w2squared;
    
    
    
    
   
    
    % Alternatively we can use modal analysis 
     nmodes = 2;
     nfloors = 2;
     masses = [mi, ms]';
     stiffnesses = [ki, ks]';
     [M, K] = computeMatrices(nfloors,masses,stiffnesses);
     [~,T,phi,gamma] = eigenvalueAnalysis(nfloors,nmodes,masses,stiffnesses);
     phi(:,1) = phi(:,1)/phi(2,1);
     phi(:,2) = phi(:,2)/phi(2,2);
    
    Hi = 2/3*hroof;
    Csm = [An1,An2];
    [F,V,U,drift] = modalAnalysis(nfloors,nmodes,masses,stiffnesses,Csm,Hi);
    U =  sqrt(sum(U.^2,2));
    drift =  sqrt(sum(drift.^2,2));
    
    % Print results from equivalent structure analysis
    fprintf('\n\nEquivalent structure results:\n')
    fprintf('Stiffness matrix:\n'); disp(K);
    fprintf('Mass matrix:\n'); disp(M);
    fprintf('Period mode 1: %.4f s\n',T(1));
    fprintf('Period mode 2: %.4f s\n',T(2));
    fprintf('Cs mode 1: %.4f s\n',Csm(1));
    fprintf('Cs mode 2: %.4f s\n',Csm(2));
    fprintf('Displacement:\n'); disp(U);
    fprintf('Drift [%%]:\n'); disp(100*drift);
    
    % Convert the equivalent structure back to real system
    % First we need to calculate the beta values for the real system
    Beta1 = gamma(1)*sphi(end,1);
    Beta2 = 0;
    for j=2:nfloors
        % We are calculating the IDR of the first mode
        Hroof = heights(end);
        Hstory = heights(j)-heights(j-1);
        Beta = Hroof*(sphi(j,1) - sphi(j-1,1)) / (Hstory*sphi(end,1));
        Beta2 = max(Beta,Beta2);
    end
    IDR_MDOF = 2/3*Beta1*Beta2*drift(1);
    
    fprintf('Analysis for real structure\n')
    fprintf('Beta1 = %.4f\n',Beta1);
    fprintf('Beta2 = %.4f\n',Beta2);
    fprintf('MDOF drift = %.4f %%\n',IDR_MDOF*100);
    
end

