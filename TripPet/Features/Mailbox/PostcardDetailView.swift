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

                ArtImage(name: postcard.destinationAssetName)
                    .frame(width: size.width * 0.42, height: size.height * 0.18)
                    .position(x: size.width * 0.31, y: size.height * 0.19)

                ArtImage(name: postcard.animalAssetName)
                    .frame(width: size.width * 0.25, height: size.height * 0.18)
                    .rotationEffect(.degrees(3))
                    .position(x: size.width * 0.46, y: size.height * 0.25)

                ArtImage(name: postcard.stampAssetName)
                    .frame(width: size.width * 0.18, height: size.width * 0.18)
                    .rotationEffect(.degrees(-12))
                    .opacity(0.78)
                    .position(x: size.width * 0.81, y: size.height * 0.14)

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
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: size.width * 0.72, alignment: .leading)
                .position(x: size.width * 0.52, y: size.height * 0.61)
            }
        }
        .aspectRatio(971.0 / 1619.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(postcard.destination)明信片，\(postcard.subtitle)")
    }

    private var displayTitle: String {
        postcard.title == "小猫寄来的自拍" ? "小猫寄来的明信片" : postcard.title
    }

}

#Preview("Postcard Paris") {
    PostcardDetailView(postcard: SeedData.preview.postcards[0])
}

#Preview("Postcard Iceland") {
    PostcardDetailView(postcard: SeedData.preview.postcards[1])
}
