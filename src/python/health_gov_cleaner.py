import os
import re
import sys
import pandas as pd


def name_cleaner(file):
    replace_str = "(^City of |^Los Angeles - |^Unincorporated - )"
    df = pd.read_csv(file)
    df["geo_merge"] = df["geo_merge"].apply(
        lambda x: re.sub(r"".join(replace_str), "", x))

    if "death" in file:
        df.to_csv(
            "data/processed/LA_County_Covid19_CSA_case_death_table.csv",
            index = False)
        print("saved in folder: data/processed")
    elif "testing" in file:
        df.to_csv(
            "data/processed/LA_County_Covid19_CSA_testing_table.csv",
            index = False) 
        print("saved in folder: data/processed")
    else:
        print("failed to save data")

    


if __name__ == "__main__":
    file1 = sys.argv[1]
    file2 = sys.argv[2]
    name_cleaner(file1)
    name_cleaner(file2)