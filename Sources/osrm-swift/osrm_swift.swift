// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import Alamofire
import MapKit
import Polyline

typealias ParserJson = ([String: Any?]?) -> Road
public typealias RoadHandler = (Road?) -> Void
public typealias json = [String: Any?]

public enum RoadType: String {
    case car = "routed-car"
    case bike = "routed-bike"
    case foot = "routed-foot"
}
public enum Languages: String {
    case en = "en"
}
public struct InputRoadConfiguration {
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

    func getRoadAsync(wayPoints: [CLLocationCoordinate2D],
                      configuration: InputRoadConfiguration) async throws -> Road?
    func getRoad(wayPoints: [CLLocationCoordinate2D], configuration: InputRoadConfiguration,
               completion:@escaping RoadHandler)
    func buildInstruction(road:Road,language:Languages)throws -> [RoadInstruction]
    
}
public enum OSRMManagerError:Error {
    case NOTSecuredURL(String)
    case ParseResponse(String)
    case ErrorToLoadLanguageResources
}
/// OSRMManager
///
///  this class is OSRM manager where we use open source OSRM server to find routing (route)
///  using OSRMManager you can retrieve road between 2 geographic points and as well retrieve instruction of that route
///  make in consideration that our function
///
public class OSRMManager: PRoadManager {

    private var session = Session.default
    let baseOSRMURL:String
    public init(baseOSRMURL: String = "https://routing.openstreetmap.de") throws {
        if baseOSRMURL.contains("http://") {
            throw OSRMManagerError.NOTSecuredURL("use https for open source osrm server, if you're using your own server please use lets encrypt")
        }
        self.baseOSRMURL = if baseOSRMURL.contains("https") {
            baseOSRMURL
        }else {
            "https://\(baseOSRMURL)"
        }
    }
    /// getRoad
    ///
    /// this function will call our routing server to return  [Road]
    /// where it accept List of [CLLocationCoordinate2D] and using [RoadConfiguration] you can configure the request
    ///
    /// this function will return the desired Object using the completion handler (if you want to use async await use our method [getRoadAsync]
    func getRoad(wayPoints: [CLLocationCoordinate2D], configuration: InputRoadConfiguration, completion: @escaping RoadHandler){
        let serverURL = buildURL(wayPoints, configuration)
        DispatchSerialQueue.main.async {
            self.httpCall(url: serverURL) { jsonM in
                if let map = jsonM {
                    let road = self.parserRoad(json: map)
                    completion(road)
                }else{
                    completion(nil)
                }
              
            }
        }
    }
    /// getRoadAsync
    ///
    /// this is async  function for getRoad
    public func getRoadAsync(wayPoints: [CLLocationCoordinate2D],
                             configuration: InputRoadConfiguration) async -> Road? {
        do {
            let serverURL = buildURL(wayPoints, configuration)
            return try await withCheckedThrowingContinuation { continuation in
                self.httpCall(url: serverURL) { jsonM in
                    if let map = jsonM {
                        let road = self.parserRoad(json: map)
                        continuation.resume(returning: road)
                    }else{
                        continuation.resume(throwing: RoadError.emptyResult)
                    }
                }
            }
        } catch {//AFError
            //print("Caught an unexpected error: \(error)")
            return nil
        }
    }
    /// buildInstruction
    ///
    /// this function will generate instruction of latest searched road
    public func buildInstruction(road: Road, language: Languages) throws ->[RoadInstruction] {
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
                        "legIndex":index , "legCount" : roadSteps.count - 1
                    ])
                    instructions.append(RoadInstruction(location: step.location, instruction: instruction))
                }
            }
        } catch let e {
            print(e)
        }
            
        return []
    }

}
extension OSRMManager {
     func buildURL(_ waysPoints: [CLLocationCoordinate2D], _ configuration: InputRoadConfiguration) -> String {
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
    private func httpCall(url: String, parseHandler: @escaping (_ json: [String: Any?]?) -> Void)  {
        let parameters: [String: [String]] = [:]
        print("httpCall \(url)")
        session.request(url, method: .get,parameters: parameters
                        /*,encoder: JSONParameterEncoder.default*/).responseJSON { response in
            if response.data != nil {
                let data = response.value as? [String: Any?]
                parseHandler(data)
            } else {
                parseHandler(nil)
            }
        }
    }
    private func httpCallAsync(url: String) async throws ->  json? {
        return try await withCheckedThrowingContinuation { continuation in
            let parameters: [String: [String]] = [:]
            session.request(url, method: .get,parameters: parameters,encoder: JSONParameterEncoder.prettyPrinted).responseData { response in
                if response.data != nil {
                    let data = response.value as? [String: Any?]?
                    continuation.resume(returning: data!)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    private func parserRoad(json: [String: Any?]) -> Road {
       Road(json: json)
    }

    internal func setAFSession(urlSessionConf:URLSessionConfiguration){
        session = Session(configuration: urlSessionConf)
    }
}
