#if canImport(Foundation)
  import Foundation

  // MARK: - GeographicCoordinate

  extension GeographicCoordinate {
    /// The latitude as a `Measurement<UnitAngle>` in degrees.
    public var latitudeAngle: Measurement<UnitAngle> {
      Measurement(value: latitude, unit: .degrees)
    }

    /// The longitude as a `Measurement<UnitAngle>` in degrees.
    public var longitudeAngle: Measurement<UnitAngle> {
      Measurement(value: longitude, unit: .degrees)
    }
  }

  // MARK: - UTMCoordinate

  extension UTMCoordinate {
    /// The easting as a `Measurement<UnitLength>` in meters.
    public var eastingDistance: Measurement<UnitLength> {
      Measurement(value: easting, unit: .meters)
    }

    /// The northing as a `Measurement<UnitLength>` in meters.
    public var northingDistance: Measurement<UnitLength> {
      Measurement(value: northing, unit: .meters)
    }

    /// The central meridian longitude as a `Measurement<UnitAngle>` in degrees.
    public var centralMeridianAngle: Measurement<UnitAngle> {
      Measurement(value: centralMeridian, unit: .degrees)
    }
  }

  // MARK: - UPSCoordinate

  extension UPSCoordinate {
    /// The easting as a `Measurement<UnitLength>` in meters.
    public var eastingDistance: Measurement<UnitLength> {
      Measurement(value: easting, unit: .meters)
    }

    /// The northing as a `Measurement<UnitLength>` in meters.
    public var northingDistance: Measurement<UnitLength> {
      Measurement(value: northing, unit: .meters)
    }
  }

  // MARK: - MGRSCoordinate

  extension MGRSCoordinate {
    /// The easting within the 100 km square as a `Measurement<UnitLength>`.
    public var eastingDistance: Measurement<UnitLength> {
      Measurement(value: easting, unit: .meters)
    }

    /// The northing within the 100 km square as a `Measurement<UnitLength>`.
    public var northingDistance: Measurement<UnitLength> {
      Measurement(value: northing, unit: .meters)
    }
  }

  // MARK: - ProjectionResult

  extension ProjectionResult {
    /// The meridian convergence as a `Measurement<UnitAngle>` in degrees.
    public var convergenceAngle: Measurement<UnitAngle> {
      Measurement(value: convergence, unit: .degrees)
    }
  }

  // MARK: - MGRSPrecision

  extension MGRSPrecision {
    /// The ground resolution as a `Measurement<UnitLength>` in meters.
    public var resolutionDistance: Measurement<UnitLength> {
      Measurement(value: resolution, unit: .meters)
    }
  }
#endif
