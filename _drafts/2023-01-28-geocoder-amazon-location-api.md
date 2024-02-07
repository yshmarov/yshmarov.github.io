[Local geocoding](https://github.com/ankane/ahoy#local-geocoding)


https://developers.google.com/maps/documentation/maps-static


### Geocoder with Amazon Location Service API

First, grant IAM access to Amazon Location Service.

I found it a bit challenging, but [Here's the official guide I found that helped me](https://docs.aws.amazon.com/location/latest/developerguide/gs-prereqs.html)

Create a [places index](https://eu-central-1.console.aws.amazon.com/location/places/home?region=eu-central-1#/)

Next, use the [Amazon Location Service API](https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md#amazon-location-service-amazon_location_service) adapter for geocoder.

Amazon Location Service
  Amazon Location Maps
  Amazon Location Places

AmazonLocationAccessPolicy

us-east-2
geo.us-east-2.amazonaws.com 


```ruby
bundle add aws-sdk-locationservice

access_key_id = "AKIA5RINJLYGI23R5MGS"
secret_access_key = "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"
credentials = [access_key_id, secret_access_key]

require 'aws-sdk-core'
    location_service = Aws::LocationService::Client.new(region: 'us-east-1')
    resp = location_service.associate_tracker_consumer(params)

client = Aws::LocationService::Client.new(
  region: 'us-east-1',
  credentials: credentials,
)
```

```ruby
Geocoder.configure(
  lookup: :amazon_location_service,
  amazon_location_service: {
    index_name: 'YOUR_INDEX_NAME_GOES_HERE',
    api_key: {
      access_key_id: 'YOUR_AWS_ACCESS_KEY_ID_GOES_HERE',
      secret_access_key: 'YOUR_AWS_SECRET_ACCESS_KEY_GOES_HERE',
    }
  }
)
```
