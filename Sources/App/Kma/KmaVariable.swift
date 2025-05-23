import Foundation

/**
 List of all surface Kma variables
 */
enum KmaSurfaceVariable: String, CaseIterable, GenericVariable, GenericVariableMixable {
    case temperature_2m
    /// Note: The provided cloud cover total is way too high
    // case cloud_cover
    case cloud_cover_low
    case cloud_cover_mid
    case cloud_cover_high
    case cloud_cover_2m
    case pressure_msl
    case relative_humidity_2m

    case wind_speed_10m
    case wind_direction_10m
    case wind_speed_50m
    case wind_direction_50m

    case snowfall_water_equivalent
    /// Only downloaded and added to regular snow. Not stored on disk
    case snowfall_water_equivalent_convective
    case showers
    case precipitation

    // case snow_depth_water_equivalent

    case wind_gusts_10m

    case shortwave_radiation
    case direct_radiation

    case surface_temperature
    case cape
    case visibility

    var storePreviousForecast: Bool {
        switch self {
        case .temperature_2m, .relative_humidity_2m: return true
        case .precipitation, .snowfall_water_equivalent: return true
        case .wind_speed_10m, .wind_direction_10m: return true
        case .pressure_msl: return true
        // case .cloud_cover: return true
        case .cloud_cover_mid, .cloud_cover_low, .cloud_cover_high: return true
        case .shortwave_radiation, .direct_radiation: return true
        case .wind_gusts_10m: return true
        case .cape: return true
        case .visibility: return true
        default: return false
        }
    }

    var requiresOffsetCorrectionForMixing: Bool {
        return false
    }

    var omFileName: (file: String, level: Int) {
        return (rawValue, 0)
    }

    var scalefactor: Float {
        switch self {
        case .temperature_2m, .surface_temperature:
            return 20
        case .cloud_cover_low, .cloud_cover_mid, .cloud_cover_high, .cloud_cover_2m:
            return 1
        case .relative_humidity_2m:
            return 1
        case .precipitation, .showers:
            return 10
        case .wind_gusts_10m:
            return 10
        case .pressure_msl:
            return 10
        case .shortwave_radiation, .direct_radiation:
            return 1
        case .snowfall_water_equivalent, .snowfall_water_equivalent_convective:
            return 10
        case .wind_speed_10m, .wind_speed_50m:
            return 10
        case .wind_direction_10m, .wind_direction_50m:
            return 1
        case .cape:
            return 0.1
        case .visibility:
            return 0.05 // 20 metre
        }
    }

    var interpolation: ReaderInterpolation {
        switch self {
        case .temperature_2m, .surface_temperature:
            return .hermite(bounds: nil)
        case .cloud_cover_low, .cloud_cover_mid, .cloud_cover_high, .cloud_cover_2m:
            return .hermite(bounds: 0...100)
        case .pressure_msl:
            return .hermite(bounds: nil)
        case .relative_humidity_2m:
            return .hermite(bounds: 0...100)
        case .precipitation, .showers:
            return .backwards_sum
        case .snowfall_water_equivalent, .snowfall_water_equivalent_convective: // , .snow_depth_water_equivalent:
            return .backwards_sum
        case .wind_gusts_10m:
            return .hermite(bounds: nil)
        case .shortwave_radiation, .direct_radiation:
            return .solar_backwards_averaged
        case .cape:
            return .hermite(bounds: 0...10e9)
        case .visibility:
            return .linear
        case .wind_speed_10m, .wind_speed_50m:
            return .hermite(bounds: 0...10e9)
        case .wind_direction_10m, .wind_direction_50m:
            return .linearDegrees
        }
    }

    var unit: SiUnit {
        switch self {
        case .temperature_2m, .surface_temperature:
            return .celsius
        case .cloud_cover_low, .cloud_cover_mid, .cloud_cover_high, .cloud_cover_2m:
            return .percentage
        case .relative_humidity_2m:
            return .percentage
        case .precipitation, .showers: // , .snow_depth_water_equivalent:
            return .millimetre
        case .wind_gusts_10m:
            return .metrePerSecond
        case .pressure_msl:
            return .hectopascal
        case .shortwave_radiation, .direct_radiation:
            return .wattPerSquareMetre
        case .snowfall_water_equivalent, .snowfall_water_equivalent_convective:
            return .millimetre
        case .cape:
            return .joulePerKilogram
        case .visibility:
            return .metre
        case .wind_speed_10m, .wind_speed_50m:
            return .metrePerSecond
        case .wind_direction_10m, .wind_direction_50m:
            return .degreeDirection
        }
    }

    var isElevationCorrectable: Bool {
        switch self {
        case .temperature_2m, .surface_temperature:
            return true
        default:
            return false
        }
    }
}

/**
 Types of pressure level variables
 */
enum KmaPressureVariableType: String, CaseIterable {
    case temperature
    case wind_u_component
    case wind_v_component
    case geopotential_height
    case relative_humidity
}

/**
 A pressure level variable on a given level in hPa / mb
 */
struct KmaPressureVariable: PressureVariableRespresentable, GenericVariable, Hashable, GenericVariableMixable {
    let variable: KmaPressureVariableType
    let level: Int

    var storePreviousForecast: Bool {
        return false
    }

    var requiresOffsetCorrectionForMixing: Bool {
        return false
    }

    var omFileName: (file: String, level: Int) {
        return (rawValue, 0)
    }

    var scalefactor: Float {
        // Upper level data are more dynamic and that is bad for compression. Use lower scalefactors
        switch variable {
        case .temperature:
            // Use scalefactor of 2 for everything higher than 300 hPa
            return (2..<10).interpolated(atFraction: (300..<1000).fraction(of: Float(level)))
        case .wind_u_component, .wind_v_component:
            // Use scalefactor 3 for levels higher than 500 hPa.
            return (3..<10).interpolated(atFraction: (500..<1000).fraction(of: Float(level)))
        case .geopotential_height:
            return (0.05..<1).interpolated(atFraction: (0..<500).fraction(of: Float(level)))
        case .relative_humidity:
            return (0.2..<1).interpolated(atFraction: (0..<800).fraction(of: Float(level)))
        }
    }

    var interpolation: ReaderInterpolation {
        switch variable {
        case .temperature:
            return .hermite(bounds: nil)
        case .wind_u_component:
            return .hermite(bounds: nil)
        case .wind_v_component:
            return .hermite(bounds: nil)
        case .geopotential_height:
            return .hermite(bounds: nil)
        case .relative_humidity:
            return .hermite(bounds: 0...100)
        }
    }

    var unit: SiUnit {
        switch variable {
        case .temperature:
            return .celsius
        case .wind_u_component:
            return .metrePerSecond
        case .wind_v_component:
            return .metrePerSecond
        case .geopotential_height:
            return .metre
        case .relative_humidity:
            return .percentage
        }
    }

    var isElevationCorrectable: Bool {
        return false
    }
}
/**
 Combined surface and pressure level variables with all definitions for downloading and API
 */
typealias KmaVariable = SurfaceAndPressureVariable<KmaSurfaceVariable, KmaPressureVariable>
