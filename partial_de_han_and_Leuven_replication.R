rm(list=ls())
#############################################
#instructions: save 'NLSY79_analysis_ed' in some directory, and then paste directory in the below:

my.directory<-'C:\\Users\\Joe Spearing\\Documents\\labour_econ'



####################################
# global libraries used everywhere #
####################################

#This code checks you have the appropriate packages, and installs them if not

pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
  return("OK")
}


global.libraries <- c("foreign","haven","ggplot2")

results <- sapply(as.list(global.libraries), pkgTest)


#############################################
library(foreign)
library(haven)
library(ggplot2)


setwd(my.directory)
data<-read_dta("NLSY79_analysis_ed.dta")

#drop NAs for head start
data<-subset(data,is.na(headstart)==FALSE)
#Also drop the data before 1964
data<-subset(data,birthyear>=64)

#################################
#effect on high school completion: worked example
#Get: P(D=1), P(D=0), HS(0,D=0), HS(1, d=1)
#MTS 
#conditional MTS
#MIV
#MIV and MTS

HS.data<-subset(data, headstart==1)
no.HS.data<-subset(data, headstart==0)
share.HS<-nrow(HS.data)/nrow(data)
share.no.HS<-nrow(no.HS.data)/nrow(data)
hsgrad.HS<-sum(HS.data$gradesm>=12)/nrow(HS.data)
hsgrad.no.HS<-sum(no.HS.data$gradesm>=12)/nrow(no.HS.data)

#untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
#E(H(0)|D=1) must be between 1 and 0.
max.untreated<-share.no.HS*hsgrad.no.HS+share.HS
min.untreated<-share.no.HS*hsgrad.no.HS

#treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
#E(H(1)|D=0) must be between 1 and 0.
max.treated<-share.HS*hsgrad.HS+(1-share.HS)
min.treated<-share.HS*hsgrad.HS

#MTS assumption: E(H(1)|D=0)>E(H(1)|D=1)
#E(H(0)|D=0)>E(H(0)|D=1)
#untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
MTS.max.untreated<-share.no.HS*hsgrad.no.HS+share.HS*hsgrad.no.HS
MTS.min.untreated<-share.no.HS*hsgrad.no.HS

#treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
MTS.max.treated<-share.HS*hsgrad.HS+(1-share.HS)
MTS.min.treated<-share.HS*hsgrad.HS+(1-share.HS)*hsgrad.HS

#########################################
#with the MIV

#now do by parental education which runs from 1 to 6
#col 1: share with this level of parental education
#col 2: max non-HS participants
#col 3: min non-HS participants
#col 4: max HS participants
#col 5: min HS participants
#col 6: max non-HS participants with MTS
#col 7: min non-HS participants with MTS
#col 8: max HS participants with MTS
#col 9: min HS participants with MTS

MIV.calcs<-matrix(data=0,nrow=6,ncol=9)
count.to.six<-seq(from=1,to=6,by=1)
#for each education level
for (val in count.to.six){
  #find out:
  #what percentage of people's parents have this level of education (share.educ)
  #what percentage within this group (share.headstart)
  #what percentage within each treatment-education group have highschool (share.HS.hsgrad, share.noHS.hsgrad)
  educ.data<-subset(data, mivparent==val)
  share.educ<-nrow(educ.data)/nrow(data)
  MIV.calcs[val,1]<-share.educ
  share.headstart<-sum(educ.data$headstart==1)/nrow(educ.data)
  educ.HS.data<-subset(educ.data, headstart==1)
  share.HS.hsgrad<-sum(educ.HS.data$gradesm>=12)/nrow(educ.HS.data)
  educ.HS.data<-subset(educ.data, headstart==0)
  share.noHS.hsgrad<-sum(educ.HS.data$gradesm>=12)/nrow(educ.HS.data)
  
  #max HS amongst non-participants
  MIV.calcs[val,2]<-(1-share.headstart)*share.noHS.hsgrad+share.headstart
  #and min
  MIV.calcs[val,3]<-(1-share.headstart)*share.noHS.hsgrad
  
  #max HS among participants
  MIV.calcs[val,4]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
  #and min
  MIV.calcs[val,5]<-share.headstart*share.HS.hsgrad
    
  #max non-participation with MTS
  MIV.calcs[val,6]<-share.noHS.hsgrad
  #and min
  MIV.calcs[val,7]<-(1-share.headstart)*share.noHS.hsgrad
  
  #max HS participation with MTS
  MIV.calcs[val,8]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
  #and min
  MIV.calcs[val,9]<-share.HS.hsgrad
    
}

