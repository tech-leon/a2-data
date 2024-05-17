---
Title: "Assignment 2"
Name: Leon Wu(10582390)
---


# Install necessary packages for data analysis and visualization
#install.packages(c("tidyverse","ggpubr","moments","scatterplot3d","factoextra","ranger"))
install.packages(c("tidyverse","caret","ranger","ggpubr"))
install.packages(c("rpart","rpart.plot"))



# Load required libraries
library(tidyverse)
library(ggpubr)
# library(moments)
# library(scatterplot3d) 
# library(factoextra)
library(ranger)  #For random forest
library(caret)  #Classification and Regression Training package

library(rpart)
library(rpart.plot)

# Set the working directory
# Note that you may need to change the path to your work directory
# setwd("/Users/leonfuns/Projects/ECU/data-analysis/a2.try")
setwd("/Users/leonfuns/Projects/ECU/data-analysis/a2.try/Data-Logistic-Elastic-Net-Regression-RANDOM-FOREST")
options(scipen = 999) # show all numbers
# getwd()

## ------------------------------------------------------------------
#        Part 1 – General data preparation and cleaning (a)
## ------------------------------------------------------------------

# You may need to change/include the path of your working directory
mydata = read.csv("HealthCareData_2024.csv", stringsAsFactors = TRUE)
dim(mydata)
# 

## ------------------------------------------------------------------
#        Part 1 – General data preparation and cleaning (b)
## ------------------------------------------------------------------
# 
## i. Clean the dataset based on the feedback received for Assignment 1.
summary(mydata)

mydata$AlertCategory = fct_collapse(mydata$AlertCategory, 
  Informational = c("Informational", "Info"))
mydata$NetworkEventType = fct_collapse(mydata$NetworkEventType, 
  PolicyViolation = c("Policy_Violation", "PolicyViolation"))

mydata$NetworkAccessFrequency[mydata$NetworkAccessFrequency == -1] = NA

mydata$ResponseTime[mydata$ResponseTime > 150 ] = NA

summary(mydata)



## ii. merge the ‘Regular’ and ‘Unknown’ categories together.
mydata$NetworkInteractionType = fct_collapse(mydata$NetworkInteractionType, 
                                  Others = c("Regular", "Unknown"))

summary(mydata)
# 

# 
## iii. Standardising dataset.
# Delete the System Access Rate as this column have too many NA data and it will affect 
dat.cleaned = na.omit(mydata[,-9]);dat.cleaned
summary(dat.cleaned)
# 

## ------------------------------------------------------------------
#        Part 1 – General data preparation and cleaning (c)
## ------------------------------------------------------------------
# 
# Separate samples of normal and malicious events
dat.class0 = dat.cleaned %>% filter(Classification == "Normal") # normal
dat.class1 = dat.cleaned %>% filter(Classification == "Malicious") # malicious
# Randomly select 9600 non-malicious and 400 malicious samples using your student
# ID, then combine them to form a working data set
set.seed(10582390)
rows.train0 = sample(1:nrow(dat.class0), size = 9600, replace = FALSE)
rows.train1 = sample(1:nrow(dat.class1), size = 400, replace = FALSE)
# Your 10000 ‘unbalanced’ training samples
train.class0 = dat.class0[rows.train0,] # Non-malicious samples
train.class1 = dat.class1[rows.train1,] # Malicious samples
mydata.ub.train = rbind(train.class0, train.class1)
# Your 19200 ‘balanced’ training samples, i.e. 9600 normal and malicious samples each.
set.seed(10582390)
train.class1_2 = train.class1[sample(1:nrow(train.class1), size = 9600,
  replace = TRUE),]
mydata.b.train = rbind(train.class0, train.class1_2)
# Your testing samples
test.class0 = dat.class0[-rows.train0,]
test.class1 = dat.class1[-rows.train1,]
mydata.test = rbind(test.class0, test.class1)


## ------------------------------------------------------------------
#   Part 2 – Compare the performances of different ML algorithms (a)
## ------------------------------------------------------------------
# 
set.seed(10582390)
models.list1 = c("Logistic Ridge Regression",
  "Logistic LASSO Regression",
  "Logistic Elastic-Net Regression")
models.list2 = c("Classification Tree",
  "Bagging Tree",
  "Random Forest")
myModels = c(sample(models.list1, size = 1),
  sample(models.list2, size = 1))
myModels %>% data.frame
# 

#
#write.csv(mydata.ub.train, "mydata.ub.train.csv")
#write.csv(mydata.b.train, "mydata.b.train.csv")
#write.csv(mydata.test, "mydata.test.csv")
# write.csv(mydata, "mydata.csv")



#A sequence of lambdas
lambdas = 10^seq(-3, 3, length = 100)
alphas = seq(0.1,0.9,by=0.1)

set.seed(10582390)
mod.ridge.b = train(
  Classification~.,
  data = mydata.b.train,
  method = "glmnet",
  preProcess = NULL,
  trControl = trainControl("repeatedcv", number = 10, repeats = 2),
  tuneGrid = expand.grid(alpha = alphas, lambda = lambdas)
)
plot(mod.ridge.b)
mod.ridge.b$bestTune



set.seed(10582390)
mod.ridge.ub = train(
  Classification~.,
  data = mydata.ub.train,
  method = "glmnet",
  preProcess = NULL,
  trControl = trainControl("repeatedcv", number = 10, repeats = 2),
  tuneGrid = expand.grid(alpha = alphas, lambda = lambdas)
)
plot(mod.ridge.ub)
mod.ridge.ub$bestTune



