library(timetk)
library(forecast)
library(lubridate)
library(sweep)
library(tidyverse)

data <- read.csv('kanpur.csv')
data.begin <- ymd(data$Date[1])
data.end <- ymd(data$Date[nrow(data)])
summary(data)

# Convert into a time series with weekly period
data.ts.dsc <- tk_ts(data$Deceased, frequency=7, start=data.begin)
autoplot(decompose(data.ts.dsc)) + ggtitle("Decomposition")

# Utility functions:
rmse <- function(t, o) { sqrt(mean((t-o)^2)) }
rm_na <- function(d) { d[!is.na(d)] }
res_sw <- function(res) { res %>% sw_sweep(timekit_idx=T) %>% rename(date=index) }
res_date <- function(res, begin, end) {
  res$date <- begin:end
  res
}
res_g <- function(res, title="", x_lab="", y_lab="") {
  res %>%
      ggplot(aes(x = as.Date(date, "1970-01-01"), y = value, color = key)) +
      # Prediction intervals
      geom_ribbon(aes(ymin = lo.95, ymax = hi.95, fill=key),
                  fill = "#FFBD00", alpha=0.7, color = NA, size = 0) +
      geom_ribbon(aes(ymin = lo.80, ymax = hi.80, fill = key),
                  fill = "#EEABC4", color = NA, size = 0, alpha = 0.8) +
      # Actual & Forecast
      geom_line(size = 1) +
      # Aesthetics
      theme_bw() +
      labs(title=title, x=x_lab, y=y_lab) +
      scale_x_date(date_labels="%d %b %Y")
}
desc.title <- "COVID-19 caused deaths in Kanpur with respect to time"
desc.xlab <- "Date"
desc.ylab <- "Number of Deaths"
res_mtab <- function(res) {
  res %>% res_date(data.begin, data.end + 60) %>%
  mutate( date = ymd(as.Date(date, "1970-01-01")) ) 
}
# Training Testing & Tuning
# Creating training & testing data 80/20 split
data.train <- tk_ts(data.ts.dsc[1:round(length(data.ts.dsc) * 0.8)], frequency=7, start=data.begin)
data.train.size <- length(data.train)
data.test <- tk_ts(rm_na(data.ts.dsc[length(data.train)+1:length(data.ts.dsc)]), frequency=7, start=data.begin)
data.test.size <- length(data.test)

# ARIMA model
model.arima <- auto.arima(data.train, seasonal=TRUE, stepwise=FALSE, approximation=FALSE)
results.arima <- forecast(model.arima, h=data.test.size)
sw_results <- res_sw(results.arima)
rmse(data.test[1:data.test.size], results.arima$mean)
# Plot the arima model
sw_results %>% res_date(data.begin, data.end) %>% res_g(desc.title, desc.xlab, desc.ylab)

# Holt-Winters
results.hw <- hw(data.train, seasonal='additive', h=data.test.size)
rmse(data.test[1:data.test.size], results.hw$mean)
sw_results <- res_sw(results.hw)
# Graph the results
sw_results %>% res_date(data.begin, data.end) %>% res_g(desc.title, desc.xlab, desc.ylab)

# Time for forecasting
# arima forecasting
model.arima <- auto.arima(data.ts.dsc, seasonal=TRUE, stepwise=FALSE, approximation=FALSE)
forecast.arima <- forecast(model.arima, h=60)
forecast.sw.arima <- res_sw(forecast.arima)
# Plot the results
forecast.sw.arima %>% res_date(data.begin, data.end + 60) %>% res_g(desc.title, desc.xlab, desc.ylab)
forecast.fin.arima <- res_mtab(forecast.sw.arima)
res_mtab(forecast.sw.arima) %>%
  filter(mday(date) == 1) %>%
  readr::write_csv("res_tab_arima.csv", na="NA")

# Holt-Winters forecasting
forecast.hw <- hw(data.ts.dsc, seasonal='additive', h=60)
forecast.sw.hw <- res_sw(forecast.hw)
# Plot the results
forecast.sw.hw %>% res_date(data.begin, data.end + 60) %>% res_g(desc.title, desc.xlab, desc.ylab)
forecast.fin.hw <- res_mtab(forecast.sw.hw)
res_mtab(forecast.sw.hw) %>%
  filter(mday(date) == 1) %>%
  readr::write_csv("res_tab_hw.csv", na="NA")