#normalise so that the total share sums to 1
MIV.calcs[,1]<-MIV.calcs[,1]/sum(MIV.calcs[,1])

#for each education level, the min should be at least education less than this
count.to.six<-seq(from=2,to=6,by=1)
for (val in count.to.six){
  MIV.calcs[val,3]<-max(MIV.calcs[val,3],MIV.calcs[val-1,3])
  MIV.calcs[val,5]<-max(MIV.calcs[val,5],MIV.calcs[val-1,5])
}
#And the max should be less than the education higher than this
count.to.five<-seq(from=1,to=5,by=1)
for (val in count.to.five){
  val<-6-val
MIV.calcs[val,2]<-min(MIV.calcs[val,2],MIV.calcs[val+1,2])
MIV.calcs[val,4]<-min(MIV.calcs[val,4],MIV.calcs[val+1,4])
}

#now combine then to get conditional MIV
max.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,2]
min.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,3]

max.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,4]
min.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,5]

#and conditional MTS
max.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
min.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]

max.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
min.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]

#now to combine MTS and MIV
#for each education level, the min should be at least education less than this
count.to.six<-seq(from=2,to=6,by=1)
for (val in count.to.six){
  MIV.calcs[val,9]<-max(MIV.calcs[val,9],MIV.calcs[val-1,9])
  MIV.calcs[val,7]<-max(MIV.calcs[val,7],MIV.calcs[val-1,7])
}
#And the max should be less than the education higher than this
count.to.five<-seq(from=1,to=5,by=1)
for (val in count.to.five){
  val<-6-val
  MIV.calcs[val,8]<-min(MIV.calcs[val,8],MIV.calcs[val+1,8])
  MIV.calcs[val,6]<-min(MIV.calcs[val,6],MIV.calcs[val+1,6])
}

#and conditional MIV-MTS
max.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
min.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]

max.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
min.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]

#This produces Figure 8 of the paper

#plots
plot.data<-as.data.frame(matrix(nrow=5,ncol=5))
colnames(plot.data)<-c('x_axis','min_untreated','max_untreated','min_treated','max_treated')
  plot.data[1,2]<-min.untreated
  plot.data[2,2]<-min.miv.untreated
  plot.data[3,2]<-MTS.min.untreated
  plot.data[4,2]<-min.condMTS.untreated
  plot.data[5,2]<-min.MIVMTS.untreated
  plot.data[1,4]<-min.treated
  plot.data[2,4]<-min.miv.treated
  plot.data[3,4]<-MTS.min.treated
  plot.data[4,4]<-min.condMTS.treated
  plot.data[5,4]<-min.MIVMTS.treated
  
  plot.data[1,3]<-max.untreated
  plot.data[2,3]<-max.miv.untreated
  plot.data[3,3]<-MTS.max.untreated
  plot.data[4,3]<-max.condMTS.untreated
  plot.data[5,3]<-max.MIVMTS.untreated
  plot.data[1,5]<-max.treated
  plot.data[2,5]<-max.miv.treated
  plot.data[3,5]<-MTS.max.treated
  plot.data[4,5]<-max.condMTS.treated
  plot.data[5,5]<-max.MIVMTS.treated
  
  #get the x-axis right
  plot.data[,1]<-as.character(c('NOA','MIV','MTS','cond_MTS','MIV-MTS'))
  level.order<-c('NOA','MIV','MTS','cond_MTS','MIV-MTS')
  
