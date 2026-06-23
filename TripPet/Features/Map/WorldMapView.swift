import SwiftUI

struct WorldMapView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        GeometryReader { proxy in
            let signWidth = min(proxy.size.width * 0.76, 330)
            let signHeight = signWidth * 0.34
            let topReserve = proxy.safeAreaInsets.top + 70
            let bottomReserve = proxy.safeAreaInsets.bottom + 96
            let globeSignGap: CGFloat = 30
            let availableGlobeHeight = proxy.size.height - topReserve - bottomReserve - signHeight - globeSignGap
            let globeDiameter = min(proxy.size.width * 0.88, max(240, availableGlobeHeight), 390)

            ZStack {
                MapCosmicBackground()

                VStack(spacing: globeSignGap) {
                    Spacer()
                        .frame(height: topReserve)

                    TravelGlobeView(routes: globeRoutes)
                        .frame(width: globeDiameter, height: globeDiameter)
                        .accessibilityLabel(accessibilitySummary)

                    travelCountSign(width: signWidth)

                    Spacer()
                        .frame(minHeight: bottomReserve)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }

    private var activeTravelAnimalCount: Int {
        environment.repository.activeTravelTrips.prefix(9).count
    }

    private var accessibilitySummary: String {
        "\(activeTravelAnimalCount)只小动物从小屋出发旅行中，可拖动旋转地球查看路线"
    }

    private func travelCountSign(width: CGFloat) -> some View {
        ZStack {
            ArtImage(name: "map_travel_count_sign")
                .frame(width: width, height: width * 0.34)

            Text("\(activeTravelAnimalCount)只小动物在旅行中")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .padding(.horizontal, width * 0.18)
                .padding(.top, 2)
        }
        .frame(width: width, height: width * 0.34)
        .shadow(color: AppTheme.oliveInk.opacity(0.18), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activeTravelAnimalCount)只小动物在旅行中")
    }

    private var globeRoutes: [TravelGlobeRoute] {
        environment.repository.activeTravelTrips.prefix(9).enumerated().compactMap { index, trip in
            let manifestDestination = environment.destination(for: trip)
            guard let destinationCoordinate = GlobeCoordinate.coordinate(
                for: trip.destinationId,
                destination: manifestDestination
            ) else {
                return nil
            }

            let animal = environment.repository.animal(for: trip.animalId)
            return TravelGlobeRoute(
                id: trip.id,
                animalName: animal?.name ?? environment.repository.animalName(for: trip.animalId),
                destination: trip.destination,
                animalAssetName: animal?.travelMarkerAssetName ?? "animal_visitor_unknown",
                origin: .cottage,
                destinationCoordinate: destinationCoordinate,
                departedAt: trip.departedAt,
                expectedReturnAt: trip.expectedReturnAt,
                tint: TravelGlobeRoute.palette[index % TravelGlobeRoute.palette.count]
            )
        }
    }
}

private struct MapCosmicBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.13, green: 0.17, blue: 0.29)

                Image("map_journal_night_sky_final")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                Image("texture_paper_grain")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(0.05)
                    .clipped()
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

struct TravelGlobeView: View {
    let routes: [TravelGlobeRoute]

    @State private var orientation = GlobeOrientation.defaultReadable
    @State private var dragStartOrientation: GlobeOrientation?

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = diameter * 0.49
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let projection = GlobeProjection(center: center, radius: radius, orientation: orientation)

            TimelineView(.periodic(from: Date(), by: 30)) { timeline in
                ZStack {
                    globeSurface(diameter: diameter)
                    GlobeGridView(projection: projection)
                    routeLayer(projection: projection, date: timeline.date)
                    globeShading(diameter: diameter)
                    markerLayer(projection: projection, date: timeline.date)
                }
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
                .gesture(rotationGesture(diameter: diameter))
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }

