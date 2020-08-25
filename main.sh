curl -o data/raw/Covid-19-density.csv https://raw.githubusercontent.com/ANRGUSC/lacounty_covid19_data/master/data/Covid-19-density.csv
curl -o data/raw/lacounty_covid.json https://raw.githubusercontent.com/ANRGUSC/lacounty_covid19_data/master/data/lacounty_covid.json

tar -xvf data/external/Core-USA-August2020-Release-CORE_POI-2020_07-2020-08-07.gz -C data/external/Core_POI_Folder/

python src/python/export_data.py 0805 0812 0819

Rscript --vanilla src/R/risk_score.R