png('figure_6_left.png')

ggplot(plot.data, aes(x=factor(x_axis,level=level.order)))+
               geom_errorbar(aes(ymin=min_untreated, ymax=max_untreated), width=0.2,
                          position=position_dodge(0.05))+
  scale_y_continuous(limits = c(0,1))+
  xlab('')+ylab('E(HS(h)')
dev.off()

png('figure_6_right.png')
ggplot(plot.data, aes(x=factor(x_axis,level=level.order)))+
  geom_errorbar(aes(ymin=min_treated, ymax=max_treated), width=0.2,
                position=position_dodge(0.05))+
  scale_y_continuous(limits = c(0,1))+
  xlab('')+ylab('E(HS(h)')
dev.off()
#####
#okay, so this seems to work (can replicate figure 6)
#need to turn this into a function of the number

#input.vector<-c('var_name','value')

MIV_MTS_bounds_educ<-function(value){
  #value<-30
  
  HS.data<-subset(data, headstart==1)
  no.HS.data<-subset(data, headstart==0)
  share.HS<-nrow(HS.data)/nrow(data)
  share.no.HS<-nrow(no.HS.data)/nrow(data)
  hsgrad.HS<-sum(HS.data$gradesm>value)/nrow(HS.data)
  hsgrad.no.HS<-sum(no.HS.data$gradesm>value)/nrow(no.HS.data)
  
  #untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
  #E(H(0)|D=1) must be between 1 and 0.
  max.untreated<-share.no.HS*hsgrad.no.HS+share.HS
  min.untreated<-share.no.HS*hsgrad.no.HS
  
  #treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
  #E(H(1)|D=0) must be between 1 and 0.
  max.treated<-share.HS*hsgrad.HS+(1-share.HS)
  min.treated<-share.HS*hsgrad.HS
  
  #MTS assumption: E(H(1)|D=0)>E(H(1)|D=1)
  #E(H(0)|D=0)>E(H(0)|D=1)
  #untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
  MTS.max.untreated<-share.no.HS*hsgrad.no.HS+share.HS*hsgrad.no.HS
  MTS.min.untreated<-share.no.HS*hsgrad.no.HS
  
  #treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
  MTS.max.treated<-share.HS*hsgrad.HS+(1-share.HS)
  MTS.min.treated<-share.HS*hsgrad.HS+(1-share.HS)*hsgrad.HS
  
  #########################################
  #with the MIV
  
  #now do by parental education which runs from 1 to 6
  #col 1: share with this level of parental education
  #col 2: max non-HS participants
  #col 3: min non-HS participants
  #col 4: max HS participants
  #col 5: min HS participants
  #col 6: max non-HS participants with MTS
  #col 7: min non-HS participants with MTS
  #col 8: max HS participants with MTS
  #col 9: min HS participants with MTS
  
  MIV.calcs<-matrix(data=0,nrow=6,ncol=9)
  count.to.six<-seq(from=1,to=6,by=1)
  #for each education level
  for (val in count.to.six){
    #find out:
    #what percentage of people's parents have this level of education (share.educ)
    #what percentage within this group (share.headstart)
    #what percentage within each treatment-education group have highschool (share.HS.hsgrad, share.noHS.hsgrad)
    educ.data<-subset(data, mivparent==val)
    share.educ<-nrow(educ.data)/nrow(data)
    MIV.calcs[val,1]<-share.educ
    share.headstart<-sum(educ.data$headstart==1)/nrow(educ.data)
    educ.HS.data<-subset(educ.data, headstart==1)
    share.HS.hsgrad<-sum(educ.HS.data$gradesm>value)/nrow(educ.HS.data)
    educ.HS.data<-subset(educ.data, headstart==0)
    share.noHS.hsgrad<-sum(educ.HS.data$gradesm>value)/nrow(educ.HS.data)
    
    #max HS amongst non-participants
    MIV.calcs[val,2]<-(1-share.headstart)*share.noHS.hsgrad+share.headstart
    #and min
    MIV.calcs[val,3]<-(1-share.headstart)*share.noHS.hsgrad
    
    #max HS among participants
    MIV.calcs[val,4]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
    #and min
    MIV.calcs[val,5]<-share.headstart*share.HS.hsgrad
    
    #max non-participation with MTS
    MIV.calcs[val,6]<-share.noHS.hsgrad
    #and min
    MIV.calcs[val,7]<-(1-share.headstart)*share.noHS.hsgrad
    
    #max HS participation with MTS
    MIV.calcs[val,8]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
    #and min
    MIV.calcs[val,9]<-share.HS.hsgrad
    
  }
  
  #normalise so that the total share sums to 1
  MIV.calcs[,1]<-MIV.calcs[,1]/sum(MIV.calcs[,1])
  
  #for each education level, the min should be at least education less than this
  count.to.six<-seq(from=2,to=6,by=1)
  for (val in count.to.six){
    MIV.calcs[val,3]<-max(MIV.calcs[val,3],MIV.calcs[val-1,3])
    MIV.calcs[val,5]<-max(MIV.calcs[val,5],MIV.calcs[val-1,5])
  }
  #And the max should be less than the education higher than this
  count.to.five<-seq(from=1,to=5,by=1)
  for (val in count.to.five){
    val<-6-val
    MIV.calcs[val,2]<-min(MIV.calcs[val,2],MIV.calcs[val+1,2])
    MIV.calcs[val,4]<-min(MIV.calcs[val,4],MIV.calcs[val+1,4])
  }
  
  #now combine then to get conditional MIV
  max.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,2]
  min.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,3]
  
  max.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,4]
  min.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,5]
  
  #and conditional MTS
  max.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
  min.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]
  
  max.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
  min.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]
  
  #now to combine MTS and MIV
  #for each education level, the min should be at least education less than this
  count.to.six<-seq(from=2,to=6,by=1)
  for (val in count.to.six){
    MIV.calcs[val,9]<-max(MIV.calcs[val,9],MIV.calcs[val-1,9])
    MIV.calcs[val,7]<-max(MIV.calcs[val,7],MIV.calcs[val-1,7])
  }
  #And the max should be less than the education higher than this
  count.to.five<-seq(from=1,to=5,by=1)
  for (val in count.to.five){
    val<-6-val
    MIV.calcs[val,8]<-min(MIV.calcs[val,8],MIV.calcs[val+1,8])
    MIV.calcs[val,6]<-min(MIV.calcs[val,6],MIV.calcs[val+1,6])
  }
  
  #and conditional MIV-MTS
  max.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
  min.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]
  
  max.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
  min.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]
  
  output.vector<-c(max.MIVMTS.untreated,min.MIVMTS.untreated,max.MIVMTS.treated,min.MIVMTS.treated)
  return(output.vector)
}