    private func globeSurface(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.paperWhite.opacity(0.98),
                            Color(red: 0.62, green: 0.82, blue: 0.82).opacity(0.94),
                            Color(red: 0.34, green: 0.67, blue: 0.76)
                        ],
                        center: .topLeading,
                        startRadius: diameter * 0.08,
                        endRadius: diameter * 0.62
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.77, green: 0.91, blue: 0.83).opacity(0.30),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.34, y: 0.28),
                        startRadius: 4,
                        endRadius: diameter * 0.42
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.55, blue: 0.67).opacity(0.22),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.76, y: 0.78),
                        startRadius: 8,
                        endRadius: diameter * 0.45
                    )
                )

            Image("world_travel_map")
                .resizable()
                .scaledToFill()
                .frame(width: diameter * 2.30, height: diameter * 1.22)
                .offset(x: textureOffset(width: diameter * 2.30))
                .saturation(1.08)
                .contrast(1.10)
                .brightness(-0.02)
                .opacity(0.40)
                .blendMode(.multiply)
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.61, green: 0.79, blue: 0.74).opacity(0.16)
                        ],
                        center: .center,
                        startRadius: diameter * 0.16,
                        endRadius: diameter * 0.54
                    )
                )
                .blendMode(.multiply)

            Image("texture_paper_grain")
                .resizable()
                .scaledToFill()
                .frame(width: diameter, height: diameter)
                .opacity(0.16)
                .clipShape(Circle())
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .compositingGroup()
        .overlay {
            Circle()
                .stroke(Color(red: 0.18, green: 0.37, blue: 0.45).opacity(0.30), lineWidth: 9)
                .blur(radius: 1.6)
        }
        .overlay {
            Circle()
                .stroke(AppTheme.paperWhite.opacity(0.82), lineWidth: 1.8)
        }
        .overlay {
            Circle()
                .stroke(Color(red: 0.73, green: 0.90, blue: 0.92).opacity(0.26), lineWidth: 14)
                .blur(radius: 4)
        }
        .shadow(color: Color(red: 0.03, green: 0.05, blue: 0.10).opacity(0.28), radius: 18, x: 0, y: 14)
    }

    private func routeLayer(projection: GlobeProjection, date: Date) -> some View {
        ZStack {
            ForEach(routes) { route in
                let segments = route.visibleSegments(projection: projection)
                ForEach(segments.indices, id: \.self) { index in
                    Path { path in
                        guard let first = segments[index].first else { return }
                        path.move(to: first)
                        segments[index].dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(
                        route.tint.opacity(0.78),
                        style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round, dash: [7, 6])
                    )
                    .shadow(color: route.tint.opacity(0.22), radius: 5, x: 0, y: 2)
                }
            }
        }
        .frame(width: projection.center.x * 2, height: projection.center.y * 2)
        .clipShape(Circle())
    }

    private func markerLayer(projection: GlobeProjection, date: Date) -> some View {
        ZStack {
            if let cottagePoint = projection.project(.cottage), cottagePoint.isVisible {
                CottageMarker()
                    .position(cottagePoint.point)
            }

            ForEach(routes) { route in
                if let planeCoordinate = route.coordinate(at: date),
                   let projectedPlane = projection.project(planeCoordinate),
                   projectedPlane.isVisible {
                    PaperPlaneMarker(tint: route.tint)
                        .rotationEffect(.degrees(route.planeAngle(at: date, projection: projection)))
                        .position(projectedPlane.point)
                        .opacity(0.92)
                }

                if let destinationPoint = projection.project(route.destinationCoordinate),
                   destinationPoint.isVisible {
                    AnimalDestinationMarker(route: route)
                        .position(destinationPoint.point)
                }
            }
        }
        .frame(width: projection.center.x * 2, height: projection.center.y * 2)
    }

    private func globeShading(diameter: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.32),
                        Color.white.opacity(0.04),
                        Color(red: 0.06, green: 0.12, blue: 0.18).opacity(0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.multiply)
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.04, green: 0.09, blue: 0.14).opacity(0.24)
                            ],
                            center: UnitPoint(x: 0.82, y: 0.82),
                            startRadius: diameter * 0.10,
                            endRadius: diameter * 0.56
                        )
                    )
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white.opacity(0.26))
                    .frame(width: diameter * 0.36, height: diameter * 0.20)
                    .blur(radius: 12)
                    .offset(x: diameter * 0.18, y: diameter * 0.16)
            }
            .frame(width: diameter, height: diameter)
            .allowsHitTesting(false)
    }

    private func rotationGesture(diameter: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStartOrientation == nil {
                    dragStartOrientation = orientation
                }
                guard let start = dragStartOrientation else { return }
                orientation = start.applyingDrag(value.translation, diameter: diameter)
            }
            .onEnded { value in
                guard let start = dragStartOrientation else { return }
                orientation = start.applyingDrag(value.translation, diameter: diameter)
                dragStartOrientation = nil
            }
    }

    private func textureOffset(width: CGFloat) -> CGFloat {
        let normalized = CGFloat((orientation.centerLongitude + 180) / 360)
        return (0.5 - normalized) * width * 0.46
    }
}

