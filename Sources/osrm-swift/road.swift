//
//  Road.swift
//  
//
//  Created by Dali Hamza on 07.04.24.
//
import Foundation
import MapKit
import Polyline


struct RoadInformation: Equatable {
    let id: String
    let distance: Double
    let seconds: Double
    let encodedRoute: String
}


public struct RoadInstruction {
    var location: CLLocationCoordinate2D
    var instruction: String
}
/**
 * Road
 *
 *  this Class responsible to contain the information need it for poyline or road that we will get from
 *  OSRM API or any other third party API that provider the same service as OSRM
 */
public struct Road : Equatable {
    
    
    var legs: [RoadLeg] = []
    public var distance: Double = 0.0
    public var duration: Double = 0
    public var mRouteHigh: String = ""

    
    public init(json:[String:Any?]) {
        if json.keys.contains("routes") {
            let routes = json["routes"] as! [[String: Any?]]
            routes.forEach { route in
                distance = (route["distance"] as! Double) / 1000
                duration = route["duration"] as! Double
                mRouteHigh = route["geometry"] as! String
                let jsonLegs = route["legs"] as! [[String: Any]]
                jsonLegs.enumerated().forEach { indexLeg,jLeg in
                    var legRoad: RoadLeg = RoadLeg()
                    legRoad.distance = (jLeg["distance"] as! Double) / 1000
                    legRoad.duration = jLeg["duration"] as! Double

                    let jsonSteps = jLeg["steps"] as! [[String: Any?]]
                    jsonSteps.enumerated().forEach { index,step in
                        let maneuver = (step["maneuver"] as! [String: Any?])
                        let location = maneuver["location"] as! [Double]
                        let cLocation = CLLocationCoordinate2D(
                            latitude: (location)[1],
                            longitude: (location)[0]
                        )
                        let roadStep = RoadStep(json: step,location: cLocation)
                        legRoad.steps.append(roadStep)
                        
                    }

                }
            }
        }
    }
    
    public static func == (lhs: Road, rhs: Road) -> Bool {
        lhs.mRouteHigh == rhs.mRouteHigh
    }
   
}

struct RoadLeg {
    /** in km */
    var distance: Double = 0
    /** in sec */
    public var duration: Double = 0
    
    var steps: [RoadStep] = []
}

struct RoadNode {
    var location: CLLocationCoordinate2D
    var instruction: String = ""
    var distance: Double = 0.0
    var duration: Double = 0
    var maneuver: Int = 0
   
    init(location: CLLocationCoordinate2D) {
        self.location = location
    }
}

struct RoadConfig {
    var wayPoints: [GeoPoint]
    var intersectPoints: [GeoPoint]?
    var roadType: RoadType
}



struct RoadStep {
    var location: CLLocationCoordinate2D
    var name: String
    var ref: String?
    var rotaryName: String? = nil
    var destinations: String? = nil
    var exits: String? = nil
    var maneuver: Maneuver
    var duration: Double
    var distance: Double
    var intersections: [Intersections]
    var drivingSide: String

    init(json: [String: Any?],location: CLLocationCoordinate2D) {
        self.location = location
        name = json["name"] as! String? ?? ""
        if json.keys.contains("ref") {
            ref = json["ref"] as? String
        }
        duration = json["duration"] as! Double
        distance = json["distance"] as! Double
        drivingSide = json["driving_side"] as! String
        if json.keys.contains("rotary_name") {
            rotaryName = json["rotary_name"] as? String
        }
        if json.keys.contains("rotary_name") {
            rotaryName = json["rotary_name"] as? String
        }
        if json.keys.contains("destinations") {
            destinations = json["destinations"] as? String
        }
        if json.keys.contains("exits") {
            exits = json["exits"] as! String?
        }

        maneuver = Maneuver(json: json["maneuver"] as! [String: Any?])
        intersections = (json["intersections"] as! [[String: Any]]).map { j -> Intersections in
            Intersections(json: j)
        }
    }
}

struct Intersections {
    var lanes: [Lane]?
    var bearings: [Int]
    var location: CLLocationCoordinate2D

    init(json: [String: Any?]) {
        location = CLLocationCoordinate2D(latitude: (json["location"] as! [Double]).last!,
                longitude: (json["location"] as! [Double]).first!
        )
        bearings = json["bearings"] as! [Int]
        if json.keys.contains("lanes") {
            lanes = (json["lanes"] as! [[String: Any]]).map { value -> Lane in
                Lane(json: value)
            }
        }
    }
}