#check this works
MIV_MTS_bounds_educ(14)
#It does!

#Alright, so...
#Want min and max of the treated and untreated group for each education level
education.levels<-seq(from=8,to=max(data[,'gradesm']),by=1)
educ.CDF.results<-matrix(data=0,nrow=length(education.levels),ncol=5)
#the first col is just education levels
educ.CDF.results[,1]<-education.levels
#then for each education level
for (val in education.levels){
  educ.CDF.results[val-7,2:5]<-MIV_MTS_bounds_educ(educ.CDF.results[val-7,1])
}
#We want 1-this
educ.CDF.results[,2:5]<-1-educ.CDF.results[,2:5]
#name the columns
colnames(educ.CDF.results)<-c('x_axis','max_untreated','min_untreated','max_treated','min_treated')
educ.CDF.results<-as.data.frame(educ.CDF.results)

#This returns figure 9 top left panel
png('figure_9_top_left.png')
ggplot(educ.CDF.results,aes(x=x_axis))+
  geom_ribbon(aes(ymin = max_untreated, ymax = min_untreated), fill = "blue")+
  geom_ribbon(aes(ymin = max_treated, ymax = min_treated), fill = "red")+
 xlab('Years of education')
dev.off()

########################################################
#Same for wages
#subset to kill nas
data<-subset(data,is.na(wage1994)==FALSE)


