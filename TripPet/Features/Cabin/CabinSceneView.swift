import SwiftUI

struct CabinSceneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var resident: Animal?
    var visitor: Animal?
    var isApproaching: Bool = false
    var isEmpty: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                ArtImage(name: "cabin_room_base", contentMode: .fill, cornerRadius: 28, showsShadow: true)
                    .frame(width: size.width, height: size.height)

                ArtImage(name: "prop_map_table")
                    .frame(width: size.width * 0.58, height: size.height * 0.38)
                    .rotationEffect(.degrees(-2))
                    .position(x: size.width * 0.64, y: size.height * 0.69)

                if isApproaching {
                    ArtImage(name: "cabin_next_animal_approaching")
                        .frame(width: size.width * 0.78, height: size.height * 0.58)
                        .opacity(0.94)
                        .offset(y: reduceMotion ? 0 : (isBreathing ? -2 : 2))
                        .position(x: size.width * 0.5, y: size.height * 0.58)
                } else if isEmpty == false {
                    ArtImage(name: resident?.homeAssetName ?? "animal_cat_home")
                        .frame(width: size.width * 0.38, height: size.height * 0.44)
                        .scaleEffect(reduceMotion ? 1 : (isBreathing ? 1.018 : 0.994))
                        .position(x: size.width * 0.33, y: size.height * 0.62)

                    if let visitor {
                        ArtImage(name: visitor.visitorAssetName)
                            .frame(width: size.width * 0.24, height: size.height * 0.28)
                            .opacity(0.92)
                            .offset(y: reduceMotion ? 0 : (isBreathing ? -3 : 1))
                            .position(x: size.width * 0.81, y: size.height * 0.53)
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
}
