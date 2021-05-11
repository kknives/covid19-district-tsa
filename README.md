# District level projection of COVID-19 cases
We can semi-reliably predict (tuning required) the trend of new cases due to COVID-19 in a given district using
standard Time Series Analysis methods such as Holt-Winters or ARIMA.

## How to Use
`forecast.R` contains the code for making a training and testing a model and finally applying it on available data
to forecast the near future.

But before that, we need the data, the scripts for doing that are in the `Makefile`, but you don't need to know how
it works, generate the data for your district using:
```
make district='"New Delhi"'
```

Keep in mind, the data is from `covid19india.org` and is updated daily, to download a new copy of the data, run
```
make fetch
make district='"New Delhi"'
```
