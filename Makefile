district_code := "Kanpur Nagar"
header := "Date,Confirmed,Recovered,Deceased"
kanpur.csv: districts.csv
	echo $(header) > kanpur.csv # Append header 
	cat $^ | grep $(district_code) | awk -F, 'OFS="," {print $$1,$$4,$$5,$$6}' >> kanpur.csv
