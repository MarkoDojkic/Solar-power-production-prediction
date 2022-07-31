The dataset represents power output data from horizontal photovoltaic panels located at 12 locations in the Northern Hemisphere over 14 months. This data set was used for the purposes of predicting the output power of the panels and presented in the paper "Machine Learning Modeling of Horizontal Photovoltaics Using Weather and Location Data". 
For the purposes of this project work, an attempt will be made to predict whether the monthly production of the solar system based on the provided weather parameters will be sufficient for the household in the given locations. As we do not need all the attributes that are available to us, below I will describe only those that have been entered into the machine learning algorithm (the data cleaning procedure will be shown in the continuation of the project work):
  •location – Name of the place where the solar power plant is located
 *•month – Month of the year when production was measured
 *•humidity – Average** air humidity in percent
  •temp – Average** temperature (°C)
  •wind_speed – Average** wind speed (km/h)
  •visibility – Average** visibility (km) 
  •pressure –Average** atmospheric pressure (millibar)
  •power_output –Cut** solar system production (wh)
  •cloud_coverage –Cut** cloud coverage in percentage 
  •is_enough_power_produced –Logical value we are considering (condition: power_output > 1000.0)* Data is grouped based on these two attributes
** When processing the data for these attributes, their average monthly value was taken for each location.
