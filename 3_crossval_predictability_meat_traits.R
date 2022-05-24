#-----------------------------------------------------------------------------#
# Date: 12 October 2021
# Description code: r-repeated 5-fold cross-validation to estimate the predictive ability
#                   of animal models in meat quality and carcass traits
# 1. Input files: 
# 1.1. Dataframe with phenotypes and fixed effects
# 1.2. Relationship matrix : A, Gibs, Gibd
# 2. Ouput files:
# 2.1.resu_varcomp_Gibs: text file with estimated variance components.
# 2.2.rfold_G: text file with 4 columns: number of replicate,name of trait, number of fold, 
#                       estimated correlation between the observed and predicted phenotype.
# 2.3.resu_sd_G: text file with number of iteration
#
# ****Observations***
# 1. This code was write to run 300 times in a High Performance Computing (HPC) 
#   and the next additional arguments in the bash file are need:
#     for rep in {1..300}
#     do
#     sd=`echo 0 | awk -v rep="$rep" '{print $1+(rep-1)*1000}'`
#     Rscript 2_crossval_predictability_meat_traits.R $rep $sd
#     done
#
# 2. The code execute only one relationship matrix, therefore it is necessary
#    change the matrix if do you want to run the validation for the other matrices
#
# 3. It may be that some replicates the estimation of variance components does not achieve 
#    the convergence criteria with some matrix, then the replicate will not appear in the output file
#
# 4. Running the code to 1 replicate per trait, the elapsed time is 13.647 seconds in a personal computer
#-----------------------------------------------------------------------------#


rm(list=ls())
setwd("~/Documents/Github_heritability_predictability_Meat_Traits/")

# Arguments take from bash file
#args <- commandArgs(TRUE)
#rep <-as.integer(args[1]) # number of replicates (default = 300)
#sd <- as.integer(args[2])
rep <-1 # run 1 replicate
sd <- 1 # seed from 1
# Number of folds
nfold = 5

# Libraries
library(regress)
library(gwaR)
library(Matrix)
library(caret)
library(MASS)
library(tidyverse)

# 1. Load input files
# 1.1. Load phenotypes data
load("msuprphenofile.Rdata")
# 1.2. Load Relationship matrix
load("Gibs_mat.Rdata")
#load("A_mat.Rdata")
# G<-A
#load("Gibd_mat.Rdata")
#G<-Gibd



# 2. Description of the mix model for each meat quality trait
cont_struc<-rbind(
c("last_lum.1",y~sex + car_wt + slgdt_cd),c("dress_ptg.1",y~ + car_wt + slgdt_cd),
  c("car_length.1",y~sex + car_wt + slgdt_cd),c("belly.1",y~sex + car_wt + slgdt_cd),
  c("juiciness.1",y~sex + car_wt + slgdt_cd),c("WBS.1",y~sex + car_wt + slgdt_cd),
  c("ph_24h.1",y~sex + car_wt + slgdt_cd),c("driploss.1",y~sex + car_wt + slgdt_cd),
  c("protein.1",y~sex + car_wt + slgdt_cd),c("cook_yield.1",y~sex + car_wt + slgdt_cd),
  c("bf10_22wk.1",y~sex + car_wt + slgdt_cd),c("lma_22wk.1",y~ sex + car_wt + slgdt_cd),
  c("ham.1",y ~ sex + car_wt + slgdt_cd),c("loin.1",y ~ sex + car_wt + slgdt_cd),
  c("fat.1",y~ sex + car_wt + slgdt_cd),c("moisture.1",y ~ sex + car_wt + slgdt_cd), 
  c( "tenderness.1", ~ sex + car_wt + slgdt_cd),c("boston.1", ~ sex + car_wt + slgdt_cd),
  c( "spareribs.1", ~ sex + car_wt + slgdt_cd),c("picnic.1", ~ sex + car_wt + slgdt_cd)
)

# 2. Dataframe with univariate analysis
lsdata<-pheno.msuprp #960 rows

# 3. Validation Analysis 
result<- vector("list", nrow(cont_struc))

# 3.1. Set Dataframe with only Cross-Classified fixed data 
#for checking near-zero-variance factors in training sets (folds)
cont_struc2<-rbind(
c("last_lum.1",y~sex + car_wt + slgdt_cd),c("dress_ptg.1",y~ + car_wt + slgdt_cd),
  c("car_length.1",y~sex + car_wt + slgdt_cd),c("belly.1",y~sex + car_wt + slgdt_cd),
  c("juiciness.1",y~sex + car_wt + slgdt_cd),c("WBS.1",y~sex + car_wt + slgdt_cd),
  c("ph_24h.1",y~sex + car_wt + slgdt_cd),c("driploss.1",y~sex + car_wt + slgdt_cd),
  c("protein.1",y~sex + car_wt + slgdt_cd),c("cook_yield.1",y~sex + car_wt + slgdt_cd),
  c("bf10_22wk.1",y~sex + car_wt + slgdt_cd),c("lma_22wk.1",y~ sex + car_wt + slgdt_cd), 
  c("ham.1",y ~ sex + car_wt + slgdt_cd),c("loin.1",y ~ sex + car_wt + slgdt_cd),
  c("fat.1",y~ sex + car_wt + slgdt_cd),c("moisture.1",y ~ sex + car_wt + slgdt_cd), 
  c( "tenderness.1", ~ sex + car_wt + slgdt_cd),c("boston.1", ~ sex + car_wt + slgdt_cd),
  c( "spareribs.1", ~ sex + car_wt + slgdt_cd),c("picnic.1", ~ sex + car_wt + slgdt_cd)
)
# 3.2. Split data for each trait into 5 FOLDS  ----------------------------
lsdata<- pheno.msuprp

