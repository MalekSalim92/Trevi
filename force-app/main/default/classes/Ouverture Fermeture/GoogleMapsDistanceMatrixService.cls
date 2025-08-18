public class GoogleMapsDistanceMatrixService {
    private static final String BASE_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json';

    public class NearestLocationResult {
        @InvocableVariable
        public Id nearestLocationId;
        @InvocableVariable
        public Decimal distance;
        @InvocableVariable
        public String error;
    }

    @InvocableMethod(label='Get Nearest Location and Distance' description='Finds the nearest Location for an Address and returns the Location ID and Distance.')
    public static List<NearestLocationResult> getNearestLocationAndDistance(List<Id> addressIds) {
        List<NearestLocationResult> results = new List<NearestLocationResult>();

        for (Id addressId : addressIds) {
            NearestLocationResult result = new NearestLocationResult();
            try {
                Address__c address = [
                    SELECT Id, Address__Street__s, Address__City__s, Address__StateCode__s, Address__PostalCode__s, Address__CountryCode__s,
                           Address__Latitude__s, Address__Longitude__s 
                    FROM Address__c 
                    WHERE Id = :addressId
                    LIMIT 1
                ];

                if (address.Address__Latitude__s == null || address.Address__Longitude__s == null) {
                    throw new MissingGeocodeDataException('Geocode data is missing for Address: ' + addressId);
                }

                List<Schema.Location> nearestLocations = [
                    SELECT Id, VisitorAddress.Street, VisitorAddress.City, VisitorAddress.State, VisitorAddress.PostalCode, VisitorAddress.Country,
                           VisitorAddress.Latitude, VisitorAddress.Longitude
                    FROM Location
                    WHERE VisitorAddressId != NULL
                    ORDER BY DISTANCE(VisitorAddress.Address, GEOLOCATION(:address.Address__Latitude__s, :address.Address__Longitude__s), 'km')
                    LIMIT 3
                ];

                if (nearestLocations.isEmpty()) {
                    throw new NoNearbyLocationsFoundException('No nearby Locations found for Address: ' + addressId);
                }

                Decimal closestDistance = null;
                Id nearestLocationId = null;

                for (Schema.Location location : nearestLocations) {
                    String originAddress = address.Address__Street__s + ', ' + address.Address__City__s + ', ' +
                                           address.Address__StateCode__s + ', ' + address.Address__PostalCode__s + ', ' + address.Address__CountryCode__s;

                    String destinationAddress = location.VisitorAddress.Street + ', ' + location.VisitorAddress.City + ', ' +
                                                 location.VisitorAddress.State + ', ' + location.VisitorAddress.PostalCode + ', ' + location.VisitorAddress.Country;

                    Decimal distance = getDistanceFromGoogleMaps(originAddress, destinationAddress);

                    if (distance != null && (closestDistance == null || distance < closestDistance)) {
                        closestDistance = distance;
                        nearestLocationId = location.Id;
                    }
                }

                if (nearestLocationId != null) {
                    result.nearestLocationId = nearestLocationId;
                    result.distance = closestDistance;
                } else {
                    result.nearestLocationId = null;
                    result.distance = null;
                }
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
                result.error = e.getMessage();
            }
            results.add(result);
        }
        System.debug(results);
        return results;
    }

    private static Decimal getDistanceFromGoogleMaps(String origin, String destination) {
        try {
            String apiKey = GoogleMapsSettings__c.getInstance().API_Key__c;
            if (String.isBlank(apiKey)) {
                throw new MissingAPIKeyException('API Key is missing from Custom Setting');
            }

            String url = BASE_URL + '?origins=' + EncodingUtil.urlEncode(origin, 'UTF-8')
                         + '&destinations=' + EncodingUtil.urlEncode(destination, 'UTF-8')
                         + '&key=' + apiKey;

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
                        return Decimal.valueOf((Integer) distance.get('value')) / 1000; // Convert meters to kilometers
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error retrieving distance: ' + e.getMessage());
        }
        return null;
    }

    public class MissingGeocodeDataException extends Exception {}
    public class NoNearbyLocationsFoundException extends Exception {}
    public class MissingAPIKeyException extends Exception {}
    public class APIException extends Exception {}
}