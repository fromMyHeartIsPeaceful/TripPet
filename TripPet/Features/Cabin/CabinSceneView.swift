import SwiftUI

struct CabinSceneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var animals: [Animal]
    var isEmpty: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let visibleAnimals = Array(animals.prefix(9))

            ZStack {
                ArtImage(name: "cabin_room_base", contentMode: .fill, cornerRadius: 28, showsShadow: true)
                    .frame(width: size.width, height: size.height)

                ArtImage(name: "prop_map_table")
                    .frame(width: size.width * 0.58, height: size.height * 0.38)
                    .rotationEffect(.degrees(-2))
                    .position(x: size.width * 0.64, y: size.height * 0.69)

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
        .aspectRatio(1, contentMode: .fit)
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
            widthRatio = 0.38
            heightRatio = 0.44
        case 2...4:
            widthRatio = 0.27
            heightRatio = 0.31
        default:
            widthRatio = 0.2
            heightRatio = 0.23
        }
        return CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
    }

    private func position(for index: Int, count: Int, in size: CGSize) -> CGPoint {
        let single = [CGPoint(x: 0.33, y: 0.62)]
        let pair = [
            CGPoint(x: 0.29, y: 0.63),
            CGPoint(x: 0.76, y: 0.55)
        ]
        let compact = [
            CGPoint(x: 0.25, y: 0.63),
            CGPoint(x: 0.48, y: 0.56),
            CGPoint(x: 0.72, y: 0.63),
            CGPoint(x: 0.82, y: 0.48)
        ]
        let full = [
            CGPoint(x: 0.2, y: 0.51),
            CGPoint(x: 0.42, y: 0.48),
            CGPoint(x: 0.64, y: 0.5),
            CGPoint(x: 0.82, y: 0.48),
            CGPoint(x: 0.22, y: 0.66),
            CGPoint(x: 0.43, y: 0.65),
            CGPoint(x: 0.64, y: 0.67),
            CGPoint(x: 0.82, y: 0.64),
            CGPoint(x: 0.52, y: 0.77)
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
