% LOAD THE the estimates of MCMC and addpath
% load('/work/sta790/ff31/MCMC_estimation_paper.mat')  
% addpath('/work/sta790/ff31/HPYsinglecell/codes')  
% addpath('/work/sta790/ff31/HPYsinglecell/codes/hyper') 

% get job array ID
III = str2num(getenv('SLURM_ARRAY_TASK_ID'));
rng(III*100)

    % Uniform sampling
    supp=1:J;
    masses=ones(1,J)/J;
    KuniUni=Kini;
    bigK=length(Kini);
    
    % HPY
    nn=n_init;
    KuniHPY=Kini;
    mjk=mjk_ini;
    m_dot_k=m_dot_k_ini;
    m_j_dot=m_j_dot_ini;
    m_dd=m_dd_ini;
    M_parameters=M_parameters_ini;
    
    % calcolo n.k
    nj_dot_k=zeros(J,tot_dist);
    for j=1:J
        for w=1:tot_dist
            nj_dot_k(j,w) = sum(data{j}==KuniHPY(w));
        end
    end
    
    
    % Oracle
    KuniOracle=Kini;
    missingmass=zeros(1,J);
    for j=1:J
        labelsseen=ismember(pop{j},KuniOracle);
        missingmass(j) = 1-sum(freq{j}(labelsseen));
    end
    
    % Good-Tulming
    GT_data=data;
    KuniGT=Kini;
    
    % vector to indicate whether i discover new species 
    newobsindHPY=zeros(1,addsample);
    newobsindOra=zeros(1,addsample);
    newobsindUni=zeros(1,addsample);
    newobsindGT=zeros(1,addsample);
    
    % weights
    w_HPY=zeros(1,J);
    w_Ora=zeros(1,J);
    w_Uni=zeros(1,J);
    w_GT=zeros(1,J);
    
    
    
    %% Start Algorithms
    
    
    
    for i=1:addsample
        
        alpha_temp = alpha(III,:);
        d_temp = d(III,:);
        
        % Uniform
        unif=gendiscr(supp,masses);
        w_Uni(unif)=w_Uni(unif)+1;
        
        
        % HPY
        betadraws=zeros(1,J);
        K_j_post = zeros(1,J);
        betazero=betarnd(gamma(III,1)+nu(III,1)*bigK,m_dd-bigK*nu(III,1));
        for j=1:J
            betadraws(j)=betarnd(betazero*(alpha_temp(j)+(m_j_dot(j))), ((1-betazero)*(alpha_temp(j)+m_j_dot(j))+ nn(j)- m_j_dot(j)));
            K_j_post(j) = E_Kjl_simplified(betadraws(j),nu(III,1),gamma(III,1),bigK,...
                alpha_temp(j),d_temp(j),betazero,m_j_dot(j),n_inc);
        end
  
        [v_max, armchosen]= max(K_j_post);
        w_HPY(armchosen)=w_HPY(armchosen)+1;
        
        
        % Oracle
        [v_max armchosenOrac]=max(missingmass);
        if length(armchosenOrac)>1
            Oracprob=ones(1,length(armchosenOrac))/armchosenOrac;
            armchosenOrac=gendiscr(armchosenOrac,Oracprob);
        end
        w_Ora(armchosenOrac)=w_Ora(armchosenOrac)+1;
        
        
        % GT
        u_GT=zeros(1,J);
        for j=1:J
            t = size(data{j},2)/n_inc;
            f = makeFinger(data{j});            
            u_GT(j) = U_GT(f,t) + alpha_GT;
        end
        u_GT = u_GT./sum(u_GT);
        armchosenGT = gendiscr(1:J,u_GT);
        w_GT(armchosenGT)=w_GT(armchosenGT)+1;
        
        % Sample a unit for each strategy
        newobservations=zeros(n_inc,J);
        for j=1:J
            for jj=1:n_inc
                newobservations(jj,j) = gendiscr(pop{j},freq{j});
            end
        end
        newunif=newobservations(:,unif);
        newobsHPY=newobservations(:,armchosen);
        newobsOrac=newobservations(:,armchosenOrac);
        newobsGT=newobservations(:,armchosenGT);
        
        % Update Uniform
        newobsindUni(i) = 0;
        for jj=1:n_inc
        if sum(KuniUni==newunif(jj))==0
            newobsindUni(i)=newobsindUni(i)+1;
            KuniUni=[KuniUni newunif(jj)];
        end
        end
        
        % Update parameters of HPY
        % Save old parameters for new filtering algorithm
        mjk_old = mjk;m_j_dot_old = m_j_dot;m_dd_old = m_dd; 
        m_dot_k_old = m_dot_k;nj_dot_k_old = nj_dot_k; nn_old = nn;
        bigK_old = bigK;
        
        % update tables 
        newobsindHPY(i) = 0;
        for jj=1:n_inc
        if sum(KuniHPY==newobsHPY(jj))==0
            bigK=bigK+1;
            m_j_dot(armchosen)=m_j_dot(armchosen)+1;
            m_dd=m_dd+1;
            KuniHPY=[KuniHPY newobsHPY(jj)];
            newobsindHPY(i)=newobsindHPY(i)+1;
            m_dot_k=[m_dot_k 1];
            nj_dot_k=[nj_dot_k , zeros(J,1)];
            mjk=[mjk , zeros(J,1)];
            nj_dot_k(armchosen,bigK)=1;
            mjk(armchosen,bigK)=1;
        else
            
            % probability of old table with old observation
            olddistinct=find(KuniHPY==newobsHPY(jj));
            probnewold=[nj_dot_k(armchosen,olddistinct)-d_temp(armchosen)*mjk(armchosen,olddistinct),...
                (alpha_temp(armchosen)+m_j_dot(armchosen)*d_temp(armchosen))*((m_dot_k(olddistinct)-nu(III,1))/(gamma(III,1)+m_dd))];
            probnewold=probnewold/sum(probnewold);
            bern=binornd(1,probnewold(1));
            if bern==0
                % observation is in a new table
                m_j_dot(armchosen)=m_j_dot(armchosen)+1;
                m_dot_k(olddistinct)= m_dot_k(olddistinct)+1;
                mjk(armchosen,olddistinct)=mjk(armchosen,olddistinct)+1;
                m_dd=m_dd+1;
            end
            nj_dot_k(armchosen,olddistinct)=nj_dot_k(armchosen,olddistinct)+1;
        end
        
        nn(armchosen)=nn(armchosen)+1;
        end
        
        % update HPY hyperparameters with MH
        [alpha(III,:), d(III,:) ,gamma(III,1) ,nu(III,1) , M_parameters]=Filter_hyperparameters_v1(...
            mjk,m_j_dot,m_dd,m_dot_k,nj_dot_k,J,nn,bigK,N_iter,M_parameters,...
            mjk_old, m_j_dot_old,m_dd_old,m_dot_k_old,nj_dot_k_old,nn_old,...
            bigK_old);
        
        
        % Update Oracle
        newobsindOra(i) = 0;
        for jj=1:n_inc
        if sum(KuniOracle==newobsOrac(jj))==0
            KuniOracle=[KuniOracle newobsOrac(jj)];
            newobsindOra(i)=newobsindOra(i)+1;
            % update la missin mass
            for j=1:J
                newlabel=find(pop{j}==newobsOrac(jj));
                if isnan(newlabel)==0
                    missingmass(j)=missingmass(j)-freq{j}(newlabel);
                end
            end
        end
        end
        
        % Update GT
        newobsindGT(i)=0;
        for jj=1:n_inc
        if sum(KuniGT==newobsGT(jj))==0
            KuniGT=[KuniGT newobsGT(jj)];
            newobsindGT(i)=newobsindGT(i)+1;
        end
        end
        GT_data{armchosenGT} = [GT_data{armchosenGT} newobsGT'];
        
    end
    
    % results MCMC
    distcumHPY=cumsum(newobsindHPY);
    distcumUni=cumsum(newobsindUni);
    distcumOra=cumsum(newobsindOra);
    distcumGT=cumsum(newobsindGT);
    
    DATAfinal_HPY(III,:)=distcumHPY;
    DATAfinal_uniform(III,:)=distcumUni;
    DATAfinal_Oracle(III,:)=distcumOra;
    DATAfinal_GoodTulming(III,:)=distcumGT;
    
    WEIGTHS_HPY(III,:)=w_HPY;
    WEIGTHS_uniform(III,:)=w_Uni;
    WEIGTHS_Oracle(III,:)=w_Ora;
    WEIGTHS_GoodTulming(III,:)=w_GT;
    
    III
    
    
    % Storage just for one iteration of algorithm 
    save_file = strcat('results_',string(III),'.mat');
    save(save_file);

    
    