struct Maneuver {
    var modifier: String?
    var bearingBefore: Double = 0
    var bearingAfter: Double = 0
    var exit: Int? = nil
    var maneuverType: String
    var location: CLLocationCoordinate2D

    init(json: [String: Any?]) {
        location = CLLocationCoordinate2D(latitude: (json["location"] as! [Double]).last!,
                longitude: (json["location"] as! [Double]).first!
        )
        maneuverType = json["type"] as! String
        if (json.keys.contains("modifier")) {
            modifier = json["modifier"] as! String?
        }
        bearingBefore = json["bearing_before"] as! Double
        bearingAfter = json["bearing_after"] as! Double
        if (json.keys.contains("exit")) {
            exit = json["exit"] as! Int?
        }
    }
}

struct Lane {
    var indications: [String]
    var valid: Bool

    init(json: [String: Any?]) {
        indications = json["indications"] as! [String]
        valid = json["valid"] as! Bool
    }
}

extension RoadStep {
    func buildInstruction(instructions: [String: Any], options: [String: Int]) throws -> String {
        var type = maneuver.maneuverType
        let instructionsV5 = instructions["v5"] as! [String: Any]
        if (!instructionsV5.keys.contains(type)) {
            type = "turn"
        }

        var instructionObject = (instructionsV5[type] as! [String: Any])["default"] as! [String: Any]
        let omitSide = type == "off ramp" && ((maneuver.modifier?.index(ofAccessibilityElement: drivingSide) ?? 0) >= 0);
        if maneuver.modifier != nil && (instructionsV5[type] as! [String: Any]).keys.contains(maneuver.modifier!) && !omitSide {
            instructionObject = (instructionsV5[type] as! [String: Any])[maneuver.modifier!] as! [String: Any]
        }
        var laneInstruction: String?
        switch (maneuver.maneuverType) {
        case "use lane":
            let lane = laneConfig()
            if (lane != nil) {
                laneInstruction = (((instructionsV5[type] as! [String: Any])["constants"] as! [String: Any])["lanes"] as! [String: String])[lane!]
            } else {
                instructionObject = ((instructionsV5[type] as! [String: Any])[maneuver.maneuverType] as! [String: Any])["no_lanes"] as! [String: Any]
            }
            break;
        case "rotary", "roundabout":
            if (rotaryName != nil && maneuver.exit != nil && instructionObject.keys.contains("name_exit")) {
                instructionObject = instructionObject["name_exit"] as! [String: Any]
            } else if (rotaryName != nil && instructionObject.keys.contains("name")) {
                instructionObject = instructionObject["name"] as! [String: Any]
            } else if (maneuver.exit != nil && instructionObject.keys.contains("exit")) {
                instructionObject = instructionObject["exit"] as! [String: Any]
            } else {
                instructionObject = instructionObject["default"] as! [String: Any]
            }
            break;
        default:
            break;
        }
        let name = retrieveName()
        var instruction = instructionObject["default"] as! String
        if destinations != nil && exits != nil && instructionObject.keys.contains("exit_destination") {
            instruction = instructionObject["exit_destination"] as! String
        } else if destinations != nil && instructionObject.keys.contains("destination") {
            instruction = instructionObject["destination"] as! String
        } else if exits != nil && instructionObject.keys.contains("exit") {
            instruction = instructionObject["exit"] as! String
        } else if !name.isEmpty && instructionObject.keys.contains("name") {
            instruction = instructionObject["name"] as! String
        }
        var firstDestination: String? = nil
        do {
            if destinations != nil {
                let destinationSplits = destinations!.split(separator: ":")
                let destinationRef = try destinationSplits.first?.split(separator: ",").first
                if destinationSplits.count > 1 {
                    let destination = try destinationSplits[1].split(separator: ",").first
                        firstDestination = "\(destinationRef ?? destination ?? "")"
                    if let destination = destination, let destinationRef = destinationRef {
                        firstDestination = "\(destinationRef): \(destination)"
                    }else{
                        if let destination = destination {
                            firstDestination = "\(String(describing: destinationRef)): \(destination)"
                        }else if let destinationRef = destinationRef {
                            firstDestination = "\(destinationRef)"
                        }
                    }
                }else{
                    firstDestination = String("\(destinationRef ?? "")")
                }
            }
        } catch let e {
            print(e)
            throw  OSRMManagerError.ParseResponse("\(e)")
        }

        var modifierInstruction = ""
        if let modifier = maneuver.modifier {
            modifierInstruction = ((instructionsV5["constants"] as! [String: Any])["modifier"] as! [String: String])[modifier]!
        }
        var nthWaypoint = ""
        if options["legIndex"]! >= 0 && options["legIndex"]! != options["legCount"]! {
            let key = "\(options["legIndex"]! + 1)"
            nthWaypoint = ordinalize(instructionsV5: instructionsV5, key: key) ?? ""
        }
        var exitOrdinalise = ""
        if let exit = maneuver.exit {
            exitOrdinalise = ordinalize(instructionsV5: instructionsV5, key: "\(exit)") ?? ""
        }
        let outputInstruction = tokenize(instruction: instruction, tokens: [
            "way_name": name,
            "destination": firstDestination ?? "",
            "exit": String(exits?.split(separator: ";").first ?? ""),
            "exit_number": exitOrdinalise,
            "rotary_name": rotaryName ?? "",
            "lane_instruction": laneInstruction ?? "",
            "modifier": modifierInstruction,
            "direction": directionFromDegree(degree: maneuver.bearingBefore),
            "nth": nthWaypoint
        ] as [String: String])
        return outputInstruction
    }