MIV_MTS_bounds_wages<-function(value){
  #value<-300
  
  HS.data<-subset(data, headstart==1)
  no.HS.data<-subset(data, headstart==0)
  share.HS<-nrow(HS.data)/nrow(data)
  share.no.HS<-nrow(no.HS.data)/nrow(data)
  hsgrad.HS<-sum(HS.data$wage1994>value)/nrow(HS.data)
  hsgrad.no.HS<-sum(no.HS.data$wage1994>value)/nrow(no.HS.data)
  
  #untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
  #E(H(0)|D=1) must be between 1 and 0.
  max.untreated<-share.no.HS*hsgrad.no.HS+share.HS
  min.untreated<-share.no.HS*hsgrad.no.HS
  
  #treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
  #E(H(1)|D=0) must be between 1 and 0.
  max.treated<-share.HS*hsgrad.HS+(1-share.HS)
  min.treated<-share.HS*hsgrad.HS
  
  #MTS assumption: E(H(1)|D=0)>E(H(1)|D=1)
  #E(H(0)|D=0)>E(H(0)|D=1)
  #untreated is P(D=0)E(H(0)|D=0)+P(D=1)E(H(0)|D=1)
  MTS.max.untreated<-share.no.HS*hsgrad.no.HS+share.HS*hsgrad.no.HS
  MTS.min.untreated<-share.no.HS*hsgrad.no.HS
  
  #treated is P(D=0)E(H(1)|D=0)+P(D=1)E(H(1)|D=1)
  MTS.max.treated<-share.HS*hsgrad.HS+(1-share.HS)
  MTS.min.treated<-share.HS*hsgrad.HS+(1-share.HS)*hsgrad.HS
  
  #########################################
  #with the MIV
  
  #now do by parental education which runs from 1 to 6
  #col 1: share with this level of parental education
  #col 2: max non-HS participants
  #col 3: min non-HS participants
  #col 4: max HS participants
  #col 5: min HS participants
  #col 6: max non-HS participants with MTS
  #col 7: min non-HS participants with MTS
  #col 8: max HS participants with MTS
  #col 9: min HS participants with MTS
  
  MIV.calcs<-matrix(data=0,nrow=6,ncol=9)
  count.to.six<-seq(from=1,to=6,by=1)
  #for each education level
  for (val in count.to.six){
    #find out:
    #what percentage of people's parents have this level of education (share.educ)
    #what percentage within this group (share.headstart)
    #what percentage within each treatment-education group have highschool (share.HS.hsgrad, share.noHS.hsgrad)
    educ.data<-subset(data, mivparent==val)
    share.educ<-nrow(educ.data)/nrow(data)
    MIV.calcs[val,1]<-share.educ
    share.headstart<-sum(educ.data$headstart==1)/nrow(educ.data)
    educ.HS.data<-subset(educ.data, headstart==1)
    share.HS.hsgrad<-sum(educ.HS.data$wage1994>value)/nrow(educ.HS.data)
    educ.HS.data<-subset(educ.data, headstart==0)
    share.noHS.hsgrad<-sum(educ.HS.data$wage1994>value)/nrow(educ.HS.data)
    
    #max HS amongst non-participants
    MIV.calcs[val,2]<-(1-share.headstart)*share.noHS.hsgrad+share.headstart
    #and min
    MIV.calcs[val,3]<-(1-share.headstart)*share.noHS.hsgrad
    
    #max HS among participants
    MIV.calcs[val,4]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
    #and min
    MIV.calcs[val,5]<-share.headstart*share.HS.hsgrad
    
    #max non-participation with MTS
    MIV.calcs[val,6]<-share.noHS.hsgrad
    #and min
    MIV.calcs[val,7]<-(1-share.headstart)*share.noHS.hsgrad
    
    #max HS participation with MTS
    MIV.calcs[val,8]<-share.headstart*share.HS.hsgrad+(1-share.headstart)
    #and min
    MIV.calcs[val,9]<-share.HS.hsgrad
    
  }
  
  #normalise so that the total share sums to 1
  MIV.calcs[,1]<-MIV.calcs[,1]/sum(MIV.calcs[,1])
  
  #for each education level, the min should be at least education less than this
  count.to.six<-seq(from=2,to=6,by=1)
  for (val in count.to.six){
    MIV.calcs[val,3]<-max(MIV.calcs[val,3],MIV.calcs[val-1,3])
    MIV.calcs[val,5]<-max(MIV.calcs[val,5],MIV.calcs[val-1,5])
  }
  #And the max should be less than the education higher than this
  count.to.five<-seq(from=1,to=5,by=1)
  for (val in count.to.five){
    val<-6-val
    MIV.calcs[val,2]<-min(MIV.calcs[val,2],MIV.calcs[val+1,2])
    MIV.calcs[val,4]<-min(MIV.calcs[val,4],MIV.calcs[val+1,4])
  }
  
  #now combine then to get conditional MIV
  max.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,2]
  min.miv.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,3]
  
  max.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,4]
  min.miv.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,5]
  
  #and conditional MTS
  max.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
  min.condMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]
  
  max.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
  min.condMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]
  
  #now to combine MTS and MIV
  #for each education level, the min should be at least education less than this
  count.to.six<-seq(from=2,to=6,by=1)
  for (val in count.to.six){
    MIV.calcs[val,9]<-max(MIV.calcs[val,9],MIV.calcs[val-1,9])
    MIV.calcs[val,7]<-max(MIV.calcs[val,7],MIV.calcs[val-1,7])
  }
  #And the max should be less than the education higher than this
  count.to.five<-seq(from=1,to=5,by=1)
  for (val in count.to.five){
    val<-6-val
    MIV.calcs[val,8]<-min(MIV.calcs[val,8],MIV.calcs[val+1,8])
    MIV.calcs[val,6]<-min(MIV.calcs[val,6],MIV.calcs[val+1,6])
  }
  
  #and conditional MIV-MTS
  max.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,6]
  min.MIVMTS.untreated<-t(MIV.calcs[,1])%*%MIV.calcs[,7]
  
  max.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,8]
  min.MIVMTS.treated<-t(MIV.calcs[,1])%*%MIV.calcs[,9]
  
  output.vector<-c(max.MIVMTS.untreated,min.MIVMTS.untreated,max.MIVMTS.treated,min.MIVMTS.treated)
  return(output.vector)
}

#check this works
1-MIV_MTS_bounds_wages(50)


#Alright, so...
#Want min and max of the treated and untreated group for each education level
wage.levels<-seq(from=min(data[,'wage1994']),to=max(data[,'wage1994']),by=0.01)
wage.CDF.results<-matrix(data=0,nrow=length(wage.levels),ncol=5)
#the first col is just education levels
wage.CDF.results[,1]<-wage.levels
#then for each education level
for (val in wage.levels){
  wage.CDF.results[1+val-min(data[,'wage1994']),2:5]<-MIV_MTS_bounds_wages(val)
}
#I think we want 1-this
wage.CDF.results[,2:5]<-1-wage.CDF.results[,2:5]

colnames(wage.CDF.results)<-c('x_axis','max_untreated','min_untreated','max_treated','min_treated')
wage.CDF.results<-as.data.frame(wage.CDF.results)

#This data produces figure 9 bottom left
png('figure_9_bottom_left.png')
ggplot(wage.CDF.results,aes(x=x_axis))+
  geom_ribbon(aes(ymin = max_untreated, ymax = min_untreated), fill = "blue")+
  geom_ribbon(aes(ymin = max_treated, ymax = min_treated), fill = "red")
dev.off()