private struct GlobeGridView: View {
    let projection: GlobeProjection

    var body: some View {
        ZStack {
            ForEach([-60, -30, 0, 30, 60], id: \.self) { latitude in
                gridPath(coordinates: stride(from: -180, through: 180, by: 4).map {
                    GlobeCoordinate(latitude: Double(latitude), longitude: Double($0))
                })
                .stroke(AppTheme.paperWhite.opacity(latitude == 0 ? 0.34 : 0.20), lineWidth: latitude == 0 ? 0.9 : 0.62)
            }

            ForEach(stride(from: -150, through: 180, by: 30).map { $0 }, id: \.self) { longitude in
                gridPath(coordinates: stride(from: -84, through: 84, by: 4).map {
                    GlobeCoordinate(latitude: Double($0), longitude: Double(longitude))
                })
                .stroke(AppTheme.paperWhite.opacity(0.17), lineWidth: 0.58)
            }
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    private func gridPath(coordinates: [GlobeCoordinate]) -> Path {
        Path { path in
            var currentSegmentHasPoint = false

            for coordinate in coordinates {
                guard let projected = projection.project(coordinate), projected.isVisible else {
                    currentSegmentHasPoint = false
                    continue
                }

                if currentSegmentHasPoint {
                    path.addLine(to: projected.point)
                } else {
                    path.move(to: projected.point)
                    currentSegmentHasPoint = true
                }
            }
        }
    }
}

private struct CottageMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.ochre.opacity(0.92))
                .frame(width: 19, height: 19)
                .overlay(Circle().stroke(AppTheme.paperWhite, lineWidth: 2))
                .shadow(color: AppTheme.ochre.opacity(0.42), radius: 8, x: 0, y: 3)

            Image(systemName: "house.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(AppTheme.paperWhite)
        }
        .accessibilityHidden(true)
    }
}

private struct PaperPlaneMarker: View {
    let tint: Color

    var body: some View {
        Image(systemName: "paperplane.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppTheme.paperWhite)
            .shadow(color: tint.opacity(0.85), radius: 4, x: 0, y: 2)
            .overlay {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.84))
                    .offset(x: 0.8, y: 0.8)
                    .blendMode(.multiply)
            }
            .accessibilityHidden(true)
    }
}

private struct AnimalDestinationMarker: View {
    let route: TravelGlobeRoute

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.paperWhite.opacity(0.96))
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(route.tint.opacity(0.9), lineWidth: 2))
                .shadow(color: AppTheme.oliveInk.opacity(0.22), radius: 10, x: 0, y: 5)

            ArtImage(name: route.animalAssetName)
                .frame(width: 38, height: 38)
                .clipShape(Circle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(route.animalName)正在前往\(route.destination)")
    }
}

struct TravelGlobeRoute: Identifiable {
    let id: String
    let animalName: String
    let destination: String
    let animalAssetName: String
    let origin: GlobeCoordinate
    let destinationCoordinate: GlobeCoordinate
    let departedAt: Date
    let expectedReturnAt: Date
    let tint: Color

