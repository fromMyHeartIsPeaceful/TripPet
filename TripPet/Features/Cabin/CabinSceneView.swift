import SwiftUI

struct CabinSceneView: View {
    private let sceneAspectRatio: CGFloat = 1254.0 / 1455.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var animals: [Animal]
    var isEmpty: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let visibleAnimals = Array(animals.prefix(9))

            ZStack {
                ArtImage(name: "cabin_room_base_user_test", contentMode: .fill, cornerRadius: 28, showsShadow: true)
                    .frame(width: size.width, height: size.height)

                if isEmpty == false {
                    ForEach(Array(visibleAnimals.enumerated()), id: \.element.id) { index, animal in
                        let point = position(for: index, count: visibleAnimals.count, in: size)
                        let animalSize = animalFrameSize(for: visibleAnimals.count, in: size)

                        ArtImage(name: animal.homeAssetName)
                            .frame(width: animalSize.width, height: animalSize.height)
                            .scaleEffect(reduceMotion ? 1 : (isBreathing ? 1.018 : 0.994))
                            .offset(y: reduceMotion ? 0 : (isBreathing ? -2 : 1))
                            .position(point)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(sceneAspectRatio, contentMode: .fit)
        .onAppear {
            guard reduceMotion == false else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    private func animalFrameSize(for count: Int, in size: CGSize) -> CGSize {
        let widthRatio: CGFloat
        let heightRatio: CGFloat
        switch count {
        case 0...1:
            widthRatio = 0.27
            heightRatio = 0.31
        case 2...4:
            widthRatio = 0.19
            heightRatio = 0.22
        default:
            widthRatio = 0.18
            heightRatio = 0.23
        }
        return CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
    }

    private func position(for index: Int, count: Int, in size: CGSize) -> CGPoint {
        let single = [CGPoint(x: 0.5, y: 0.62)]
        let pair = [
            CGPoint(x: 0.35, y: 0.63),
            CGPoint(x: 0.66, y: 0.63)
        ]
        let compact = [
            CGPoint(x: 0.28, y: 0.58),
            CGPoint(x: 0.49, y: 0.55),
            CGPoint(x: 0.69, y: 0.58),
            CGPoint(x: 0.82, y: 0.69)
        ]
        let full = [
            CGPoint(x: 0.18, y: 0.47),
            CGPoint(x: 0.39, y: 0.43),
            CGPoint(x: 0.64, y: 0.43),
            CGPoint(x: 0.90, y: 0.55),
            CGPoint(x: 0.14, y: 0.66),
            CGPoint(x: 0.36, y: 0.72),
            CGPoint(x: 0.73, y: 0.69),
            CGPoint(x: 0.18, y: 0.83),
            CGPoint(x: 0.79, y: 0.83)
        ]

        let ratios: [CGPoint]
        switch count {
        case 0...1:
            ratios = single
        case 2:
            ratios = pair
        case 3...4:
            ratios = compact
        default:
            ratios = full
        }

        let point = ratios[min(index, ratios.count - 1)]
        return CGPoint(x: size.width * point.x, y: size.height * point.y)
    }
}
