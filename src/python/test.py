#%%
import glob
import os

import pandas as pd
os.chdir("/Users/yenchenchou/Documents/RMDS_YC/RiskScore/RMDS_COVID19_riskgenerator")

#%%

# %%
df_pattern = pd.read_csv(
    "data/external/weekly_pattern/0805/patterns-part1.csv.gz", 
    compression="gzip",
    usecols=["safegraph_place_id",
             "visits_by_day",
             "visits_by_each_hour",
             "median_dwell",
             "date_range_start"])
df_pattern.head(3)
# %%
df_pattern.tail(3)
