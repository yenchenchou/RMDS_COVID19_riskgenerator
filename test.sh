NOW=$(date +"%Y-%m-%d")
YESTERDAY=$(date -v -1d +"%Y-%m-%d")
echo "move old test/death data to data/archive if exist..."
find data/external -ctime -365 -type f -name "LA_County_Covid19*" -exec mv {} data/archive/ \;
mv data/archive/LA_County_Covid19_CSA_testing_table.csv data/archive/LA_County_Covid19_CSA_testing_table_$YESTERDAY.csv
mv data/archive/LA_County_Covid19_CSA_case_death_table.csv data/archive/LA_County_Covid19_CSA_case_death_table_$YESTERDAY.csv
echo "rename LA_County_Covid19_CSA_testing_table if exist..."
mv data/external/LA_County_Covid19_CSA_testing_table\ copy.csv data/external/LA_County_Covid19_CSA_testing_table.csv
echo "rename LA_County_Covid19_CSA_case_death_table if exist..."
mv data/external/LA_County_Covid19_CSA_case_death_table\ copy.csv data/external/LA_County_Covid19_CSA_case_death_table.csv