    static let palette: [Color] = [
        AppTheme.ochre,
        AppTheme.peach,
        AppTheme.deepSage,
        Color(red: 0.47, green: 0.62, blue: 0.84),
        Color(red: 0.72, green: 0.54, blue: 0.76)
    ]

    func travelProgress(at date: Date) -> Double {
        guard expectedReturnAt > departedAt else { return 1 }
        let elapsed = date.timeIntervalSince(departedAt)
        let duration = expectedReturnAt.timeIntervalSince(departedAt)
        return min(max(elapsed / duration, 0), 1)
    }

    func coordinate(at date: Date) -> GlobeCoordinate? {
        origin.interpolated(to: destinationCoordinate, progress: travelProgress(at: date))
    }

    func visibleSegments(projection: GlobeProjection, sampleCount: Int = 80) -> [[CGPoint]] {
        var segments: [[CGPoint]] = []
        var currentSegment: [CGPoint] = []

        for index in 0...sampleCount {
            let progress = Double(index) / Double(sampleCount)
            guard let coordinate = origin.interpolated(to: destinationCoordinate, progress: progress),
                  let projected = projection.project(coordinate),
                  projected.isVisible else {
                if currentSegment.count > 1 {
                    segments.append(currentSegment)
                }
                currentSegment = []
                continue
            }

            currentSegment.append(projected.point)
        }

        if currentSegment.count > 1 {
            segments.append(currentSegment)
        }

        return segments
    }

    func planeAngle(at date: Date, projection: GlobeProjection) -> Double {
        let progress = travelProgress(at: date)
        let nextProgress = min(progress + 0.012, 1)
        let previousProgress = max(progress - 0.012, 0)
        guard let firstCoordinate = origin.interpolated(to: destinationCoordinate, progress: previousProgress),
              let secondCoordinate = origin.interpolated(to: destinationCoordinate, progress: nextProgress),
              let firstPoint = projection.project(firstCoordinate)?.point,
              let secondPoint = projection.project(secondCoordinate)?.point else {
            return 0
        }

        return atan2(secondPoint.y - firstPoint.y, secondPoint.x - firstPoint.x) * 180 / .pi + 35
    }
}

struct GlobeProjection {
    let center: CGPoint
    let radius: CGFloat
    let orientation: GlobeOrientation

    func project(_ coordinate: GlobeCoordinate) -> GlobeProjectedPoint? {
        let latitude = coordinate.latitude.radians
        let longitude = coordinate.longitude.radians
        let centerLatitude = orientation.centerLatitude.radians
        let centerLongitude = orientation.centerLongitude.radians
        let deltaLongitude = longitude - centerLongitude

        let cosAngularDistance = sin(centerLatitude) * sin(latitude) +
            cos(centerLatitude) * cos(latitude) * cos(deltaLongitude)

        let x = radius * CGFloat(cos(latitude) * sin(deltaLongitude))
        let y = -radius * CGFloat(
            cos(centerLatitude) * sin(latitude) -
                sin(centerLatitude) * cos(latitude) * cos(deltaLongitude)
        )

        return GlobeProjectedPoint(
            point: CGPoint(x: center.x + x, y: center.y + y),
            depth: cosAngularDistance,
            isVisible: cosAngularDistance >= -0.0001
        )
    }
}

struct GlobeProjectedPoint: Equatable {
    let point: CGPoint
    let depth: Double
    let isVisible: Bool
}

typealias WorldMapDestinationCoordinate = GlobeCoordinate

struct GlobeOrientation: Equatable {
    var centerLatitude: Double
    var centerLongitude: Double

    static let defaultReadable = GlobeOrientation(centerLatitude: 18, centerLongitude: 56)

    func applyingDrag(_ translation: CGSize, diameter: CGFloat) -> GlobeOrientation {
        let safeDiameter = max(Double(diameter), 1)
        let longitudeDelta = Double(translation.width) / safeDiameter * -180
        let latitudeDelta = Double(translation.height) / safeDiameter * 92
        return GlobeOrientation(
            centerLatitude: (centerLatitude + latitudeDelta).clamped(to: -55...55),
            centerLongitude: (centerLongitude + longitudeDelta).normalizedLongitude
        )
    }
}