    private func ordinalize(instructionsV5: [String: Any], key: String) -> String? {
        ((instructionsV5["constants"] as! [String: Any])["ordinalize"] as! [String: String])[key]
    }

    private func tokenize(instruction: String, tokens: [String: String]) -> String {

        var output: String = instruction
        tokens.forEach { (key, value) in
            if output.contains(key) && !value.isEmpty {
                output = output.replacingOccurrences(of: "{\(key)}", with: value)
            } else if output.contains(key) && value.isEmpty {
                output = output.replacingOccurrences(of: "{\(key)}", with: "")
            }
        }
        output = output.replacingOccurrences(of: " {2}", with: " ", options: .regularExpression)

        return output
    }

    private func retrieveName() -> String {
        let refN = ref?.split(separator: ";").first
        var n = name
        if (refN != nil && refN! == n) {
            n = ""
        }
        if !n.isEmpty && refN != nil {
            return "\(name) (\(refN!))"
        }
        return name
    }

    private func directionFromDegree(degree: Double?) -> String {
        if (degree != nil) {
            // step had no bearing_after degree,
            return "";
        } else if (degree! >= 0 && degree! <= 20) {
            return "north";
        } else if (degree! > 20 && degree! < 70) {
            return "northeast";
        } else if (degree! >= 70 && degree! <= 110) {
            return "east";
        } else if (degree! > 110 && degree! < 160) {
            return "southeast";
        } else if (degree! >= 160 && degree! <= 200) {
            return "south";
        } else if (degree! > 200 && degree! < 250) {
            return "southwest";
        } else if (degree! >= 250 && degree! <= 290) {
            return "west";
        } else if (degree! > 290 && degree! < 340) {
            return "northwest";
        } else if (degree! >= 340 && degree! <= 360) {
            return "north";
        } else {
            return ""
        }
    }

    private func laneConfig() -> String? {
        if (intersections.isEmpty || (intersections.first?.lanes == nil)) {
            return nil
        }
        var config: [String] = []
        var validity: Bool? = nil
        intersections.first?.lanes?.forEach { lane in
            if validity == nil || validity != lane.valid {
                if (lane.valid) {
                    config.append("o")
                } else {
                    config.append("x")
                }
                validity = lane.valid
            }
        }
        return config.joined()
    }

    /*private func buildInstruction(_ maneuver: Int, _ name: String, _ direction: String) -> String {

        var instruction = DIRECTIONS[maneuver]!["en"]!

        if (name.isEmpty) {
            instruction = instruction.replacingOccurrences(of: "\\[.+\\]", with: "", options: .regularExpression)
        } else {
            instruction = instruction.replacingOccurrences(of: "[", with: "")
            instruction = instruction.replacingOccurrences(of: "]", with: "")
            instruction = instruction.replacingOccurrences(of: "%s", with: name)

        }
        if (instruction.contains("{direction}")) {
            instruction = instruction.replacingOccurrences(of: "\\{.+\\}", with: direction, options: .regularExpression)
        }


        return instruction
    }*/
}
