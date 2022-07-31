library(readr) #Library needed to read csv file
#install.packages("corrplot")
library(corrplot) #Installed library for plotting corelation matrix
#install.packages("randomForest")
library(randomForest) #Installed library for machine learning random forest algorithm
#install.packages("dplyr")
library(dplyr) #Library needed for data manipulation
#install.packages("Boruta")
library(Boruta) #Installed library used to preform feature selection for random forest algorithm
#install.packages("ggplot2")
library(ggplot2) #Installed library used for data visualization

# Dataset is downloaded from: https://www.kaggle.com/datasets/saurabhshahane/northern-hemisphere-horizontal-photovoltaic?select=Pasion+et+al+dataset.csv
# Provided dataset represents data about power output of horizontal photovoltaic panels located at 12 Northern hemisphere sites over 14 months.
# *Note: This dataset accompanies the paper \"Machine Learning Modeling of Horizontal Photovoltaics Using Weather and Location Data\" submitted to the Journal of Renewable Energy
# Based on data structure we'll try to predict whether monthly power output of our solar system will be enough for household in given location.

data <- read.csv("Desktop/Praktikum\ -\ Napredno\ softversko\ inženjerstvo/Ispit/Final/Pasion et al dataset.csv")

#Now some of data isn't necessary for prediction power output so we just remove those columns

data <- data %>% select(-Date)
data <- data %>% select(-Time)
data <- data %>% select(-Hour)
data <- data %>% select(-Latitude)
data <- data %>% select(-Longitude)
data <- data %>% select(-Altitude)
data <- data %>% select(-YRMODAHRMI)
data <- data %>% select(-Season)

head(data, 10) #Let's now see our data

colSums(is.na(data)) #We don't have missing values in our data, no processing needed

df = data.frame(
  location = data$Location, #Location of measurement
  month = data$Month, #Month of measurement
  humidity = data$Humidity, #Recorded humidity (%)
  temp = data$AmbientTemp, #Recorded ambient solar panel temperature (°C)
  wind_speed = data$Wind.Speed, #Recorded wind speed (km/h)
  visibility = data$Visibility, #Recorded visibility (km)
  pressure = data$Pressure, #Recorded atmospheric pressure (millibar)
  power_output = data$PolyPwr, #Recorded power output (w)
  cloud_coverage = data$Cloud.Ceiling #Recorded cloud coverage (km)
)

#Using "dplyr" library now we'll group data by month and location using sum and mean values for some fields

df <- unique(within(df, {
  humidity <- ave(humidity, list(location,month), FUN = mean) #Take average humidity
  temp <- ave(temp, list(location,month), FUN = mean) #Take average temperature
  wind_speed <- ave(wind_speed, list(location,month), FUN = mean) #Take average wind speed
  visibility <- ave(visibility, list(location,month), FUN = mean) #Take average visibility
  pressure <- ave(pressure, list(location,month), FUN = mean) #Take average pressure
  cloud_coverage <- ave(cloud_coverage, list(location,month), FUN = mean) #Take average cloud coverage
  power_output <- ave(power_output, list(location,month), FUN = sum) #Sum daily recorded system power output (Wh)
  is_enough_power_produced = (power_output > 1000) #Our Boolean value used for classification (monthly production above 1kwh)
}))

#Now we draw graphs to visualise our data

hist(df$temp, main = "Ambient temperature", xlab="°C")
hist(df$cloud_coverage, main = "Cloud coverage", xlab="km")
hist(df$visibility, main = "Visibility", xlab="km")

#In already conducted study mentioned on line 11 of this code it is proven that greatest impact on power output has temperature and thus
#we will show relationship between power output and average temperature

a <- df$temp
b <- df$power_output

plot(a, b, main = "Relationship between panel average monthly\n temperature and it's output in Wh", xlab = "Temperature °C", ylab = "Power output Wh", pch = 8, frame = FALSE)
abline(lm(b ~ a, data = df), col = "red")
cor.test(a, b, method = c("pearson", "kendall", "spearman")) 
#The p-value of the test is 2.2^{-16}, which is less than the significance level alpha = 0.05. 
#We can conclude that panel temperature and it's output are significantly correlated 
#with a correlation coefficient of 0.66 and p-value of 2.2^{-16}.

