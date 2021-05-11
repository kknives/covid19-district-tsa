district := "Kanpur Nagar"
data_src := https://api.covid19india.org/csv/latest/districts.csv
header := "Date,Confirmed,Recovered,Deceased"
kanpur.csv: districts.csv
	echo $(header) > kanpur.csv # Append header 
	cat $^ | grep $(district) | awk -F, 'OFS="," {print $$1,$$4,$$5,$$6}' >> kanpur.csv

fetch:
	curl $(data_src) -o districts.csv
