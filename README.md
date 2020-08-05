# RMDS_COVID19_riskgenerator


# How to use this script

 1. Clone the whole repository from GitHub

 2. Pre-Download data:
    * Data from SafeGraph.com: Need to apply an account
        * Consecutive 3 weeks of user patterns: Weekly Places Patterns 
        ![Weekly Places Patterns](data/internal/image/weekly.png)
        * POI data: Core Places (US Only)
        ![poi](data/internal/image/poi.png)
    * Third party data saved in SafeGraph.com:
        * POI area square foot data: Need to download from AWS CLI (stored in S3)
        * `aws s3 cp s3://sg-c19-response/geo-supplement/May2020Release/SafeGraphPlacesGeoSupplementSquareFeet.csv.gz <your_local_path> --profile safegraphws --endpoint https://s3.wasabisys.com`
    * infection cases and death cases from [lacounty.gov](http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/)
        * Click `[Table: Community Case/Death]`, then click download
        * Click `[Table: Community Testing]`, then click download

