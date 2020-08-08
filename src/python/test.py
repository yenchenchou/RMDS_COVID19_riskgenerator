#%%
import glob
import os

import pandas as pd
os.chdir("/Users/yenchenchou/Documents/RMDS_YC/RiskScore/RMDS_COVID19_riskgenerator")

#%%

# %%
df_pattern = pd.read_csv(
    "data/external/weekly_pattern/0729/patterns-part1.csv.gz", 
    compression="gzip",
    usecols=["safegraph_place_id",
             "visits_by_day",
             "visits_by_each_hour",
             "median_dwell",
             "date_range_start"])
df_pattern.head(3)
# %%
df_poi = pd.read_csv("data/processed/RMDS_poi.csv",usecols=["safegraph_place_id"])
df_poi.head(3)

# %%
df_pattern = pd.merge(df_poi, df_pattern, how="inner")

# %%
df_pattern.shape

# %%
df_pattern.info()

# %%
df_pattern_filter = pd.read_csv(
    "data/processed/patterns-1.csv", 
    usecols=["safegraph_place_id",
             "visits_by_day",
             "visits_by_each_hour",
             "median_dwell",
             "date_range_start",
             "date_range_end"])

# %%
df_pattern_filter.head()

# %%
df_pattern_filter.shape


# %%
df_pattern_filter.info()

# %%
int("0715") + 7

# %%
