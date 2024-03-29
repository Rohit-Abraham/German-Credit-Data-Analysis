library(readxl)
Data <- read_excel("D:/R/GermanCredit_assgt1_F18.xls")
Data <- Data[,-c(1,5,6,7,8,9,10,18)]
Data$AGE <- ifelse(is.na(Data$AGE),mean(Data$AGE,na.rm=TRUE),Data$AGE)
cols <- c("CHK_ACCT","HISTORY","SAV_ACCT","EMPLOYMENT","MALE_DIV","MALE_SINGLE","MALE_MAR_or_WID","GUARANTOR",
          "PRESENT_RESIDENT","REAL_ESTATE","PROP_UNKN_NONE","OTHER_INSTALL","RENT","OWN_RES","JOB","TELEPHONE",
          "FOREIGN","RESPONSE")
Data[cols] <- lapply(Data[cols], factor)
sapply(Data, class)
Data$X <- NULL #Removing the extra variable,X, created during file import.
str(Data)
View(Data)

#Variabe plots for "interesting" variables
library(ggplot2)
plot(mdData$RESPONSE)
dat1 <- data.frame(table(mdData$EMPLOYMENT,mdData$RESPONSE))
names(dat1) <- c("EMPLOYMENT","RESPONSE","Count")
p1 <- ggplot(data=dat1, aes(x=EMPLOYMENT, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat2 <- data.frame(table(mdData$HISTORY,mdData$RESPONSE))
names(dat2) <- c("HISTORY","RESPONSE","Count")
p2 <- ggplot(data=dat2, aes(x=HISTORY, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat3 <- data.frame(table(mdData$JOB,mdData$RESPONSE))
names(dat3) <- c("JOB","RESPONSE","Count")
p3 <- ggplot(data=dat3, aes(x=JOB, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat4 <- data.frame(table(mdData$RENT,mdData$RESPONSE))
names(dat4) <- c("RENT","RESPONSE","Count")
p4 <- ggplot(data=dat4, aes(x=RENT, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat5 <- data.frame(table(mdData$CHK_ACCT,mdData$RESPONSE))
names(dat5) <- c("CHK_ACCT","RESPONSE","Count")
p5 <- ggplot(data=dat5, aes(x=CHK_ACCT, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat6 <- data.frame(table(mdData$OTHER_INSTALL,mdData$RESPONSE))
names(dat6) <- c("OTHER_INSTALL","RESPONSE","Count")
p6 <- ggplot(data=dat6, aes(x=OTHER_INSTALL, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat7 <- data.frame(table(mdData$OWN_RES,mdData$RESPONSE))
names(dat7) <- c("OWN_RES","RESPONSE","Count")
p7 <- ggplot(data=dat7, aes(x=OWN_RES, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
dat8 <- data.frame(table(mdData$SAV_ACCT,mdData$RESPONSE))
names(dat8) <- c("SAV_ACCT","RESPONSE","Count")
p8 <- ggplot(data=dat8, aes(x=SAV_ACCT, y=Count, fill=RESPONSE)) + geom_bar(stat = "identity")
grid.arrange(p1,p2,p3,p4,p5,p6,p7,p8)

#Developing the rpart decision model
library(rpart)
set.seed(123)
ctrl = rpart.control(maxdepth=10)
rpModel1=rpart(RESPONSE ~ ., data=Data, method="class",  parms = list(split = 'information'), 
               control=rpart.control(minsplit = 25,cp = 0.001,maxdepth = 10))
print(rpModel1)

#Prediction, confusion matrix and accuracy
predTrn_whole=predict(rpModel1, data=Data, type='class')
table(pred = predTrn_whole, true=Data$RESPONSE)
mean(predTrn_whole==Data$RESPONSE)

#C50 model
install.packages("C50")
library(C50)
cModel1=C5.0(RESPONSE ~ ., data=Data, method="class")
summary(cModel1)

plot(rpModel1, uniform=TRUE,  main="Decision Tree for German Credit")
text(rpModel1, use.n=TRUE, all=TRUE, cex=.7)
install.packages("rpart.plot")
library(rpart.plot)
rpart.plot::prp(rpModel1, type=2, extra=1)
summary(rpModel1)

predTrn_whole=predict(cModel1, data=Data, type='class')
table(pred = predTrn_whole, true=Data$RESPONSE)
mean(predTrn_whole==Data$RESPONSE)

#splitting the data into training and validation sets, developing a model in the training data
#splitting the data into training and test(validation) sets - 80% for training, rest for validation
nr=nrow(Data)
trnIndex = sample(1:nr, size = round(0.7*nr), replace=FALSE)#get a random 70%sample of row-indices
mdTrn=Data[trnIndex,]   #training data with the randomly selected row-indices
mdTst = Data[-trnIndex,]  #test data with the other row-indices
dim(mdTrn) 
dim(mdTst)

#developing a tree on the training data
set.seed(123)
rpModel2=rpart(RESPONSE ~ ., data=mdTrn, method="class",  parms = list(split = 'gini'), control=ctrl)
summary(rpModel2)

#Obtain the model's predictions, confusion table and accuracy on the training data
predTrn=predict(rpModel2, mdTrn, type='class')
table(pred = predTrn, true=mdTrn$RESPONSE)
mean(predTrn==mdTrn$RESPONSE)

#For confussion table statistics
cm <- table(pred=predict(rpModel2,mdTst, type="class"), true=mdTst$RESPONSE)
n = sum(cm) # number of instances
diag = diag(cm) # number of correctly classified instances per class 
rowsums = apply(cm, 2, sum) # number of instances per class
colsums = apply(cm, 1, sum) # number of predictions per class
p = rowsums / n # distribution of instances over the actual classes
q = colsums / n # distribution of instances over the predicted classes
accuracy = sum(diag) / n 
accuracy
precision = diag / colsums 
precision
recall = diag / rowsums 
recall
f1 = 2 * precision * recall / (precision + recall) 
f1

# Plotting the best obtained model
plot(rpModel2, uniform=TRUE,  main="Decision Tree for German Credit")
text(rpModel2, use.n=TRUE, all=TRUE, cex=.7)
rpart.plot::prp(rpModel2, type=2, extra=1)
summary(rpModel2)


#Classification threshold and its affect on performance of model
CTHRESH=0.7 #if confidence is more than this then 1 else 0

predProbTrn=predict(rpModel1, mdTrn, type='prob')
predTrn = ifelse(predProbTrn[,'1'] >= CTHRESH, '1', '0')
ct = table( pred = predTrn, true=mdTrn$RESPONSE)
mean(predTrn==mdTrn$RESPONSE)

#Calculating ROC and Lift curves using ROCR
install.packages("ROCR")
library(ROCR)
library("gridExtra")
#score test data set
mdTst$score<-predict(rpModel2,type='prob',mdTst)
pred<-prediction(mdTst$score[,2],mdTst$RESPONSE)
perf1 <- performance(pred,"acc","fpr")
pr1 <- plot(perf1)
perf2 <- performance(pred,"acc","tpr")
pr2 <- plot(perf2)
perf3 <- performance(pred,"acc","fnr")
pr3 <- plot(perf3)
perf4 <- performance(pred,"acc","tnr")
pr4 <- plot(perf4)
perf5 <- performance(pred,"tpr","fpr")
pr5 <- plot(perf5)
# plot(perf1)
?par()
grid.arrange(pr1,pr2,pr3,pr4)
?performance
#Cost matrix
costMatrix <- matrix(c(0,1,5, 0), byrow=TRUE, nrow=2)
colnames(costMatrix) <- c('Predict Good','Predict Bad')
rownames(costMatrix) <- c('Actual Good','Actual Bad')
costMatrix

rpTree = rpart(RESPONSE ~ ., data=mdTrn, method="class", parms = list( prior = c(.70,.30), loss = costMatrix, split = "gini"))

#Obtain the model's predictions on the training data
predTrn=predict(rpTree, mdTrn, type='class')
#Confusion table
table(pred = predTrn, true=mdTrn$RESPONSE)
#Accuracy
mean(predTrn==mdTrn$RESPONSE)
#Calculate and apply the theoretical threshold and assess performance*
th = costMatrix[2,1]/(costMatrix[2,1] + costMatrix[1,2])
th

install.packages("dplyr")
library(dplyr)

PROFITVAL=100
COSTVAL=-500
?predict
scoreTst=predict(rpModel2,mdTst, type="prob")[,'1'] 
prLifts=data.frame(scoreTst)
prLifts=cbind(prLifts, mdTst$RESPONSE)
#check what is in prLifts ....head(prLifts)

prLifts=prLifts[order(-scoreTst) ,]  #sort by descending score

#add profit and cumulative profits columns
prLifts<-prLifts %>% mutate(profits=ifelse(prLifts$`mdTst$RESPONSE`=='1', PROFITVAL, COSTVAL), cumProfits=cumsum(profits))
View(prLifts)
plot(prLifts$cumProfits)

#find the score coresponding to the max profit
maxProfit= max(prLifts$cumProfits)
maxProfit_Ind = which.max(prLifts$cumProfits)
maxProfit_score = prLifts$scoreTst[maxProfit_Ind]
print(c(maxProfit = maxProfit, scoreTst = maxProfit_score))

#Random forest
install.packages("randomForest")
library('randomForest')

#for reproducible results, set a specific value for the random number seed
set.seed(123)
?rfImpute
View(mdTrn)
mdTrn.imputed <- rfImpute(RESPONSE ~ ., data=mdTrn)
#develop a model with 200 trees, and obtain variable importance
rfModel = randomForest(factor(RESPONSE) ~ ., data=mdTrn.imputed, ntree=200, importance=TRUE )
#check the model -- see what OOB error rate it gives

#Variable importance
a <- importance(rfModel)
varImpPlot(rfModel)

#Draw the ROC curve for the randomForest model
perf_rf=performance(prediction(predict(rfModel,mdTst, type="prob")[,2], mdTst$RESPONSE), "tpr", "fpr")
plot(perf_rf)