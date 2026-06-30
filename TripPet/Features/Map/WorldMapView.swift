import SceneKit
import SwiftUI
import simd

struct WorldMapView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedTravelRoute: TravelGlobeRoute?
    var isActive: Bool = true

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

                    TravelGlobeView(
                        routes: globeRoutes,
                        isActive: isActive,
                        onSelectRoute: { route in
                            selectedTravelRoute = route
                        }
                    )
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
        .sheet(item: $selectedTravelRoute) { route in
            TravelCountdownSheet(route: route) {
                _ = environment.revealEligiblePostcards()
                selectedTravelRoute = nil
            }
            .appActionSheetPresentation()
        }
        .onChange(of: activeTravelRouteIds) { _, activeRouteIds in
            guard let selectedTravelRoute,
                  activeRouteIds.contains(selectedTravelRoute.id) == false else {
                return
            }
            self.selectedTravelRoute = nil
        }
    }

    private var activeTravelAnimalCount: Int {
        environment.repository.activeTravelTrips.prefix(9).count
    }

    private var activeTravelRouteIds: Set<String> {
        Set(globeRoutes.map(\.id))
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
    var isActive: Bool = true
    var onSelectRoute: (TravelGlobeRoute) -> Void = { _ in }

    @State private var orientation = GlobeOrientation.defaultReadable
    fileprivate static let visibleGlobeRadiusRatio: CGFloat = 0.475

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = diameter * Self.visibleGlobeRadiusRatio
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let projection = GlobeProjection(center: center, radius: radius, orientation: orientation)

            TimelineView(.periodic(from: Date(), by: 30)) { timeline in
                ZStack {
                    globeSurface(diameter: diameter)
                    routeLayer(projection: projection, date: timeline.date)
                        .allowsHitTesting(false)
                    markerLayer(projection: projection, date: timeline.date)
                        .allowsHitTesting(isActive)
                }
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .onAppear {
            resetToCottageCenterIfNeeded()
        }
        .onChange(of: isActive) { _, newValue in
            guard newValue else { return }
            resetToCottageCenterIfNeeded()
        }
    }

    private func resetToCottageCenterIfNeeded() {
        guard orientation != .cottageCentered else { return }
        orientation = .cottageCentered
    }

    private func globeSurface(diameter: CGFloat) -> some View {
        SceneKitGlobeSurfaceView(orientation: $orientation, isActive: isActive)
            .frame(width: diameter, height: diameter)
            .saturation(1.06)
            .contrast(1.06)
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .compositingGroup()
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
                        route.tint.opacity(0.60),
                        style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round, dash: [7, 6])
                    )
                    .shadow(color: route.tint.opacity(0.16), radius: 5, x: 0, y: 2)
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
                    .allowsHitTesting(false)
                    .position(cottagePoint.point)
            }

            ForEach(routes) { route in
                if let destinationPoint = projection.project(route.destinationCoordinate),
                   destinationPoint.isVisible {
                    Button {
                        onSelectRoute(route)
                    } label: {
                        AnimalDestinationMarker(route: route)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .accessibilityLabel("查看\(route.animalName)回家倒计时")
                    .position(destinationPoint.point)
                }
            }
        }
        .frame(width: projection.center.x * 2, height: projection.center.y * 2)
    }

}

