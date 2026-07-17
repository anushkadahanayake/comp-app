#import "LocationCoordinateBridge.h"

double AFLatitudeFromLocation(CLLocation *location) {
    return location.coordinate.latitude;
}

double AFLongitudeFromLocation(CLLocation *location) {
    return location.coordinate.longitude;
}

CLLocationCoordinate2D AFCoordinateMake(double latitude, double longitude) {
    return CLLocationCoordinate2DMake(latitude, longitude);
}
