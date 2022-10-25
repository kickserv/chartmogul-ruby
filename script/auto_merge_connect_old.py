import chartmogul
config = chartmogul.Config('')

cxids_from=[]

cxids_into=[]

subids=[]

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
            "external_id": subids[j]
        },
        {
            "data_source_uuid": "",
            "external_id": subids[j]
        }
        ]
    })
    j += 1