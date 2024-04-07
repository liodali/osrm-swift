// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import Alamofire
import MapKit
import Polyline

typealias ParserJson = ([String: Any?]?) -> Road
public typealias RoadHandler = (Road?) -> Void


public enum RoadType: String {
    case car = "routed-car"
    case bike = "routed-bike"
    case foot = "routed-foot"
}
public enum Languages: String {
    case en = "en"
}
public struct RoadConfiguration {
    let typeRoad: RoadType
    let overview:Overview
    let geometrie:Geometries
    let alternative: Bool
    let steps: Bool
    public init(typeRoad: RoadType = RoadType.car,overview:Overview = Overview.full,geometrie:Geometries = Geometries.polyline, steps:Bool = true,alternative: Bool = false){
        self.typeRoad = typeRoad
        self.overview = overview
        self.geometrie = geometrie
        self.steps = steps
        self.alternative = alternative
    }
}

protocol PRoadManager {

    func getRoad(wayPoints: [CLLocationCoordinate2D], roadConfiguration: RoadConfiguration, handler: @escaping RoadHandler)
    func buildInstruction(road:Road,language:Languages)throws -> [RoadInstruction]
    
}
public enum OSRMManagerError:Error {
    case NOTSecuredURL(String)
    case ParseResponse(String)
    case ErrorToLoadLanguageResources
}

public class OSRMManager: PRoadManager {
    
   
    let baseOSRMURL:String
    public init(baseOSRMURL: String) throws {
        if baseOSRMURL.contains("http://") {
            throw OSRMManagerError.NOTSecuredURL("use https for open source osrm server, if you're using your own server please use lets encrypt")
        }
        self.baseOSRMURL = if baseOSRMURL.contains("https") {
            baseOSRMURL
        }else {
            "https://\(baseOSRMURL)"
        }
    }
    public func getRoad(wayPoints: [CLLocationCoordinate2D],roadConfiguration: RoadConfiguration,  handler: @escaping RoadHandler) {
        let serverURL = buildURL(wayPoints, roadConfiguration)
        guard let url = Bundle(for: type(of: self)).url(forResource: "en",
                                                        withExtension: "json") else {
            return print("File not found")
        }
        var contentLangEn: [String:Any] = [String:Any]()
        do {
            let data = try String(contentsOf: url).data(using: .utf8)
            contentLangEn = parse(jsonData: data)
        } catch let error {
            print(error)
        }

        DispatchQueue.global(qos: .background).async {
            self.httpCall(url: serverURL) { json in
                if json != nil {
                    let road = self.parserRoad(json: json!, instructionResource: contentLangEn)
                    DispatchQueue.main.async {
                        handler(road)
                    }
                } else {
                    DispatchQueue.main.async {
                        handler(nil)
                    }
                }
            }
        }
    }
    
    public func buildInstruction(road: Road, language: Languages)throws ->[RoadInstruction] {
        let legs = road.legs
        let roadSteps = road.legs
        let instructionHelper = readResources(resourceName:language.rawValue)
        var instructions:[RoadInstruction] = [RoadInstruction]()
        if  instructionHelper == nil {
            throw OSRMManagerError.ErrorToLoadLanguageResources
        }
        do {
            for (index,leg) in roadSteps.enumerated() {
                for step in leg.steps {
                    let instruction =  try step.buildInstruction(instructions: instructionHelper!, options: [
                        "legIndex":index , "legCount" : road.legs.count - 1
                    ])
                    instructions.append(RoadInstruction(location: step.location, instruction: instruction))
                }
            }
        } catch let e {
            
        }
            
        return []
    }
    
    
    
}
extension OSRMManager {
     func buildURL(_ waysPoints: [CLLocationCoordinate2D], _ configuration: RoadConfiguration) -> String {
        var server = baseOSRMURL
        if server.last == "/" {
            server.removeLast()
        }
        let  serverBaseURL = "\(baseOSRMURL)/\(configuration.typeRoad.rawValue)/route/v1/driving/"
        let points = waysPoints.toString()
         return "\(serverBaseURL)\(points)?steps=\(configuration.steps)&overview=\(configuration.overview.rawValue)&geometries=\(configuration.geometrie.rawValue)&alternatives=\(configuration.alternative)"
    }
     func parse(jsonData: Data?) -> [String:Any] {
        if jsonData == nil {
            return [String:Any]()
        }
        do {
            let decodedData = try JSONSerialization.jsonObject(with: jsonData!)
            return decodedData as! [String:Any]
        } catch {
            print("decode error")
        }
        return [String:Any]()
    }
    private func httpCall(url: String, parseHandler: @escaping (_ json: [String: Any?]?) -> Void) {
        let parameters: [String: [String]] = [:]
        AF.request(url, method: .get,parameters: parameters,encoder: JSONParameterEncoder.prettyPrinted).responseData { response in
            if response.data != nil {
                let data = response.value as? [String: Any?]?
                parseHandler(data!)
            } else {
                parseHandler(nil)
            }
        }
    }

    private func parserRoad(json: [String: Any?], instructionResource: [String:Any]) -> Road {
       Road(json: json)
    }
}
