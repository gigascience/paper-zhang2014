library(ggplot2)
num <- read.table("./Both.ave.div.data",header=T)
pdf("Boxplot.ave.div.data.pdf")
qplot(Clade,Percentage, data=num, geom="boxplot",colour = Clade,alpha=I(1/100),size =I(1.2),ylab="Percentage") + theme(axis.line=element_line()) + theme(panel.background = element_blank()) + theme(panel.grid.major = element_blank()) + theme(panel.grid.minor = element_blank()) 
