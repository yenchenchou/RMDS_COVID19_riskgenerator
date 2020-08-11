import requests
import json
import pandas as pd

poi = pd.read_csv("RMDS_poi-2.csv")
api_key="oMbGupwGao1rT-tojmJzvj-CjUZ3AzZ_n30xxqCbnXayu4qwQB6CGy3-5jmblq307N_yGZoHym6KT3Cxkfacdr1gjpJl_LGPy2sADmcNEtKDtYEZzYrJstOnCm4nX3Yx"
headers = {'Authorization': 'Bearer %s' % api_key}
url='https://api.yelp.com/v3/businesses/matches'

count=0
result = []
with open('business_id_matching.jsonl','a',encoding='utf-8') as f:
    for i in range(5000):
        params={'name':poi.loc[i,'location_name'],"address1":poi.loc[i,'street_address'],"address2": "",
         "address3": "","city":poi.loc[i,'city'],"state": "CA", "zip_code": poi.loc[i,'postal_code'],"country": "US"}
        print(count)
        req = requests.get(url, headers=headers, params=params)
        result.append(req.text)
        count += 1
        json.dump(req.text,f)
        f.write('\n')
print('done')  

