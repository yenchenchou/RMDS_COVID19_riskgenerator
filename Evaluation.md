**This doc is to evaluate the feasibility of external resource**

Source: [Public Health Data - Locations & Demographics](http://publichealth.lacounty.gov/media/coronavirus/locations.htm)

There are three tables from the source have the data in POI level

- Los Angeles County Residential Congregate and Acute Care Settings with an Active COVID-19 Outbreak **Including At Least One Laboratory-confirmed Resident**
    - Obs/Setting Name/City/Number of Confirmed Staff/Number of Confirmed Residents/Total Deaths
    - These data are dynamic and may not reflect real-time investigation counts for these settings. Confirmed case data reflect aggregate counts from the beginning of the current COVID-19 outbreaks in Los Angeles County. The number of confirmed deaths reflects known links to the outbreak settings. 
    - Acute care facilities include hospitals and psychiatric hospitals. Residential congregate settings include Skilled Nursing Facilities (SNFs), Assisted Living, Other Long-term Care, Group Home, and Correctional facilities. 
    - All cases and deaths associated with a Skilled Nursing Facility are counted for the city/community in which the facility is located per reportable disease surveillance standards. This list is intended to inform the public of the current COVID-19 community outbreaks in Los Angeles County. 
    - Inclusion on this list does not suggest neglect or wrongdoing on the part of the setting. These tables may not align with LA County Skilled Nursing Facility COVID-19 Dashboard, which summarizes publicly available information that is self-reported by SNFs to CDPH.

- Los Angeles County Non-Residential Settings Meeting the Criteria of Three or More Laboratory-confirmed COVID-19 Cases **including workplaces, food and retail stores and educational settings**
    - Obs/Setting Name/**Address**/Total Confirmed Staff/Total Non-Confirmed Symptomatic Staff

    - These data are dynamic and may not reflect real-time investigation counts for these setting. Data will change based on daily information gathered by public health investigators overseeing and supervising the investigation. 
    - Data reflect aggregate counts abstracted from vCMR's COVID-19 outbreak details for current COVID-19 outbreaks in Los Angeles County. Please note that those listed under non-confirmed symptomatic staff are staff who have symptoms ofCOVID-19 but have not been lab-confirmed. If a symptomatic staff member is later confirmed to have COVID-19, that person will be moved from Total Non-Confirmed Symptomatic Staff to Total Confirmed Staff. 
    - This list is intended to inform the public of the current COVID-19 community outbreaks in Los Angeles County. Inclusion on this list does not suggest neglect or wrongdoing on the part of the facility.


- Los Angeles County Homeless Service Settings Meeting the Criteria of <br>
(1) At Least One Laboratory-confirmed COVID-19 Case in a Residential Setting or <br>
(2) Three or More Laboratory-confirmed COVID-19 Cases or Symptomatic Persons With at Least 1 Laboratory-confirmed COVID-19 Case in a Non-residential Setting
    - Settings include interim housing, shelters, encampments, and single room units, and service providers supporting People Experiencing Homelessness (PEH).
    - Obs/Setting Name/Setting Type/Number of Confirmed Staff/Number of Confirmed Non-Staff/Total Deaths
    - The number of confirmed residents and staff reflect aggregate counts abstracted from vCMR's COVID-19 outbreak details for current COVID-19 outbreaks in Los Angeles County. These data are dynamic and may not reflect real-time investigation counts for these setting. Data will change based on daily information gathered by public health investigators overseeing, supervising, and closing the investigation.  This list is intended to inform the public of the current COVID-19 community outbreaks in Los Angeles County. Inclusion on this list does not suggest neglect or wrongdoing on the part of the setting.




## Thought
- Raw data is not available, therefore, we will have to crawl the web to get the **daily data**. 
- In RPI solution, they have already used the communicty case/death & community testing data from Public Health Data.
- If we are going to calculate the risk score on these POIs, we will need to write our own function, because the feature doesn't align with the POIs from Safegraph.
- For Homeless Service, it might be hard to map the POI to the map since there's no actual address.
