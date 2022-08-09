import Foundation
import Vapor


/**
 
 NCEP CFSv2 https://nomads.ncep.noaa.gov/pub/data/nccf/com/cfs/prod/cfs.20220808/00/
 https://rda.ucar.edu/datasets/ds094.0/#metadata/grib2.html?_do=y
 
 requires jpeg2000 support for eccodes, brew needs to rebuild
 brew edit eccodes
 set DENABLE_JPG_LIBJASPER to ON
 brew reinstall eccodes --build-from-source
 */
struct SeasonalForecastDownload: Command {
    struct Signature: CommandSignature {
        @Argument(name: "domain")
        var domain: String
        
        @Flag(name: "skip-existing")
        var skipExisting: Bool
    }

    var help: String {
        "Download seasonal forecasts from Copernicus"
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        guard let domain = SeasonalForecastDomain.init(rawValue: signature.domain) else {
            fatalError("Invalid domain '\(signature.domain)'")
        }
    }
}