plot(mod.ridge.b)
plot(mod.ridge.ub)



# Model coefficients
coef(mod.ridge.b$finalModel, mod.ridge.b$bestTune$lambda)
coef(mod.ridge.ub$finalModel, mod.ridge.ub$bestTune$lambda)



pred.class.b = predict(mod.ridge.b,new=mydata.test)
pred.class.ub = predict(mod.ridge.ub,new=mydata.test)

cf.b = table(relevel(pred.class.b, ref="Malicious"), 
             relevel(mydata.test$Classification, ref="Malicious"))
cf.ub = table(relevel(pred.class.ub, ref="Malicious"),
             relevel(mydata.test$Classification, ref="Malicious"))

prop.b = round(prop.table(cf.b, 2), digits = 3);prop.b
prop.ub = round(prop.table(cf.ub, 2), digits = 3);prop.ub




confusionMatrix(cf.b,mode="everything")
confusionMatrix(cf.ub,mode="everything")


## ------------------------------------------------------------------
#                   Part 2 – RANDOM FOREST
## ------------------------------------------------------------------

mod.rf.b = ranger(
  Classification~.,
  data = mydata.b.train,
  num.trees = 500,
  mtry = 3,
  respect.unordered.factors = TRUE,
  seed = 10582390,
  importance = "impurity"
)
mod.rf.ub = ranger(
  Classification~.,
  data = mydata.ub.train,
  num.trees = 500,
  mtry = 3,
  respect.unordered.factors = TRUE,
  seed = 10582390,
  importance = "impurity"
)



mod.rf.b
mod.rf.ub



pred.mod.rf.b = predict(mod.rf.b, data = mydata.test);pred.mod.rf.b
pred.mod.rf.ub = predict(mod.rf.ub, data = mydata.test);pred.mod.rf.ub



cm.b = confusionMatrix(
  pred.mod.rf.b$predictions, 
  mydata.test$Classification,
  mode="everything");cm.b
cm.ub = confusionMatrix(
  pred.mod.rf.ub$predictions, 
  mydata.test$Classification,
  mode="everything");cm.ub



grid.rf = expand.grid(num.trees = c(200, 300, 400, 500),
                      mtry = c(3:6),
                      min.node.size = seq(2, 10, 2),
                      replace = c(TRUE, FALSE),
                      sample.fraction = c(0.5, 0.6, 0.7, 0.8, 1),
                      OOB.misclass = NA,
                      test.sens = NA, 
                      test.spec = NA,  
                      test.acc = NA)
dim(grid.rf)
grid.rf



rf.train = function(data.train) {
  for (I in 1:nrow(grid.rf)) {
    rf = ranger(Classification ~ .,
                data = data.train,
                num.trees = grid.rf$num.trees[I],
                mtry = grid.rf$mtry[I],
                min.node.size = grid.rf$min.node.size[I],
                replace = grid.rf$replace[I],
                sample.fraction = grid.rf$sample.fraction[I],
                seed = 10582390,
                respect.unordered.factors = "order")

    grid.rf$OOB.misclass[I] = rf$prediction.error %>% round(5) * 100

    pred.test = predict(rf, data = mydata.test)$predictions

    test.cf = confusionMatrix(relevel(pred.test, ref="Malicious"),
            relevel(mydata.test$Classification, ref="Malicious"))

    prop.cf = test.cf$table %>% prop.table(2)
    grid.rf$test.sens[I] = prop.cf[1,1] %>% round(5)*100      #Sensitivity
    grid.rf$test.spec[I] = prop.cf[2,2] %>% round(5)*100      #Specificity
    grid.rf$test.acc[I] = test.cf$overall[1] %>% round(5)*100 #Accuracy
  }
  return(grid.rf[order(grid.rf$OOB.misclass, decreasing = FALSE)[1:10],])
}



mod.rf.b.t = rf.train(mydata.b.train)



mod.rf.ub.t = rf.train(mydata.ub.train)






# cf.ub = confusionMatrix(rf.pred.ub$predictions, mydata.test$Classification)
test.cf
options(scipen = 999)
mod.ridge.b
plot(mod.ridge.b$bestTune)
plot(lambdas)
plot(alphas)

ggplot




# df = data.frame(Actual = mydata.test$Classification, Predicted = pred.class.b);df

ggplot(df,aes(x=Predicted,y=Actual))+
  geom_point(size=3,colour="steelblue")+
  xlim(0,10000)+
  #Reference line given by y=x, i.e. slope=1 and intercept=0
  geom_abline(slope=1,
              intercept=0,
              colour="red",  #Colour of the line
              linetype=2) + #Dotted line  
  theme_minimal()













df = data.frame(Actual = mydata.test$Classification, Predicted = pred.class.b);df

ggplot(df,aes(x=Predicted,y=Actual))+
  geom_point(size=3,colour="steelblue")+

  #Reference line given by y=x, i.e. slope=1 and intercept=0
  geom_abline(slope=1,
              intercept=0,
              colour="red",  #Colour of the line
              linetype=2) + #Dotted line  
  theme_minimal()





df = data.frame(Actual = mydata.test$Classification, Predicted = pred.class.b);df

ggplot(df,aes(x=Predicted,y=Actual))+
  geom_point(size=3,colour="steelblue")+
  xlim(0,10000)+
  #Reference line given by y=x, i.e. slope=1 and intercept=0
  geom_abline(slope=1,
              intercept=0,
              colour="red",  #Colour of the line
              linetype=2) + #Dotted line  
  theme_minimal()



