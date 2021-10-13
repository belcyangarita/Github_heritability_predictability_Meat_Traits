# Variance components and Heritability of meat quality traits in pigs 

> To compare three specifications of the covariance structure of an experimental pig population to estimate additive variances, heritabilities and predictive abilities for 20 meat quality an carcass traits. 

## Table of contents
1. [General information](#general-information)
2. [Sources](#sources)
3. [Technologies](#technologies)
4. [Run examples](#examples)
5. [Acknowledgements](#Acknowledgements])
6. [Contact](#contact)

## General information
This repository contains codes and data needed to reproduce the results in the estimating of variance components and heritability by fitting three different mixed models on meat quality andcarcass traits. The models differ in the source of information for building their covariance matrices. In additon, the performance of the models was compared by estimating their predictive ability by means of a 5-fold cross-validation.

## Sources
Based on the work from ```Angarita Barajas et al.```

## Technologies
1. [R](https://www.r-project.org/) - version 4.0.2

#### Libraries
* tidyverse - version 1.2.1
* regress - version 1.3.31
* gwaR - version 1.0
* car - version 3.0.9
* Matrix - version 1.2-18
* caret - version 6.0-86
* MASS - version 7.3-51.6
* ggplot2 - version 3.3.2
* gridExtra - version 2.3
* kableExtra - version 1.1.0



## Run Examples
The **global workflow** to reproduce the results is:

1. Comparison of relationship matrices. 
2. Estimation of variance compontents and heritability of each meat quality and carcass trait.
3. Estimation of predictive ability of the models by means 5-fold cross-validation.
4. Tukey's multiple compariso to test the significance differences between the predictive abilities of the models. 


### Features
The repository [Github_heritability_predictability_Meat_Traits](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits) contains the principal data file and codes necesaries, which are named with numeric order (1,2, etc) to refer to the execution order of each one.

### Data file:

#### Input files 

1. Data file with phenotypes and fixed effects to fit the models
* [msuprphenofile.Rdata](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
2. Data files with pedigree and genomic Relationship matrices
* [A_mat.Rdata](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
* [Gibd_mat.Rdata](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
* [Gibs_mat.Rdata](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)

#### R Code files

* [1_Comparison_relationship_matrices.Rmd](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
* [2_Varcomp_Heritabily_meat_traits.Rmd](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
* [3_crossval_predictability_meat_traits.R](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)
* [4_results_crossval.Rmd](https://github.com/belcyangarita/Github_heritability_predictability_Meat_Traits)

The files within the above mentioned folder have the follow exentions:
* *.Rmd*: R Markdown code to generate the report with the results in html format
* *.R*: R code workflow, used to estimate the predictive ability and generate the outputs objects (*resu_corval_x*) 

#### Output files

* *resu_corval_x*: 3 text files one for each relationship matrix, each one have three columns: replicate, predictive ability and name of trait


### Run workflow

1. To obtain the results in the same order as it are reported in ```Angarita Barajas et al.```, the code files must be execute in according to order as it appear in the folder, althought each code can be execute the individual way.  


## Acknowledgements
> This research was founded by Agencia Nacional de Promoción Científica y Tecnológica, Argentina, PICT-2018-04497 and by National Institute of Food and Agriculture Award no. 2021-67021-34150 to Juan P. Steibel. Computer resources were provided by the Michigan State University High Performance Computing Center (HPCC).
