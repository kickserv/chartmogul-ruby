import chartmogul
config = chartmogul.Config('INSERT_API_KEY_HERE')
r = chartmogul.Ping.ping(config).get() 
print(r) #confirm authentication

cxids_from=[]
cxids_into=[]

subid_from=[]
subid_into=[]

## A file named 'data.CSV' must exist with 3 column headers.
# The first two columns should be filled with the UUIDs of the two customers being merged.
# the last two colmns should contain subscription IDs that need to be connected

# Example data.CSV:
# from_uuid,into_uuid
# cus_3hs8fh_sh4n3s,cus_38dj220_2n2du, sub_111, sub_222

with open('data.csv', 'r') as file:
    reader = csv.reader(file)
    for row in reader:
        cxids_from.append(row[0])
        cxids_into.append(row[1])
        subid_from.append(row[2])
        subid_to.append(row[3])

print("")
print("Starting merges")

i = 0
while i < 2:
    print(cxids_into[i])
    chartmogul.Customer.merge(config, data={
        "from": {
            "customer_uuid": cxids_from[i]
        },
        "into": {
            "customer_uuid": cxids_into[i]
        }
    })
    i += 1

print("")
print("Starting connections")

j = 0
while j < 2:
    print(cxids_into[j])
    chartmogul.Customer.connectSubscriptions(config, uuid=cxids_into[j], data={
        'subscriptions': [
        {
            "data_source_uuid": "",
            "external_id": subid_from[j]
        },
        {
            "data_source_uuid": "",
            "external_id": subid_into[j]
        }
        ]
    })
    j += 1