private struct SceneKitGlobeSurfaceView: UIViewRepresentable {
    @Binding var orientation: GlobeOrientation
    var isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(orientation: orientation, orientationBinding: $orientation, isActive: isActive)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsCameraControl = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = false
        view.isUserInteractionEnabled = isActive

        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        view.scene = scene

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.06
        camera.zNear = 0.1
        camera.zFar = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(cameraNode)
        view.pointOfView = cameraNode

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 560
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 720
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-0.58, -0.72, 0.0)
        scene.rootNode.addChildNode(keyLightNode)

        let sphere = SCNSphere(radius: 1)
        sphere.segmentCount = 160

        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "world_travel_map")
        material.lightingModel = .lambert
        material.isDoubleSided = false
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .clamp
        material.diffuse.magnificationFilter = .linear
        material.diffuse.minificationFilter = .linear
        sphere.firstMaterial = material

        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)

        context.coordinator.sphereNode = sphereNode
        context.coordinator.applyCurrentOrientationToNode()
        view.setNeedsDisplay()

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = true
        view.addGestureRecognizer(pan)
        context.coordinator.view = view

        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.orientationBinding = $orientation
        context.coordinator.view = view
        context.coordinator.setActive(isActive)
        context.coordinator.syncExternalOrientation(orientation)
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.invalidateMomentum()
    }

    final class Coordinator: NSObject {
        var orientationBinding: Binding<GlobeOrientation>
        weak var view: SCNView?
        weak var sphereNode: SCNNode?

        private var isActive: Bool
        private var orientation: GlobeOrientation
        private var lastLocation: CGPoint?
        private var velocity: CGPoint = .zero
        private var displayLink: CADisplayLink?
        private var isInteracting = false

        init(orientation: GlobeOrientation, orientationBinding: Binding<GlobeOrientation>, isActive: Bool) {
            self.orientation = orientation
            self.orientationBinding = orientationBinding
            self.isActive = isActive
        }

        deinit {
            invalidateMomentum()
        }

        func syncExternalOrientation(_ newOrientation: GlobeOrientation) {
            guard !isInteracting, displayLink == nil, newOrientation != orientation else { return }
            orientation = newOrientation
            applyCurrentOrientationToNode()
        }

        func setActive(_ newIsActive: Bool) {
            isActive = newIsActive
            view?.isUserInteractionEnabled = newIsActive
            if newIsActive == false {
                isInteracting = false
                lastLocation = nil
                velocity = .zero
                invalidateMomentum()
            }
        }

        func applyCurrentOrientationToNode() {
            sphereNode?.simdTransform = orientation.sceneKitTransform
            view?.setNeedsDisplay()
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isActive, let view else { return }

            let location = recognizer.location(in: view)
            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            let radius = min(view.bounds.width, view.bounds.height) * TravelGlobeView.visibleGlobeRadiusRatio

            switch recognizer.state {
            case .began:
                invalidateMomentum()
                isInteracting = true
                lastLocation = location
                velocity = .zero
            case .changed:
                guard let previousLocation = lastLocation else {
                    lastLocation = location
                    return
                }

                setOrientation(
                    orientation.applyingTrackballDrag(
                        from: previousLocation,
                        to: location,
                        center: center,
                        radius: radius
                    )
                )
                lastLocation = location
                velocity = recognizer.velocity(in: view)
            case .ended, .cancelled, .failed:
                isInteracting = false
                lastLocation = nil
                velocity = recognizer.velocity(in: view).clamped(maxLength: 4_200)
                startMomentumIfNeeded(in: view)
            default:
                break
            }
        }

        private func setOrientation(_ newOrientation: GlobeOrientation) {
            orientation = newOrientation
            applyCurrentOrientationToNode()
            orientationBinding.wrappedValue = newOrientation
        }

        private func startMomentumIfNeeded(in view: SCNView) {
            guard isActive else { return }
            guard hypot(velocity.x, velocity.y) > 40 else {
                velocity = .zero
                return
            }

            invalidateMomentum()
            let link = CADisplayLink(target: self, selector: #selector(momentumTick(_:)))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 45, maximum: 60, preferred: 60)
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func momentumTick(_ link: CADisplayLink) {
            guard let view else {
                invalidateMomentum()
                return
            }

            let speed = hypot(velocity.x, velocity.y)
            guard speed > 8 else {
                invalidateMomentum()
                velocity = .zero
                return
            }

            let dt = min(max(link.duration, 1.0 / 120.0), 1.0 / 30.0)
            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            let radius = min(view.bounds.width, view.bounds.height) * TravelGlobeView.visibleGlobeRadiusRatio
            let delta = CGSize(width: velocity.x * dt, height: velocity.y * dt)
            let nextPoint = CGPoint(x: center.x + delta.width, y: center.y + delta.height)

            setOrientation(
                orientation.applyingTrackballDrag(
                    from: center,
                    to: nextPoint,
                    center: center,
                    radius: radius
                )
            )

            let decay = pow(0.84, dt * 60)
            velocity = CGPoint(x: velocity.x * decay, y: velocity.y * decay)
        }

        func invalidateMomentum() {
            displayLink?.invalidate()
            displayLink = nil
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
                .frame(width: 46, height: 46)
                .overlay(Circle().stroke(AppTheme.ochre.opacity(0.55), lineWidth: 1.5))
                .shadow(color: AppTheme.oliveInk.opacity(0.14), radius: 7, x: 0, y: 4)

            ArtImage(name: route.animalAssetName)
                .frame(width: 42, height: 42)
                .clipShape(Circle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(route.animalName)正在前往\(route.destination)")
    }
}

private struct TravelCountdownSheet: View {
    let route: TravelGlobeRoute
    let onDone: () -> Void

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { timeline in
            let clockText = TravelCountdownFormatter.clockString(
                until: route.expectedReturnAt,
                now: timeline.date
            )

            AppActionBottomSheet(onButton: onDone) {
                VStack(spacing: 16) {
                    TravelCountdownAnimalHeader(
                        animalName: route.animalName,
                        animalAssetName: route.animalAssetName
                    )

                    TravelCountdownClockBadge(
                        text: countdownText(clockText: clockText),
                        tint: route.tint
                    )

                    Text("正在【\(route.destination)】旅行")
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func countdownText(clockText: String) -> String {
        "还有\(clockText)回家"
    }
}

private struct TravelCountdownAnimalHeader: View {
    let animalName: String
    let animalAssetName: String

    var body: some View {
        VStack(spacing: 7) {
            ArtImage(name: animalAssetName)
                .frame(width: 104, height: 104)
                .background(
                    Circle()
                        .fill(AppTheme.paperWhite.opacity(0.72))
                        .shadow(color: AppTheme.oliveInk.opacity(0.1), radius: 10, x: 0, y: 5)
                )

            Text(animalName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(animalName)
    }
}

private struct TravelCountdownClockBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            ClockGlyph()
                .frame(width: 23, height: 23)

            Text(text)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.paperWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: 304)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.sage.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.paperWhite.opacity(0.92), lineWidth: 1.2)
        )
        .shadow(color: AppTheme.oliveInk.opacity(0.08), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("回家倒计时，\(text)")
    }
}

private struct ClockGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.paperWhite.opacity(0.92), lineWidth: 2)

            Rectangle()
                .fill(AppTheme.paperWhite.opacity(0.92))
                .frame(width: 2, height: 7)
                .offset(y: -3)

            Rectangle()
                .fill(AppTheme.paperWhite.opacity(0.92))
                .frame(width: 7, height: 2)
                .offset(x: 3)
        }
    }
}