l<- vector("list", nrow(cont_struc))    #list[[trait]] with y_hats per trait after validation
mask<- vector("list", nrow(cont_struc)) #list[[trait]] of 10 elements with masked ids per fold per trait
corfold<-vector("list", nrow(cont_struc)) #list[[trit]] with y_hats per fold
for (i in 1:nrow(cont_struc)) {
  result[[i]]$name<-cont_struc[i,][[1]]
  # For each trait, extract those ids with genotypes + records (full)
  cols<- c(all.vars(cont_struc[i,][[2]]))
  cols[1]<- cont_struc[i,][[1]]
  na.stat <- apply(lsdata[,cols],1,function(row) NA %in% row)
  full<- rownames(lsdata[!na.stat,])
  full<- full[full %in% rownames(G)]
  l[[i]]<- data.frame(id=sort(as.integer(full)),y=NA,yhat=NA)
  rownames(l[[i]])<-l[[i]]$id; l[[i]]$id<-NULL
  l[[i]]$y=lsdata[rownames(l[[i]]),cont_struc[i,][[1]]]
  # Use only cross-classified fixed data for near-zero-variance factor detection
  clss<- lsdata[full, all.vars(cont_struc2[[i]]) ]
  # Mean number of animals in the validation set
  size<- length(full)/nfold
  # Detect near-zero-variance factors in each fold's training set and define final split
  repeat{
    ct = 0; sd = sd + 1
    set.seed(sd)
    split<- split(sample(full), ceiling(seq_along(full)/size))
    for (j in 1:nfold){
      nz<- nearZeroVar(clss[!(full %in% split[[j]]),-1], saveMetrics= TRUE)
      if (sum(nz$nzv*1)>0) {
        print(nz)
      } else {
        ct = ct + 1
      }
    }
    if (ct == nfold) {
      break
    }
  }
  mask[[i]]<- split
}
rm(cont_struc2, cols, na.stat, full, clss, size, split, nz, ct)


# 3.3. Run the Validation for each trait --------------------------------

for (i in 1:nrow(cont_struc)) {
  lsdata<- pheno.msuprp
  gb<-gblup(cont_struc[i,][[1]],lsdata,
            c(cont_struc[i,][[2]]),
            G,pos=c(T,T))
  result[[i]]$varcomp<- varcomp(gb)
  # Get X matrix from gb object #************
  mX<-model.matrix(gb$model$formula,gb$model[all.vars(gb$model$formula)])
  rm(gb)
  dts<-pheno.msuprp
  
 for (j in 1:nfold) {
    lsdata<- dts
    lsdata[mask[[i]][[j]],cont_struc[i,][[1]]]=NA
    gb<-gblup(cont_struc[i,][[1]],lsdata,
              c(cont_struc[i,][[2]]),
              G,pos=c(T,T))
    # Get bhats #************
    bhat<-as.matrix(gb$coefm[1:ncol(mX),1])
    colnames(bhat)<-"Estimates"
    
    # For the MASKED INDIVIDUALS
    test=as.character(sort(as.integer(mask[[i]][[j]])))
    # Get vector of solutions fixed effects and random effect #************
    sol_xb = mX[test,]%*%bhat
    sol_u = G[test,rownames(gb$model$G)] %*%solve(gb$model$G)%*%summary(gb)$uhat
    
    # Correlation by fold 
    yf<-pheno.msuprp%>%filter(id%in%test)%>%select(cont_struc[i,][[1]])
    yf<-yf%>%mutate(solfold=sol_xb + sol_u)
    corfold[[i]][[j]]<-cor(yf[1],yf[2])
    names(corfold)[i]<-cont_struc[i,][[1]]
    
    l[[i]][test,'yhat']= sol_xb + sol_u
  }
  result[[i]]$corr=cor(l[[i]]$y,l[[i]]$yhat)
}



# 3.4. Print the RESULTS---------------------------------------------------------------------*
name=matrix(nrow=2,ncol=1)
for (i in 1:nrow(cont_struc)) {
  name[1:2,1]=result[[i]]$name
  if (rep==1) {
    write.table(cbind(result[[i]]$varcomp, name), file="resu_varcomp_Gibs", append = TRUE, quote=FALSE)
  }
  # result by replicate
   #write.table(cbind(rep, result[[i]]$corr, result[[i]]$name), file="resu_corval_Gibs", 
    #           row.names=FALSE, col.names=FALSE, append=TRUE, quote=FALSE)
   
   # result by fold
   write.table(cbind(rep,names(corfold[i]),seq(corfold[[i]]),corfold[[i]]), file="rfold_G", row.names=FALSE, col.names=FALSE, append=TRUE, quote=FALSE)
   
   }
write.table(sd, file="resu_sd_G", row.names=FALSE, col.names=FALSE, append=TRUE, quote=FALSE)


