public class GeocodingAndDistanceService {
    private static final String DISTANCE_MATRIX_BASE_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    private static final String GEOCODING_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';

    public class AddressInput {
        @InvocableVariable(required=true)
        public Id addressId;
    }

    public class AddressResult {
        @InvocableVariable
        public Id addressId;

        @InvocableVariable
        public Decimal latitude;

        @InvocableVariable
        public Decimal longitude;

        @InvocableVariable
        public Id nearestLocationId;

        @InvocableVariable
        public Decimal distance;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Fetch Geolocation and Calculate Distance' description='Fetches geolocation data if missing, calculates the distance, and returns results.')
    public static List<AddressResult> handleGeocodingAndDistance(List<AddressInput> inputs) {
        List<AddressResult> results = new List<AddressResult>();
        System.debug('inputs > ' + inputs);
        for (AddressInput input : inputs) {
            AddressResult result = new AddressResult();
            result.addressId = input.addressId;
            try {
                Address__c address = [
                    SELECT Id, Address__Street__s, Address__City__s, Address__StateCode__s, Address__PostalCode__s, Address__CountryCode__s,
                           Address__Latitude__s, Address__Longitude__s
                    FROM Address__c
                    WHERE Id = :input.addressId
                    LIMIT 1
                ];

                // Check if geolocation data is present
                if (address.Address__Latitude__s == null || address.Address__Longitude__s == null) {
                    Map<String, Decimal> geolocation = fetchGeolocation(address);
                    address.Address__Latitude__s = geolocation.get('latitude');
                    address.Address__Longitude__s = geolocation.get('longitude');
                }

                result.latitude = address.Address__Latitude__s;
                result.longitude = address.Address__Longitude__s;

                // Find the nearest location
                List<Schema.Location> nearestLocations = [
                    SELECT Id, VisitorAddress.Street, VisitorAddress.City, VisitorAddress.State, VisitorAddress.PostalCode, VisitorAddress.Country,
                    VisitorAddress.Latitude, VisitorAddress.Longitude
                    FROM Location
                    WHERE VisitorAddressId != NULL
                    ORDER BY DISTANCE(VisitorAddress.Address, GEOLOCATION(:address.Address__Latitude__s, :address.Address__Longitude__s), 'km')
                    LIMIT 3
                ];

                if (nearestLocations.isEmpty()) {
                    throw new NoNearbyLocationsFoundException('No nearby locations found for Address ID: ' + input.addressId);
                }

                // Calculate the nearest distance using Google Maps Distance Matrix API
                Decimal closestDistance = null;
                Id nearestLocationId = null;
                for (Schema.Location location : nearestLocations) {
                    Decimal distance = getDistanceFromGoogleMaps(address, location);
                    if (distance != null && (closestDistance == null || distance < closestDistance)) {
                        closestDistance = distance;
                        nearestLocationId = location.Id;
                    }
                }

                result.nearestLocationId = nearestLocationId;
                result.distance = closestDistance;
                
                system.debug(result.latitude);
                system.debug(result.longitude);
                system.debug(result.nearestLocationId);
                system.debug(result.distance);
                
            } catch (Exception e) {
                result.errorMessage = 'Unexpected error: ' + e.getMessage();
            }

            results.add(result);
        }

        return results;
    }

    private static Map<String, Decimal> fetchGeolocation(Address__c address) {
        String fullAddress = address.Address__Street__s + ', ' + address.Address__City__s + ', ' +
                             address.Address__StateCode__s + ', ' + address.Address__PostalCode__s + ', ' + address.Address__CountryCode__s;

        String apiKey = GoogleMapsSettings__c.getInstance().API_Key__c;
        if (String.isBlank(apiKey)) {
            throw new MissingAPIKeyException('API Key is missing from Custom Setting');
        }

        String url = GEOCODING_BASE_URL + '?address=' + EncodingUtil.urlEncode(fullAddress, 'UTF-8') + '&key=' + apiKey;

        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(url);
        httpRequest.setMethod('GET');

        HttpResponse response = http.send(httpRequest);
        if (response.getStatusCode() != 200) {
            throw new APIException('Failed to call Geocoding API. Status: ' + response.getStatus());
        }

        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        if (results.containsKey('results')) {
            List<Object> resultList = (List<Object>) results.get('results');
            if (!resultList.isEmpty()) {
                Map<String, Object> geometry = (Map<String, Object>) ((Map<String, Object>) resultList[0]).get('geometry');
                Map<String, Object> location = (Map<String, Object>) geometry.get('location');

                return new Map<String, Decimal>{
                    'latitude' => Decimal.valueOf(location.get('lat').toString()),
                    'longitude' => Decimal.valueOf(location.get('lng').toString())
                };
            }
        }

        throw new APIException('Failed to fetch geolocation for the address.');
    }

    private static Decimal getDistanceFromGoogleMaps(Address__c origin, Schema.Location destination) {
        String apiKey = GoogleMapsSettings__c.getInstance().API_Key__c;
        if (String.isBlank(apiKey)) {
            throw new MissingAPIKeyException('API Key is missing from Custom Setting');
        }

        String originAddress = origin.Address__Street__s + ', ' + origin.Address__City__s + ', ' +
                               origin.Address__StateCode__s + ', ' + origin.Address__PostalCode__s + ', ' + origin.Address__CountryCode__s;

        String destinationAddress = destination.VisitorAddress.Street + ', ' + destination.VisitorAddress.City + ', ' +
                                     destination.VisitorAddress.State + ', ' + destination.VisitorAddress.PostalCode + ', ' + destination.VisitorAddress.Country;

        String url = DISTANCE_MATRIX_BASE_URL + '?origins=' + EncodingUtil.urlEncode(originAddress, 'UTF-8') +
                     '&destinations=' + EncodingUtil.urlEncode(destinationAddress, 'UTF-8') + '&key=' + apiKey;

        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(url);
        httpRequest.setMethod('GET');

        HttpResponse response = http.send(httpRequest);
        if (response.getStatusCode() != 200) {
            throw new APIException('Failed to call Distance Matrix API. Status: ' + response.getStatus());
        }

        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        if (results.containsKey('rows')) {
            List<Object> rows = (List<Object>) results.get('rows');
            if (!rows.isEmpty()) {
                Map<String, Object> elements = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) rows[0]).get('elements'))[0];
                Map<String, Object> distance = (Map<String, Object>) elements.get('distance');
                if (distance != null) {
                    return Decimal.valueOf((Integer) distance.get('value')); // Will be returned in meters
                }
            }
        }

        throw new APIException('Failed to calculate distance from Google Maps API.');
    }

    // Custom Exceptions
    public class MissingAPIKeyException extends Exception {}
    public class APIException extends Exception {}
    public class NoNearbyLocationsFoundException extends Exception {}
}