enum TravelCountdownFormatter {
    static let arrivingSoonText = "即将到达"

    static func clockString(until expectedReturnAt: Date, now: Date) -> String {
        clockString(remaining: expectedReturnAt.timeIntervalSince(now))
    }

    static func clockString(remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(remaining)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func timeString(until expectedReturnAt: Date, now: Date) -> String {
        timeString(remaining: expectedReturnAt.timeIntervalSince(now))
    }

    static func timeString(remaining: TimeInterval) -> String {
        guard remaining > 0 else { return arrivingSoonText }

        let totalMinutes = max(1, Int(ceil(remaining / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if totalMinutes < 60 {
            return "\(totalMinutes)分钟"
        }

        if totalMinutes < 1_440 {
            return "\(hours)小时\(minutes)分钟"
        }

        let days = totalMinutes / 1_440
        let remainingHours = (totalMinutes % 1_440) / 60
        return "\(days)天\(remainingHours)小时"
    }

    static func arrivalTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
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
        AppTheme.mapRouteBlue
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
        let vector = GlobeVector(coordinate: coordinate)
        let depth = vector.dot(orientation.forward)
        let x = radius * CGFloat(vector.dot(orientation.right))
        let y = -radius * CGFloat(vector.dot(orientation.up))

        return GlobeProjectedPoint(
            point: CGPoint(x: center.x + x, y: center.y + y),
            depth: depth,
            isVisible: depth >= -0.0001
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
    private(set) var right: GlobeVector
    private(set) var up: GlobeVector
    private(set) var forward: GlobeVector

    static let cottageCentered = GlobeOrientation(
        centerLatitude: GlobeCoordinate.cottage.latitude,
        centerLongitude: GlobeCoordinate.cottage.longitude
    )
    static let defaultReadable = cottageCentered

    init(centerLatitude: Double, centerLongitude: Double) {
        let forward = GlobeVector(coordinate: GlobeCoordinate(latitude: centerLatitude, longitude: centerLongitude))
        let worldNorth = GlobeVector(x: 0, y: 0, z: 1)
        let east = worldNorth.cross(forward)
        let right = east.length > 0.000001 ? east.normalized : GlobeVector(x: 1, y: 0, z: 0)
        let up = forward.cross(right)
        self.init(right: right, up: up, forward: forward)
    }

    private init(right: GlobeVector, up: GlobeVector, forward: GlobeVector) {
        let normalizedForward = forward.normalized
        var normalizedRight = (right - normalizedForward.scaled(by: right.dot(normalizedForward))).normalized

        if normalizedRight.length < 0.000001 {
            let fallback = abs(normalizedForward.z) > 0.98 ?
                GlobeVector(x: 1, y: 0, z: 0) :
                GlobeVector(x: 0, y: 0, z: 1).cross(normalizedForward)
            normalizedRight = fallback.normalized
        }

        self.forward = normalizedForward
        self.right = normalizedRight
        self.up = normalizedForward.cross(normalizedRight).normalized
    }

    var centerLatitude: Double {
        forward.coordinate.latitude
    }

    var centerLongitude: Double {
        forward.coordinate.longitude
    }

    var sceneKitTransform: simd_float4x4 {
        simd_float4x4(columns: (
            SIMD4(Float(right.x), Float(up.x), Float(forward.x), 0),
            SIMD4(Float(right.y), Float(up.y), Float(forward.y), 0),
            SIMD4(Float(right.z), Float(up.z), Float(forward.z), 0),
            SIMD4(0, 0, 0, 1)
        ))
    }

    func applyingTrackballDrag(
        from startLocation: CGPoint,
        to currentLocation: CGPoint,
        center: CGPoint,
        radius: CGFloat
    ) -> GlobeOrientation {
        guard radius > 0 else { return self }

        let currentVector = Self.trackballVector(at: currentLocation, center: center, radius: radius)
        let startVector = Self.trackballVector(at: startLocation, center: center, radius: radius)
        let rotationAxis = currentVector.cross(startVector)
        let axisLength = rotationAxis.length
        guard axisLength > 0.000001 else { return self }

        let angle = atan2(axisLength, currentVector.dot(startVector).clamped(to: -1...1))
        let worldAxis = localToWorld(rotationAxis).normalized

        return GlobeOrientation(
            right: right.rotated(around: worldAxis, by: angle),
            up: up.rotated(around: worldAxis, by: angle),
            forward: forward.rotated(around: worldAxis, by: angle)
        )
    }

    private static func trackballVector(at point: CGPoint, center: CGPoint, radius: CGFloat) -> GlobeVector {
        let safeRadius = max(Double(radius), 1)
        let x = Double(point.x - center.x) / safeRadius
        let y = Double(center.y - point.y) / safeRadius
        let distanceSquared = x * x + y * y

        if distanceSquared <= 1 {
            return GlobeVector(x: x, y: y, z: sqrt(1 - distanceSquared)).normalized
        }

        let distance = max(sqrt(distanceSquared), 0.000001)
        return GlobeVector(x: x / distance, y: y / distance, z: 0)
    }

    private func localToWorld(_ localVector: GlobeVector) -> GlobeVector {
        right.scaled(by: localVector.x) +
            up.scaled(by: localVector.y) +
            forward.scaled(by: localVector.z)
    }
}

struct GlobeCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    static let cottage = GlobeCoordinate(latitude: -20.0, longitude: -150.0)

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

struct GlobeVector: Equatable {
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

    var length: Double {
        sqrt(x * x + y * y + z * z)
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

    func cross(_ other: GlobeVector) -> GlobeVector {
        GlobeVector(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    func scaled(by scale: Double) -> GlobeVector {
        GlobeVector(x: x * scale, y: y * scale, z: z * scale)
    }

    func rotated(around axis: GlobeVector, by angle: Double) -> GlobeVector {
        let normalizedAxis = axis.normalized
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return scaled(by: cosAngle) +
            normalizedAxis.cross(self).scaled(by: sinAngle) +
            normalizedAxis.scaled(by: normalizedAxis.dot(self) * (1 - cosAngle))
    }

    static func + (left: GlobeVector, right: GlobeVector) -> GlobeVector {
        GlobeVector(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
    }

    static func - (left: GlobeVector, right: GlobeVector) -> GlobeVector {
        GlobeVector(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
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

private extension CGPoint {
    func clamped(maxLength: CGFloat) -> CGPoint {
        let length = hypot(x, y)
        guard length > maxLength, length > 0 else { return self }
        let scale = maxLength / length
        return CGPoint(x: x * scale, y: y * scale)
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
