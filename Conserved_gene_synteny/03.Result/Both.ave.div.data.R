library(ggplot2)
library(splines)

pdf("Both.ave.div.data.pdf")
data<- read.table("./Both.ave.div.data",header=T)
qplot(Divergence,Percentage,data=data,geom=c("point"),xlab="Divergence Time (Myr)",ylab="Percentage",colour=Clade,alpha=I(1/2),shape=Clade) + geom_smooth(method="lm")#, formula = y ~ ns(x,2))
