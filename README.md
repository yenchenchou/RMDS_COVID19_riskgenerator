# RMDS_COVID19_riskgenerator
## Project structure
The project is an extension and computation optimized version of team [RPI](https://github.com/Yueyang-Li-Elfa/Risk-Score-RPI-Solver) who participate the 2020 COVID-19 challenge held by [RMDS Lab](https://grmds.org/2020challenge). The orignal project was reviewed by a panel of judges from the City of LA, LA County Department of Public Health, Chamber of Commerce, and academia. This project produce a risk score of infection cases and its according risk level from a variety a data sources. Data includes, POI (Point of Interest) data gathered from [SafeGraph](https://www.safegraph.com/), third party POI area data store in SafeGraph, COVID-19 cases from [lacounty.gov](http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard), a mixsure result of result from another team from USC, and external dataset such as Yelp API. The project structure is as follows:

![RPI_RiskScore_FlowChart](data/internal/image/RPI_RiskScore_FlowChart.png)

## How to use this script

 1. Clone the whole repository from GitHub

 2. Pre-Download data:
 A total of 7 files need to download (Don't worry, we have example data for you in the future!). Store all the data into `/data/external/` folder
    * Data from SafeGraph.com: Need to apply an account
        * **Consecutive 3 weeks of user patterns**: Weekly Places Patterns (1-3)
        ![Weekly Places Patterns](data/internal/image/weekly.png)
        * **POI (Point of Interest) data**: Core Places (US Only) (4)
        ![poi](data/internal/image/poi.png) 
    * Third party precalculated data saved in SafeGraph.com:
        * **POI area square foot data**: Need to download from AWS CLI (stored in S3) (5)
        ```aws s3 cp s3://sg-c19-response/geo-supplement/May2020Release/SafeGraphPlacesGeoSupplementSquareFeet.csv.gz <your_local_path> --profile safegraphws --endpoint https://s3.wasabisys.com```
    * **infection cases and death cases** from [lacounty.gov](http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/)
        * Click `[Table: Community Case/Death]`, then click download (6)
        * Click `[Table: Community Testing]`, then click download (7)
        ![test_death](data/internal/image/test_death.png)

3. Check necessary dependencies in `requirements.txt` 
```
pip install -r requirements.txt
```
4. Run the script:
Go to the folder where you clone the files:
    1. Get processed data (for example), you need to enter three weeks of patterns with four digits each:

    ```Python
    python src/python/export_data.py 0722 0729 0805
    ```

        * You will get the following data:
            1. RMDS_open_hours.csv 
            2. RMDS_poi_area_square_feet.csv
            3. RMDS_poi.csv
            4. RMDS_zipcode_mapper.json
            5. pattern-<date>.csv
            
    2. Get the risk score: Open R and edit the correct weekly pattern
        ![R_script](data/internal/image/R_script_shot.png)
        * You will get POI risk score and community risk score in `data/result` folder
            1. risk_poi-YYYY-MM-DD.csv
            2. risk_community-YYYY-MM-DD.csv

