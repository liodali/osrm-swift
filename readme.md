
# OSRM Swift Package


![swift-package](https://img.shields.io/badge/0.1.0-orange)

* this package is wrapping for orsm server,where we trying to simplify make in request and retrive the instruction of the route


### installation

```
                 
dependencies: [
    .package(url: "https://github.com/liodali/osrm-swift.git",from:"[latest version]")
    ]
                                 
```

### Usage

```swift
  let osrmManager = try OSRMManager()
  // prepare geopoints
  let coords = "13.388860,52.517037;13.397634,52.529407;13.428555,52.523219".toWaypoints()
  //using Async function
  let roadData =  try await  osrmManager.getRoadAsync(wayPoints: coords, roadConfiguration: RoadConfiguration())
   //using normal function
   osrmManager.getRoadAsync(wayPoints: coords, roadConfiguration: RoadConfiguration()){ roadData in
     // apply your logic here
    }
                 
```
### Retrieve Instruction

 ```swift
     
    let instructions = osrmManager.buildInstruction(road:roadData,language:Language.de)
                                  
 ```