summary(df) #Display statistical informations about data

#Now we will use Multivariate Analysis on attributes shown on graphs

plot_temp = ggplot(df) + geom_point(aes(temp, power_output),colour = "red", alpha =0.3) + theme(axis.title = element_text(size = 8.5)) + ggtitle("Plot of monthly power output by average ambient temperature") + xlab("Temperature °C") + ylab("Power output Wh")
plot_temp

plot_cloud_coverage = ggplot(df)+geom_point(aes(cloud_coverage, power_output),colour = "skyblue", alpha =0.3) + theme(axis.title = element_text(size = 8.5))  + ggtitle("Plot of monthly power output by average cloud coverage") + xlab("Average cloud coverage km") + ylab("Power output Wh")
plot_cloud_coverage

plot_visibility = ggplot(df)+geom_point(aes(visibility, power_output),colour = "blue", alpha =0.3) + theme(axis.title = element_text(size = 8.5)) + ggtitle("Plot of monthly power output by average visibility") + xlab("Average visibility km") + ylab("Power output Wh")
plot_visibility

#Now we'll se corelation matrix to decided whether we need to use PCA algoritham for feature selection

df_numeric_only <- df %>% select_if(is.numeric) #For this matrix we need to only use numerical attributes

corMatrix <- cor(df_numeric_only) #Compute all correlations between each other and form correlation matrix.
corrplot(corMatrix,order = "FPC",method = "color",type = "lower", tl.cex = 0.6, tl.col = "black")
# Principal Component Analysis is not necessary since there are not to much strong correlations between features and target values.

boruta <- Boruta(is_enough_power_produced ~ ., data = df, doTrace = 2, maxRuns = 500) #Using Boruta for feature selection 
print(boruta) #Here we see 7 confirmed important and 2 tentative important features*
#*Note: Result may vary on each run of Boruta

boruta <- TentativeRoughFix(boruta) #We need now to check tentative features again
print(boruta) #Now we see end result of our features and we can remove any non important feature, again this result may vary on each run of Boruta

plot(boruta, las = 2, cex.axis = 0.7)
attStats(boruta)

getSelectedAttributes(boruta, withTentative = F)

#Now we need to transform our data set to be used in random forest algorithm

df <- df %>% select(-power_output) #Attribute removed because it directly impacts is_enough_power_produced
df <- df %>% select(-month) #Attribute removed because it is rejected by Boruta algorithm

df <- transform(
  df,
  location = as.character(location),
  humidity = as.numeric(humidity),
  temp = as.numeric(temp),
  wind_speed = as.numeric(wind_speed),
  visibility = as.numeric(visibility),
  pressure = as.numeric(pressure),
  cloud_coverage = as.numeric(cloud_coverage),
  is_enough_power_produced = as.factor(is_enough_power_produced)
)

# We'll split data into training and test sets.
set.seed(201682) #Setting seed so outcome of testing will be repeatable

sample_size = floor(0.70 * nrow(df)) #We split in proportion of 70/30
training_index = sample(seq_len(nrow(df)), size=sample_size)
training_set = subset(df[training_index,], sample = TRUE)
validation_set = subset(df[-training_index,], sample = FALSE)

test_set = validation_set %>% select(-is_enough_power_produced) 

#Display first 10 rows of our sets

head(training_set)
head(validation_set)

#Display row count

dim(training_set)
dim(validation_set)

# Train model with Random Forest
model <- randomForest(formula = is_enough_power_produced ~ ., data=training_set, importance=TRUE, ntree=500, type='classification')
model #Show random forest model

varImpPlot(model)

test_set$is_enough_power_produced = predict(model, newdata=test_set[-8]) #Assign predicted data to missing column

confusion_matrix = table(validation_set[,8], test_set[,8]) #Create confusion matrix of is_enough_power_produced values
confusion_matrix #Display confusion matrix of is_enough_power_produced values

cat("Our model accurancy is:", mean(test_set$is_enough_power_produced == validation_set$is_enough_power_produced) * 100, "%")