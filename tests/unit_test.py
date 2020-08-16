#%%
import os
import glob
import json
import pandas as pd
import numpy as np
os.chdir("/Users/yenchenchou/Documents/RMDS_YC/RiskScore/RMDS_COVID19_riskgenerator")

# %%
df_rpi = pd.read_csv("data/internal/risk_score.csv")
df_rpi.shape

# %%
# df_rpi[df_rpi["risk_score"]!=-1].shape

#%%
df_rpi[(df_rpi["city"]=="Los Angeles") & (df_rpi["risk_score"]!=-1)].shape
# %%
df_rmds = pd.read_csv("data/processed/RMDS_poi.csv")
df_rmds.shape

# %%
df_rmds.head()
# %%
df_rmds[df_rmds["community"]!="missing"].shape

# %%
df_rpi[df_rpi["community"].notnull()].shape

# %%
len(df_rpi["community"].unique())

# %%
df_rpi.head(20)

# %%
# rpi_community_list = df_rpi["community"].value_counts().tolist()
# rpi_index_list = df_rpi["community"].index.tolist()
rpi_community_count = pd.DataFrame(df_rpi["community"].value_counts())
rpi_community_count = rpi_community_count.reset_index()
rpi_community_count.rename(columns={"index":"community", "community":"num"}, inplace=True)
rpi_community_count.head()
# %%
rmds_community_list = df_rmds["community"].unique().tolist()

# %%
idx_list = []
for idx, val in enumerate(df_rpi["community"]):
    if val in rmds_community_list:
        idx_list.append(idx)
# %%
len(idx_list)

# %%
df_rpi_filter = df_rpi.iloc[idx_list,:]
df_rpi_filter = df_rpi_filter[(df_rpi_filter["city"]=="Los Angeles") & (df_rpi_filter["risk_score"]!=-1)]
df_rpi_filter.shape

# %%
df_rpi[(df_rpi["city"]=="Los Angeles") & (df_rpi["community"] == "passadena")].head()

# %%
df_rmds.shape

# %%
df_rpi.iloc[idx_list,:].shape

# %%
df_rpi.head()

# %%
folder_path = "data/external/Core-USA-July2020-Release"\
    "-CORE_POI-2020_06-2020-07-13"
def get_poi(folder_path):
    """ Get poi data with community names in CA
    Return:
        df (dataframe): poi data
    """
    df = pd.DataFrame()
    folder_path_exp = os.path.join(folder_path, "*.csv.gz")
    file_paths = glob.glob(folder_path_exp)
    for paths in file_paths:
        df_tmp = pd.read_csv(paths, compression="gzip")
        df_tmp = df_tmp[df_tmp["region"] == "CA"].copy()
        df_tmp = df_tmp[["safegraph_place_id","postal_code"]].copy()
        df = pd.concat([df, df_tmp], axis=0, ignore_index=True)
    return df  
df_original = get_poi(folder_path)
