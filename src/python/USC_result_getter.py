# get the risk score in each community for the specific date.
import pandas as pd
start_date = '2020-06-24' 
end_date = '2020-07-08'

def risk_score_getter(start_date=None,end_date=None):
    df = pd.read_csv('./data/processed/USC_community_risk.csv',index_col = False)
    result = df[(df.TimeStamp>=start_date) & (df.TimeStamp<=end_date)]
    if result.empty :
        print('the time frame is empty')
    else:
        pass
        path = './data/processed/USC_community_risk_{}_{}.csv'.format(start_date,end_date)
        result.to_csv(path,index=False)
    return result
    
#risk_score_getter(start_date,end_date)