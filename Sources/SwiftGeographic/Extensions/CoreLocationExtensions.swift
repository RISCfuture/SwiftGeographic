#if canImport(CoreLocation)
  import CoreLocation

  // MARK: - GeographicCoordinate

  extension GeographicCoordinate {
    /// The Core Location representation of this coordinate.
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
      CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Creates a geographic coordinate from a Core Location coordinate.
    ///
    /// - Parameter coordinate: A `CLLocationCoordinate2D`.
    /// - Throws: ``SwiftGeographicError`` if the coordinate is invalid.
    public init(_ coordinate: CLLocationCoordinate2D) throws {
      try self.init(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude
      )
    }
  }

  // MARK: - UTMCoordinate

  extension UTMCoordinate {
    /// The Core Location representation, obtained by converting to geographic
    /// coordinates.
    ///
    /// - Throws: ``SwiftGeographicError`` if the conversion fails.
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
      get throws {
        try geographic.clLocationCoordinate2D
      }
    }
  }

  // MARK: - UPSCoordinate

  extension UPSCoordinate {
    /// The Core Location representation, obtained by converting to geographic
    /// coordinates.
    ///
    /// - Throws: ``SwiftGeographicError`` if the conversion fails.
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
      get throws {
        try geographic.clLocationCoordinate2D
      }
    }
  }

  // MARK: - MGRSCoordinate

  extension MGRSCoordinate {
    /// The Core Location representation, obtained by converting to geographic
    /// coordinates.
    ///
    /// - Throws: ``SwiftGeographicError`` if the conversion fails.
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
      get throws {
        try geographic.clLocationCoordinate2D
      }
    }
  }
#endif
