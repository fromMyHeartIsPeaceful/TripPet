import SwiftUI

struct PostcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let postcard: Postcard

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 18) {
                header

                PostcardArtwork(postcard: postcard)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    ArtImage(name: "icon_back", isDecorative: false)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(AppTheme.ink)
                    Text("返回")
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("返回邮箱")
            Spacer()
        }
    }
}

private struct PostcardArtwork: View {
    let postcard: Postcard

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                ArtImage(name: postcard.templateAssetName, cornerRadius: 24, showsShadow: true)
                    .frame(width: size.width, height: size.height)

                switch layout {
                case .classicPortrait:
                    classicPortraitArtwork(size: size)
                case .landscape:
                    landscapeArtwork(size: size)
                }
            }
        }
        .aspectRatio(layout.aspectRatio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayTitle)，来自\(postcard.destination)，\(postcard.subtitle)，\(postcard.body)")
    }

    @ViewBuilder
    private func classicPortraitArtwork(size: CGSize) -> some View {
        if isFirstAirportPostcard {
            ArtImage(name: postcard.destinationAssetName, contentMode: .fill, cornerRadius: 10)
                .frame(width: size.width * 0.74, height: size.height * 0.24)
                .clipped()
                .position(x: size.width * 0.5, y: size.height * 0.2)
        } else {
            ArtImage(name: postcard.destinationAssetName)
                .frame(width: size.width * 0.42, height: size.height * 0.18)
                .position(x: size.width * 0.31, y: size.height * 0.19)

            ArtImage(name: postcard.animalAssetName)
                .frame(width: size.width * 0.25, height: size.height * 0.18)
                .rotationEffect(.degrees(3))
                .position(x: size.width * 0.46, y: size.height * 0.25)
        }

        ArtImage(name: postcard.stampAssetName)
            .frame(width: size.width * 0.18, height: size.width * 0.18)
            .rotationEffect(.degrees(-12))
            .opacity(isFirstAirportPostcard ? 0.7 : 0.78)
            .position(
                x: size.width * (isFirstAirportPostcard ? 0.78 : 0.81),
                y: size.height * (isFirstAirportPostcard ? 0.32 : 0.14)
            )

        if isFirstAirportPostcard == false {
            VStack(alignment: .leading, spacing: 6) {
                Text(postcard.destination)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(postcard.subtitle)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            .frame(width: size.width * 0.24, alignment: .leading)
            .position(x: size.width * 0.73, y: size.height * 0.25)
        }

        bodyTextBlock(size: size, widthRatio: 0.72, heightRatio: isFirstAirportPostcard ? 0.34 : nil)
            .position(
                x: size.width * 0.52,
                y: size.height * (isFirstAirportPostcard ? 0.64 : 0.61)
            )
    }

    private func landscapeArtwork(size: CGSize) -> some View {
        ZStack {
            ArtImage(name: postcard.destinationAssetName, contentMode: .fill, cornerRadius: 12)
                .frame(width: size.width * 0.84, height: size.height * 0.47)
                .clipped()
                .position(x: size.width * 0.5, y: size.height * 0.29)

            ArtImage(name: postcard.animalAssetName)
                .frame(width: size.width * 0.16, height: size.height * 0.2)
                .rotationEffect(.degrees(3))
                .position(x: size.width * 0.18, y: size.height * 0.5)

            VStack(alignment: .leading, spacing: 5) {
                Text(postcard.destination)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(postcard.subtitle)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            .frame(width: size.width * 0.18, alignment: .leading)
            .position(x: size.width * 0.18, y: size.height * 0.67)

            landscapeBodyTextBlock(size: size)
                .position(x: size.width * 0.53, y: size.height * 0.8)

            ArtImage(name: postcard.stampAssetName)
                .frame(width: size.width * 0.12, height: size.width * 0.12)
                .rotationEffect(.degrees(-12))
                .opacity(0.78)
                .position(x: size.width * 0.81, y: size.height * 0.73)
        }
    }

    private func landscapeBodyTextBlock(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(displayTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(postcard.body)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(3)
                .lineLimit(3)
                .minimumScaleFactor(0.84)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: size.width * 0.42, alignment: .leading)
    }

    private func bodyTextBlock(size: CGSize, widthRatio: CGFloat, heightRatio: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayTitle)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(postcard.body)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(6)
                .lineLimit(5)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(
            width: size.width * widthRatio,
            height: heightRatio.map { size.height * $0 },
            alignment: heightRatio == nil ? .leading : .topLeading
        )
    }

    private var isFirstAirportPostcard: Bool {
        postcard.postcardType == "first_airport_departure"
    }

    private var layout: PostcardArtworkLayout {
        PostcardArtworkLayout(templateAssetName: postcard.templateAssetName)
    }

    private var displayTitle: String {
        postcard.title == "小猫寄来的自拍" ? "小猫寄来的明信片" : postcard.title
    }

}

private enum PostcardArtworkLayout {
    case classicPortrait
    case landscape

    init(templateAssetName: String) {
        switch templateAssetName {
        case "postcard_template_landscape_v102":
            self = .landscape
        case "postcard_template_classic":
            self = .classicPortrait
        default:
            self = .classicPortrait
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .classicPortrait:
            return 971.0 / 1619.0
        case .landscape:
            return 16.0 / 9.0
        }
    }
}

#Preview("Postcard Paris") {
    PostcardDetailView(postcard: SeedData.previewPostcards[0])
}

#Preview("Postcard Iceland") {
    PostcardDetailView(postcard: SeedData.previewPostcards[1])
}
