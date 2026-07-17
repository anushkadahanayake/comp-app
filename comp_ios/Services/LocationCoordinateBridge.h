#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// ObjC bridge — Xcode 26 moved CLLocationCoordinate2D members into `_LocationEssentials`,
/// which breaks Swift member access. Keep all lat/lon reads & construction here.
double AFLatitudeFromLocation(CLLocation *location);
double AFLongitudeFromLocation(CLLocation *location);
CLLocationCoordinate2D AFCoordinateMake(double latitude, double longitude);

NS_ASSUME_NONNULL_END
