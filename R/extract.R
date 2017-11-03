#               name       desc  range minRange maxRange
#P7    530/30 Blue-A CX43 AF488 262144   -94.77   262143
#desc will described the conjugate of interest, except if it is a viability dye such as "7AAD L/D" or "DAPI"
#all teh other desc shoudl be <NA>
library(flowFP)
library(cytovasTools)

plot_titrations<-function(filedir,manifest_file){
  manifest<-read.table(manifest_file,header = TRUE)
  manifest$file<-as.character(manifest$file)
  manifest<-manifest[order(manifest$titration),]
  myFlowSet<-read.flowSet(files=paste(filedir,manifest$file,sep="/"))
  pData(myFlowSet)$titration<-manifest$titration
  
  flowparams<-parameters(myFlowSet[[1]])$desc
  nullparams<-which(is.na(flowparams))
  viabilities<-grep("7AAD|DAPI",flowparams)
  badparams<-sort(as.vector(c(nullparams,viabilities)))
  goodparams<-flowparams[-badparams][[1]]
  goodparams_index<-as.numeric(which(flowparams==goodparams))
  #CX43 is a cardiomyocyte marker
  #for cell titers
  #gating of fsc and ssc and  may be necessary
  myFlowSetTx<-doTransform(myFlowSet,cols=goodparams_index,method="biexp")
  #the name of the parameter of interest, e.g. "530/30 Blue-A"
  titrated_parameter<-colnames(myFlowSetTx)[goodparams_index]
  #attach this to the set, just in case it is needed
  pData(myFlowSetTx)$conjugate<-goodparams
  pData(myFlowSetTx)$titrated_parameter<-titrated_parameter
  myBigFlowFrame<-as(myFlowSet,"flowFrame")
  offsetJiggle<-rep(seq(1:5),times=as.numeric(fsApply(myFlowSet,nrow)[,1]))
  offsetJiggle<-offsetJiggle+rnorm(length(offsetJiggle),mean=0,sd=.125)
  myBigFlowFrame<-append_parameter(myBigFlowFrame,offsetJiggle,"offset")
  cytovasTools::pplot(myBigFlowFrame,plist = c("offset",titrated_parameter),tx="dsljkflk")
}

# par(mfrow = c(1, nrow(manifest)))
# for(i in 1:nrow(manifest)){
#   pplot(myFlowSetTx[[i]],plist=c("SSC-A",titrated_parameter),tx="linear",main=paste(manifest[i,"titration"],"µg/µl"))
# }
# par(mfrow=c(1,1))
# https://expertcytometry.com/stain-sensitivity-index/
# Telford et al. (2009)
# Staining Index = ((medianpos-medianneg)/((84%neg-medianneg)*0.995) 
# Stain Index = (Median of Positive - Median of Negative) / (SD of Negative * 2)
#              MFI(positive population) - MFI(negative population) / 2xSD(negative population)
#              MFI = median fluorescence intensity 
#              SD = standard deviation

#get rowcounts for each member of flowset
#construct random offset vector 1+/- (1,2,3,4,5) +- rnorm(0,.2)
#assign it as a parameter exprs(ff)<-cbind(exprs(ff),thevector)

append_parameter<-function(ff,param,param_name){
  tmpmat = exprs(ff)
  tmpmat = cbind (tmpmat, param)
  dimnames(tmpmat)[[2]][length(dimnames(tmpmat)[[2]])]<-param_name
  pdata = pData(parameters(ff))
  pdata = rbind(pdata, list(param_name, "<NA>", 262144, 0, floor(max(param))+1))
  rownames(pdata)[nrow(pdata)] = param_name
  res.ff = flowFrame (tmpmat, parameters=as (pdata, "AnnotatedDataFrame"))
  return(res.ff)
}

get_point_of_lowest_density_from_flowset<-function(distribution){
  d<-density(distribution)
  i = which.max(d$y)
  return(d$x[i])
}

get_stain_index_telford<-function(flowFrameExprs,parameter){
  distribution<-flowFrameExprs[,parameter]
  dividing_line<-get_point_of_lowest_density_from_flowset(distribution)
  background<-distribution[distribution<dividing_line]
  signal<-distribution[distribution>=dividing_line]
  stain_index<-(median(signal)-median(background)) / (as.numeric(quantile(background,.84))-median(background)*0.995)
  
  return(c(telford_stain_index=stain_index,positive_count=length(signal),events=length(distribution),positive_median=median(signal),negative_median=median(background),on_the_rail=sum(distribution==max(distribution))))
}

get_titration_table<-function(manifest,flowset,parameter){
  fstable<-fsApply(flowset,function(x){get_stain_index_telford(x,parameter)},simplify=TRUE,use.exprs = TRUE)
  return(cbind(manifest,fstable))
}