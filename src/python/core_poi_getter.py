"""
@author: Yen-Chen Chou
"""
import json
import pandas as pd

class POI(object):
    def __init__(self):
        self.df = pd.read_csv(
            "data/external/Core-USA-July2020-Release-CORE_POI-2020_06-2020-07-13/core_poi-part1.csv.gz",
            compression = "gzip")
        self.mapper_dict = None


    def get_poi(self):
        
        filter_ls = ["Restaurants and Other Eating Places", "Grocery Stores"]
        #     df = df[df["top_category"].isin(filter_ls)].copy()
        self.df = self.df[self.df["region"] == "CA"].copy()
        self.df = self.df[["safegraph_place_id", 
                         "latitude",
                         "longitude",
                         "city",
                         "postal_code"]]
        self.df["community"] = self.df["postal_code"].apply(lambda x: self.mapping(x))
        self.df = self.df[self.df["community"].notnull()]
        
        return self.df


    def read_mapper(self):
        with open("data/internal/zipcode_mapper.json") as file:
            self.mapper_dict = json.load(file)
        self.mapper_dict = {str(key):val for key, val in self.mapper_dict.items()}


    def mapping(self, x):
        try: 
            return self.mapper_dict[str(x)]
        except:
            pass    


# if __name__ == "__main__":
#     print("Start getting poi data...")
#     poi = POI()
#     poi.read_mapper()
#     df_poi = poi.get_poi()
#     df_poi.to_csv("data/processed/RMDS_poi.csv", index = False)
#     print("Complete!")
