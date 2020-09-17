#!/bin/sh
# params
NOW=$(date +"%Y-%m-%d")
YESTERDAY=$(date -v -1d +"%Y-%m-%d")
POI_CORE_FILE="data/external/Core-USA-September2020-Release-CORE_POI"
CUM_FILE=data/risk_latest/risk_community.csv
POI_FILE=data/risk_latest/risk_poi.csv
POI_FOLDER=data/external/Core_POI_Folder
OLD_POI_FILE=data/risk_history/risk_poi-$YESTERDAY.csv
OLD_CUM_FILE=data/risk_history/risk_community-$YESTERDAY.csv
WEEK1=$1
WEEK2=$2
WEEK3=$3

# move old LA county case/death csv and load the new
echo "move old test/death data to data/archive if exist..."
# find files modified more than 48 hours ago
# find data/external -ctime 1 -type f -name "LA_County_Covid19*" -exec mv {} data/archive/ \;

# echo "rename LA_County_Covid19_CSA_testing_table if exist..."
mv /Users/yenchenchou/Downloads/LA_County_Covid19_CSA_testing_table.csv data/external/LA_County_Covid19_CSA_testing_table.csv
# echo "rename LA_County_Covid19_CSA_case_death_table if exist..."
mv /Users/yenchenchou/Downloads/LA_County_Covid19_CSA_case_death_table.csv data/external/LA_County_Covid19_CSA_case_death_table.csv


# move the old risk score to risk_history
if [ -f "$POI_FILE" ]; then
    echo "$POI_FILE exists. Moving files..."
    mv $POI_FILE $OLD_POI_FILE
else 
    echo "$POI_FILE does not exist or has moved. Skip process..."
fi

if [ -f "$CUM_FILE" ]; then
    echo "$CUM_FILE exists. Moving files..."
    mv $CUM_FILE $OLD_CUM_FILE
else 
    echo "$CUM_FILE does not exist or has moved. Skip process..."
fi


# get density data from team USC
curl -o data/raw/Covid-19-density.csv https://raw.githubusercontent.com/ANRGUSC/lacounty_covid19_data/master/data/Covid-19-density.csv
curl -o data/raw/lacounty_covid.json https://raw.githubusercontent.com/ANRGUSC/lacounty_covid19_data/master/data/lacounty_covid.json


# create folder for POI core data and unzip the file
if [ -d "$POI_FOLDER" ]; then
    echo "$POI_FOLDER exists. Skip process..."
else 
    echo "$POI_FILE does not exist, create folder..."
    mkdir $POI_FOLDER
    if ls $POI_CORE_FILE*gz 1> /dev/null 2>&1; then
        tar -xvf $POI_CORE_FILE*gz -C data/external/Core_POI_Folder/
        # rm $POI_CORE_FILE*gz
    else
        echo "files do not exist, please download the file"
    fi
fi


# run data pipeline
python src/python/export_data.py $WEEK1 $WEEK2 $WEEK3


# run risk score calculator
Rscript --vanilla src/R/risk_score.R $WEEK1 $WEEK2 $WEEK3