struct GlobeCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    static let cottage = GlobeCoordinate(latitude: 30.0, longitude: 112.0)

    static func coordinate(
        for destinationId: String,
        destination: ManifestDestination?
    ) -> GlobeCoordinate? {
        if let latitude = destination?.latitude,
           let longitude = destination?.longitude {
            return GlobeCoordinate(latitude: latitude, longitude: longitude)
        }

        return legacyCoordinate(for: destinationId)
    }

    static func legacyCoordinate(for destinationId: String) -> GlobeCoordinate? {
        switch destinationId {
        case "paris":
            return GlobeCoordinate(latitude: 48.8566, longitude: 2.3522)
        case "iceland":
            return GlobeCoordinate(latitude: 64.1466, longitude: -21.9426)
        case "lisbon":
            return GlobeCoordinate(latitude: 38.7223, longitude: -9.1393)
        default:
            return nil
        }
    }

    func interpolated(to destination: GlobeCoordinate, progress: Double) -> GlobeCoordinate? {
        let clampedProgress = progress.clamped(to: 0...1)
        let start = GlobeVector(coordinate: self)
        let end = GlobeVector(coordinate: destination)
        let dot = start.dot(end).clamped(to: -1...1)
        let omega = acos(dot)

        if abs(omega) < 0.000001 {
            return self
        }

        let sinOmega = sin(omega)
        guard abs(sinOmega) > 0.000001 else { return nil }

        let startScale = sin((1 - clampedProgress) * omega) / sinOmega
        let endScale = sin(clampedProgress * omega) / sinOmega
        let vector = GlobeVector(
            x: start.x * startScale + end.x * endScale,
            y: start.y * startScale + end.y * endScale,
            z: start.z * startScale + end.z * endScale
        ).normalized

        return vector.coordinate
    }
}

private struct GlobeVector {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(coordinate: GlobeCoordinate) {
        let latitude = coordinate.latitude.radians
        let longitude = coordinate.longitude.radians
        x = cos(latitude) * cos(longitude)
        y = cos(latitude) * sin(longitude)
        z = sin(latitude)
    }

    var normalized: GlobeVector {
        let length = max(sqrt(x * x + y * y + z * z), 0.000001)
        return GlobeVector(x: x / length, y: y / length, z: z / length)
    }

    var coordinate: GlobeCoordinate {
        GlobeCoordinate(
            latitude: asin(z).degrees,
            longitude: atan2(y, x).degrees.normalizedLongitude
        )
    }

    func dot(_ other: GlobeVector) -> Double {
        x * other.x + y * other.y + z * other.z
    }
}

private extension Double {
    var radians: Double {
        self * .pi / 180
    }

    var degrees: Double {
        self * 180 / .pi
    }

    var normalizedLongitude: Double {
        var value = self
        while value > 180 {
            value -= 360
        }
        while value < -180 {
            value += 360
        }
        return value
    }

    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview("Travel Globe Map") {
    WorldMapView()
        .environmentObject(
            AppEnvironment.preview(
                seed: SeedData(
                    animals: SeedData.preview.animals,
                    travelWishes: SeedData.preview.travelWishes,
                    trips: [
                        Trip(
                            id: "preview_trip_paris",
                            animalId: "moji_cat",
                            destinationId: "paris",
                            destination: "巴黎",
                            departedAt: Date().addingTimeInterval(-60 * 60 * 5),
                            expectedReturnAt: Date().addingTimeInterval(60 * 60 * 19),
                            status: .traveling
                        ),
                        Trip(
                            id: "preview_trip_iceland",
                            animalId: "tangyuan_puppy",
                            destinationId: "iceland",
                            destination: "冰岛",
                            departedAt: Date().addingTimeInterval(-60 * 60 * 10),
                            expectedReturnAt: Date().addingTimeInterval(60 * 60 * 14),
                            status: .traveling
                        )
                    ],
                    postcards: [],
                    destinations: SeedData.preview.destinations
                )
            )
        )
}
