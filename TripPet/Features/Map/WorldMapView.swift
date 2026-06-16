import SwiftUI
import UIKit

struct WorldMapView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var scrollEdgeState = WorldMapScrollEdgeState(showLeft: false, showRight: true)
    @State private var scrollCommand: WorldMapScrollCommand?

    private let mapAspectRatio: CGFloat = 1.5
    private let markerSize: CGFloat = 100

    var body: some View {
        GeometryReader { proxy in
            let mapHeight = proxy.size.height
            let mapWidth = mapHeight * mapAspectRatio
            let maxScrollOffset = max(0, mapWidth - proxy.size.width)
            let scrollStep = proxy.size.width * 0.82
            let canScrollHorizontally = maxScrollOffset > scrollEdgeTolerance
            let signWidth = min(proxy.size.width * 0.78, 340)

            ZStack {
                PaperBackground()

                TrackingHorizontalScrollView(
                    contentWidth: mapWidth,
                    contentHeight: mapHeight,
                    edgeState: $scrollEdgeState,
                    scrollCommand: scrollCommand,
                    edgeTolerance: scrollEdgeTolerance
                ) {
                    mapContent(width: mapWidth, height: mapHeight)
                }
                .frame(width: proxy.size.width, height: mapHeight)
                .ignoresSafeArea(edges: .horizontal)

                if canScrollHorizontally {
                    scrollHintArrows(
                        showLeft: scrollEdgeState.showLeft,
                        showRight: scrollEdgeState.showRight,
                        scrollLeft: {
                            scrollMap(by: -scrollStep)
                        },
                        scrollRight: {
                            scrollMap(by: scrollStep)
                        }
                    )
                }

                VStack {
                    Spacer()
                    travelCountSign(width: signWidth)
                        .padding(.bottom, 22)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
    }

    private var scrollEdgeTolerance: CGFloat {
        8
    }

    private func scrollMap(by distance: CGFloat) {
        scrollCommand = WorldMapScrollCommand(delta: distance)
    }

    private func mapContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ArtImage(name: "world_travel_map", contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()

            ForEach(mapMarkers.prefix(9)) { marker in
                tripMarker(marker)
                    .position(
                        x: marker.normalizedPoint.x * width,
                        y: marker.normalizedPoint.y * height - markerSize * 0.34
                    )
            }
        }
        .frame(width: width, height: height)
    }

    private var activeTravelAnimalCount: Int {
        environment.repository.activeTravelTrips.prefix(9).count
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

    private var mapMarkers: [WorldMapMarker] {
        environment.repository.activeTravelTrips.compactMap { trip in
            let manifestDestination = environment.destination(for: trip)
            guard let destination = WorldMapDestinationCoordinate.coordinate(
                for: trip.destinationId,
                destination: manifestDestination
            ) else {
                return nil
            }

            let animal = environment.repository.animal(for: trip.animalId)
            return WorldMapMarker(
                id: trip.id,
                animalName: animal?.name ?? environment.repository.animalName(for: trip.animalId),
                destination: trip.destination,
                animalAssetName: animal?.travelMarkerAssetName ?? "animal_visitor_unknown",
                normalizedPoint: destination.normalizedMapPoint
            )
        }
    }

    private func tripMarker(_ marker: WorldMapMarker) -> some View {
        ZStack {
            ArtImage(name: "trip_marker_empty")
                .frame(width: markerSize, height: markerSize)

            ArtImage(name: marker.animalAssetName)
                .frame(width: markerSize * 0.43, height: markerSize * 0.43)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppTheme.paperWhite.opacity(0.9), lineWidth: 1.4)
                )
                .offset(y: -markerSize * 0.16)
        }
        .frame(width: markerSize, height: markerSize)
        .shadow(color: AppTheme.oliveInk.opacity(0.28), radius: 12, x: 0, y: 7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(marker.animalName)正在\(marker.destination)旅行")
    }

    private func scrollHintArrows(
        showLeft: Bool,
        showRight: Bool,
        scrollLeft: @escaping () -> Void,
        scrollRight: @escaping () -> Void
    ) -> some View {
        HStack {
            Group {
                if showLeft {
                    scrollHintArrow(
                        assetName: "map_scroll_arrow_left",
                        label: "向左移动地图",
                        action: scrollLeft
                    )
                }
            }
            .frame(width: 62, height: 92)

            Spacer()

            Group {
                if showRight {
                    scrollHintArrow(
                        assetName: "map_scroll_arrow_right",
                        label: "向右移动地图",
                        action: scrollRight
                    )
                }
            }
            .frame(width: 62, height: 92)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scrollHintArrow(assetName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ArtImage(name: assetName, isDecorative: false)
                .frame(width: 58, height: 58)
                .shadow(color: AppTheme.oliveInk.opacity(0.24), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct WorldMapScrollEdgeState: Equatable {
    let showLeft: Bool
    let showRight: Bool
}

private struct WorldMapScrollCommand: Equatable {
    let id = UUID()
    let delta: CGFloat
}

private struct TrackingHorizontalScrollView<Content: View>: UIViewRepresentable {
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    @Binding var edgeState: WorldMapScrollEdgeState
    let scrollCommand: WorldMapScrollCommand?
    let edgeTolerance: CGFloat
    @ViewBuilder let content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = true
        scrollView.decelerationRate = .normal
        scrollView.contentInsetAdjustmentBehavior = .never

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        let widthConstraint = hostingController.view.widthAnchor.constraint(equalToConstant: contentWidth)
        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: contentHeight)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            widthConstraint,
            heightConstraint
        ])

        context.coordinator.hostingController = hostingController
        context.coordinator.widthConstraint = widthConstraint
        context.coordinator.heightConstraint = heightConstraint

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hostingController?.rootView = content
        context.coordinator.widthConstraint?.constant = contentWidth
        context.coordinator.heightConstraint?.constant = contentHeight

        let maxOffset = max(0, contentWidth - scrollView.bounds.width)
        let clampedCurrentOffset = min(max(scrollView.contentOffset.x, 0), maxOffset)
        if abs(scrollView.contentOffset.x - clampedCurrentOffset) > 0.5 {
            scrollView.setContentOffset(CGPoint(x: clampedCurrentOffset, y: 0), animated: false)
        }

        if let scrollCommand, context.coordinator.lastCommandId != scrollCommand.id {
            context.coordinator.lastCommandId = scrollCommand.id
            let targetOffset = min(max(clampedCurrentOffset + scrollCommand.delta, 0), maxOffset)
            context.coordinator.animate(scrollView: scrollView, to: targetOffset)
        }

        context.coordinator.reportEdgeState(for: scrollView)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: TrackingHorizontalScrollView
        var hostingController: UIHostingController<Content>?
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        var lastCommandId: UUID?
        private var lastReportedEdgeState: WorldMapScrollEdgeState?

        init(_ parent: TrackingHorizontalScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            reportEdgeState(for: scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            reportEdgeState(for: scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if decelerate == false {
                reportEdgeState(for: scrollView)
            }
        }

        func animate(scrollView: UIScrollView, to targetOffset: CGFloat) {
            guard abs(scrollView.contentOffset.x - targetOffset) > 0.5 else {
                return
            }

            UIView.animate(
                withDuration: 0.36,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]
            ) {
                scrollView.contentOffset = CGPoint(x: targetOffset, y: 0)
            }
        }

        func reportEdgeState(for scrollView: UIScrollView) {
            let maxOffset = max(0, parent.contentWidth - scrollView.bounds.width)
            let offset = min(max(scrollView.contentOffset.x, 0), maxOffset)
            let nextState = WorldMapScrollEdgeState(
                showLeft: offset > parent.edgeTolerance,
                showRight: offset < maxOffset - parent.edgeTolerance
            )

            guard nextState != lastReportedEdgeState else {
                return
            }
            lastReportedEdgeState = nextState

            DispatchQueue.main.async {
                self.parent.edgeState = nextState
            }
        }
    }
}

private struct WorldMapMarker: Identifiable {
    let id: String
    let animalName: String
    let destination: String
    let animalAssetName: String
    let normalizedPoint: CGPoint
}

struct WorldMapDestinationCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    var normalizedMapPoint: CGPoint {
        let projectedX = (longitude + 180) / 360
        let projectedY = (90 - latitude) / 180
        let mapInset = MapInset(left: 0.045, right: 0.055, top: 0.075, bottom: 0.105)

        return CGPoint(
            x: CGFloat(mapInset.left + projectedX * mapInset.width),
            y: CGFloat(mapInset.top + projectedY * mapInset.height)
        )
    }

    static func coordinate(
        for destinationId: String,
        destination: ManifestDestination?
    ) -> WorldMapDestinationCoordinate? {
        if let latitude = destination?.latitude,
           let longitude = destination?.longitude {
            return WorldMapDestinationCoordinate(latitude: latitude, longitude: longitude)
        }

        return legacyCoordinate(for: destinationId)
    }

    static func legacyCoordinate(for destinationId: String) -> WorldMapDestinationCoordinate? {
        switch destinationId {
        case "paris":
            return WorldMapDestinationCoordinate(latitude: 48.8566, longitude: 2.3522)
        case "iceland":
            return WorldMapDestinationCoordinate(latitude: 64.1466, longitude: -21.9426)
        case "lisbon":
            return WorldMapDestinationCoordinate(latitude: 38.7223, longitude: -9.1393)
        default:
            return nil
        }
    }
}

private struct MapInset {
    let left: Double
    let right: Double
    let top: Double
    let bottom: Double

    var width: Double {
        1 - left - right
    }

    var height: Double {
        1 - top - bottom
    }
}

#Preview("World Map") {
    WorldMapView()
        .environmentObject(
            AppEnvironment.preview(
                seed: SeedData(
                    animals: SeedData.preview.animals,
                    travelWishes: SeedData.preview.travelWishes,
                    trips: [
                        Trip(
                            id: "preview_trip_paris",
                            animalId: "cat",
                            destinationId: "paris",
                            destination: "巴黎",
                            departedAt: Date(),
                            expectedReturnAt: Date().addingTimeInterval(60 * 60 * 24),
                            status: .traveling
                        ),
                        Trip(
                            id: "preview_trip_iceland",
                            animalId: "dog",
                            destinationId: "iceland",
                            destination: "冰岛",
                            departedAt: Date(),
                            expectedReturnAt: Date().addingTimeInterval(60 * 60 * 24),
                            status: .traveling
                        )
                    ],
                    postcards: [],
                    destinations: SeedData.preview.destinations
                )
            )
        )
}
