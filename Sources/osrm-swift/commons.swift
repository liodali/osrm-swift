//
//  coomons.swift
//  
//
//  Created by Dali Hamza on 07.04.24.
//

import Foundation
import MapKit

typealias GeoPoint = [String: Double]

public enum Overview: String {
  case simplified = "simplified"
  case full = "full"
  case none = "none"
}

public enum Geometries: String {
  case polyline = "polyline"
  case polyline6 = "polyline6"
  case geojson = "geojson"
}

let MANEUVERS: Dictionary<String, Int> = [
    "new name": 2,
    "turn-straight": 1,
    "turn-slight right": 6,
    "turn-right": 7,
    "turn-sharp right": 8,
    "turn-uturn": 12,
    "turn-sharp left": 5,
    "turn-left": 4,
    "turn-slight left": 3,
    "depart": 25,
    "arrive": 24,
    "roundabout-1": 27,
    "roundabout-2": 28,
    "roundabout-3": 29,
    "roundabout-4": 30,
    "roundabout-5": 31,
    "roundabout-6": 32,
    "roundabout-7": 33,
    "roundabout-8": 34,
    "merge-left": 20,
    "merge-sharp left": 20,
    "merge-slight left": 20,
    "merge-right": 21,
    "merge-sharp right": 21,
    "merge-slight right": 21,
    "merge-straight": 22,
    "ramp-left": 17,
    "ramp-sharp left": 17,
    "ramp-slight left": 17,
    "ramp-right": 18,
    "ramp-sharp right": 18,
    "ramp-slight right": 18,
    "ramp-straight": 19
];

let DIRECTIONS = [
    1: ["en": "Continue[ on %s]", "de": ""],
    2: ["en": "[Go on %s]", "de": ""],
    3: ["en": "Turn slight left[ on %s]", "de": ""],
    4: ["en": "Turn left[ on %s]", "de": ""],
    5: ["en": "Turn sharp left[ on %s]", "de": ""],
    6: ["en": "Turn slight right[ on %s]", "de": ""],
    7: ["en": "Turn right[ on %s]", "de": ""],
    8: ["en": "Turn sharp right[ on %s]", "de": ""],
    12: ["en": "U-Turn[ on %s]", "de": ""],
    17: ["en": "Take the ramp on the left[ on %s]", "de": ""],
    18: ["en": "Take the ramp on the right[ on %s", "de": ""],
    19: ["en": "Take the ramp straight ahead[ on %s]", "de": ""],
    24: ["en": "You have reached a waypoint of your trip", "de": ""],
    25: ["en": "Head {direction} [on %s]", "de": ""],
    27: ["en": "Enter roundabout and leave at first exit[ on %s]", "de": ""],
    28: ["en": "Enter roundabout and leave at second exit[ on %s]", "de": ""],
    29: ["en": "Enter roundabout and leave at third exit[ on %s]", "de": ""],
    30: ["en": "Enter roundabout and leave at fourth exit[ on %s]", "de": ""],
    31: ["en": "Enter roundabout and leave at fifth exit[ on %s]", "de": ""],
    32: ["en": "Enter roundabout and leave at sixth exit[ on %s]", "de": ""],
    33: ["en": "Enter roundabout and leave at seventh exit[ on %s]", "de": ""],
    34: ["en": "Enter roundabout and leave at eighth exit[ on %s]", "de": ""],
]

func readResources(resourceName:String,ext:String = "json")->[String : Any]?{
    do {
        if let bundlePath = Bundle.main.path(forResource: resourceName, ofType: ext),
          let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
             if let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
                return json
             } else {
                print("Given JSON is not a valid dictionary object.")
                 return nil
             }
          }
       } catch {
          print(error)
       }
    return nil
}

extension Array where Element == CLLocationCoordinate2D {
    func toString()-> String {
        map { location in
            "\(location.longitude),\(location.latitude)"
        }.joined(separator: ";")
    }
}
