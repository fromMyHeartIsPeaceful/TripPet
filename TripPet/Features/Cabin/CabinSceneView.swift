import ImageIO
import SwiftUI
import UIKit

struct CabinAnimalLayout {
    struct LayoutProfile: Equatable {
        var sourceSize: CGSize
        var slots: [Slot]

        func renderedRect(in containerSize: CGSize, contentMode: ArtImage.ContentMode) -> CGRect {
            Self.renderedRect(
                sourceSize: sourceSize,
                containerSize: containerSize,
                contentMode: contentMode
            )
        }

        static func renderedRect(
            sourceSize: CGSize,
            containerSize: CGSize,
            contentMode: ArtImage.ContentMode
        ) -> CGRect {
            guard sourceSize.width > 0,
                  sourceSize.height > 0,
                  containerSize.width > 0,
                  containerSize.height > 0 else {
                return CGRect(origin: .zero, size: containerSize)
            }

            let widthScale = containerSize.width / sourceSize.width
            let heightScale = containerSize.height / sourceSize.height
            let scale: CGFloat
            switch contentMode {
            case .fit:
                scale = min(widthScale, heightScale)
            case .fill:
                scale = max(widthScale, heightScale)
            }

            let renderedSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )

            return CGRect(
                x: (containerSize.width - renderedSize.width) / 2,
                y: (containerSize.height - renderedSize.height) / 2,
                width: renderedSize.width,
                height: renderedSize.height
            )
        }
    }

    enum Floor: Int, CaseIterable {
        case top
        case middle
        case bottom
    }

    enum RoomSide: String {
        case leftLarge
        case rightSmall
    }

    struct Slot: Identifiable, Equatable {
        var id: String { animalId }
        var animalId: String
        var floor: Floor
        var side: RoomSide
        var footPointRatio: CGPoint
        var heightRatio: CGFloat
        var isMirrored: Bool = false

        func footPoint(in size: CGSize) -> CGPoint {
            CGPoint(
                x: size.width * footPointRatio.x,
                y: size.height * footPointRatio.y
            )
        }

        func frame(in size: CGSize, aspectRatio: CGFloat) -> CGRect {
            let height = size.height * heightRatio
            let width = height * aspectRatio
            let footPoint = footPoint(in: size)

            return CGRect(
                x: footPoint.x - width / 2,
                y: footPoint.y - height,
                width: width,
                height: height
            )
        }

        func footPoint(in renderedRect: CGRect, verticalLiftRatio: CGFloat) -> CGPoint {
            let liftedRatioY = footPointRatio.y - verticalLiftRatio
            return CGPoint(
                x: renderedRect.minX + renderedRect.width * footPointRatio.x,
                y: renderedRect.minY + renderedRect.height * liftedRatioY
            )
        }

        func frame(in renderedRect: CGRect, aspectRatio: CGFloat, verticalLiftRatio: CGFloat) -> CGRect {
            let height = renderedRect.height * heightRatio
            let width = height * aspectRatio
            let footPoint = footPoint(in: renderedRect, verticalLiftRatio: verticalLiftRatio)

            return CGRect(
                x: footPoint.x - width / 2,
                y: footPoint.y - height,
                width: width,
                height: height
            )
        }
    }

    struct Placement: Identifiable {
        var id: String { animal.id }
        var animal: Animal
        var slot: Slot
    }

    static let fullscreenDayRoom = LayoutProfile(
        sourceSize: CGSize(width: 1254, height: 2712),
        slots: [
            Slot(
                animalId: "xiaoman_hamster",
                floor: .top,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.205, y: 0.478),
                heightRatio: 0.120
            ),
            Slot(
                animalId: "moji_cat",
                floor: .top,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.500, y: 0.452),
                heightRatio: 0.126
            ),
            Slot(
                animalId: "dengdeng_rabbit",
                floor: .top,
                side: .rightSmall,
                footPointRatio: CGPoint(x: 0.749, y: 0.458),
                heightRatio: 0.120,
                isMirrored: true
            ),
            Slot(
                animalId: "tangyuan_puppy",
                floor: .middle,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.125, y: 0.615),
                heightRatio: 0.120
            ),
            Slot(
                animalId: "xiaolu_guinea_pig",
                floor: .middle,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.365, y: 0.635),
                heightRatio: 0.114
            ),
            Slot(
                animalId: "bear_visitor",
                floor: .middle,
                side: .rightSmall,
                footPointRatio: CGPoint(x: 0.635, y: 0.635),
                heightRatio: 0.120,
                isMirrored: true
            ),
            Slot(
                animalId: "deer_visitor",
                floor: .middle,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.875, y: 0.646),
                heightRatio: 0.124
            ),
            Slot(
                animalId: "fox_visitor",
                floor: .bottom,
                side: .leftLarge,
                footPointRatio: CGPoint(x: 0.260, y: 0.700),
                heightRatio: 0.138
            ),
            Slot(
                animalId: "feifei_parrot",
                floor: .bottom,
                side: .rightSmall,
                footPointRatio: CGPoint(x: 0.740, y: 0.700),
                heightRatio: 0.116
            )
        ]
    )

    static let nightCutawayRoom = LayoutProfile(
        sourceSize: CGSize(width: 1254, height: 1455),
        slots: [
        Slot(
            animalId: "xiaoman_hamster",
            floor: .top,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.200, y: 0.580),
            heightRatio: 0.116
        ),
        Slot(
            animalId: "moji_cat",
            floor: .top,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.500, y: 0.565),
            heightRatio: 0.120
        ),
        Slot(
            animalId: "dengdeng_rabbit",
            floor: .top,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.800, y: 0.580),
            heightRatio: 0.116,
            isMirrored: true
        ),
        Slot(
            animalId: "tangyuan_puppy",
            floor: .middle,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.105, y: 0.665),
            heightRatio: 0.116
        ),
        Slot(
            animalId: "xiaolu_guinea_pig",
            floor: .middle,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.355, y: 0.690),
            heightRatio: 0.110
        ),
        Slot(
            animalId: "bear_visitor",
            floor: .middle,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.645, y: 0.690),
            heightRatio: 0.116,
            isMirrored: true
        ),
        Slot(
            animalId: "deer_visitor",
            floor: .middle,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.895, y: 0.665),
            heightRatio: 0.112
        ),
        Slot(
            animalId: "fox_visitor",
            floor: .bottom,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.230, y: 0.718),
            heightRatio: 0.102
        ),
        Slot(
            animalId: "feifei_parrot",
            floor: .bottom,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.770, y: 0.718),
            heightRatio: 0.100
        )
    ]
    )

    static var slots: [Slot] {
        fullscreenDayRoom.slots
    }

    static func slot(for animalId: String, in profile: LayoutProfile = fullscreenDayRoom) -> Slot? {
        profile.slots.first { $0.animalId == animalId }
    }

    static func placements(for animals: [Animal], in profile: LayoutProfile = fullscreenDayRoom) -> [Placement] {
        let animalsById = Dictionary(animals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let slots = profile.slots
        let knownPlacements = slots.compactMap { slot -> Placement? in
            guard let animal = animalsById[slot.animalId] else { return nil }
            return Placement(animal: animal, slot: slot)
        }

        let knownIds = Set(slots.map(\.animalId))
        let placedIds = Set(knownPlacements.map(\.animal.id))
        let unmatchedAnimals = animals
            .filter { knownIds.contains($0.id) == false }
            .prefix(max(0, slots.count - knownPlacements.count))
        let emptySlots = slots.filter { placedIds.contains($0.animalId) == false }

        let fallbackPlacements = zip(unmatchedAnimals, emptySlots).map { animal, slot in
            Placement(animal: animal, slot: slot)
        }

        return knownPlacements + fallbackPlacements
    }
}

enum CabinAnimalAnimationCatalog {
    struct Entry: Decodable, Equatable {
        var animalId: String
        var filename: String
        var frameCount: Int
        var pixelWidth: Int
        var pixelHeight: Int

        var aspectRatio: CGFloat {
            guard pixelHeight > 0 else { return 1 }
            return CGFloat(pixelWidth) / CGFloat(pixelHeight)
        }
    }

    private struct Manifest: Decodable {
        var resourceSubdirectory: String
        var animations: [Entry]
    }

    static let resourceSubdirectory = "AnimalAnimations"

    static let fallbackEntries: [Entry] = [
        Entry(animalId: "xiaoman_hamster", filename: "animal_animation_xiaoman_hamster.gif", frameCount: 91, pixelWidth: 318, pixelHeight: 420),
        Entry(animalId: "tangyuan_puppy", filename: "animal_animation_tangyuan_puppy.gif", frameCount: 73, pixelWidth: 355, pixelHeight: 420),
        Entry(animalId: "moji_cat", filename: "animal_animation_moji_cat.gif", frameCount: 73, pixelWidth: 387, pixelHeight: 420),
        Entry(animalId: "dengdeng_rabbit", filename: "animal_animation_dengdeng_rabbit.gif", frameCount: 73, pixelWidth: 323, pixelHeight: 420),
        Entry(animalId: "feifei_parrot", filename: "animal_animation_feifei_parrot.gif", frameCount: 73, pixelWidth: 399, pixelHeight: 420),
        Entry(animalId: "xiaolu_guinea_pig", filename: "animal_animation_xiaolu_guinea_pig.gif", frameCount: 73, pixelWidth: 408, pixelHeight: 392),
        Entry(animalId: "deer_visitor", filename: "animal_animation_jiujiu_deer.gif", frameCount: 73, pixelWidth: 267, pixelHeight: 420),
        Entry(animalId: "fox_visitor", filename: "animal_animation_aini_fox.gif", frameCount: 73, pixelWidth: 314, pixelHeight: 419),
        Entry(animalId: "bear_visitor", filename: "animal_animation_dundun_bear.gif", frameCount: 73, pixelWidth: 363, pixelHeight: 420)
    ]

    static func entry(for animalId: String, bundle: Bundle = .main) -> Entry? {
        entries(bundle: bundle).first { $0.animalId == animalId }
    }

    static func animationURL(for animalId: String, bundle: Bundle = .main) -> URL? {
        guard let entry = entry(for: animalId, bundle: bundle) else { return nil }
        let resourceName = (entry.filename as NSString).deletingPathExtension
        let resourceExtension = (entry.filename as NSString).pathExtension
        return bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension,
            subdirectory: resourceSubdirectory
        )
    }

    static func usesPingPongLoop(for animalId: String) -> Bool {
        animalId == "tangyuan_puppy"
    }

    private static func entries(bundle: Bundle) -> [Entry] {
        guard let manifestURL = bundle.url(
            forResource: "manifest",
            withExtension: "json",
            subdirectory: resourceSubdirectory
        ),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data),
              manifest.animations.isEmpty == false else {
            return fallbackEntries
        }
        return manifest.animations
    }
}

struct CabinSceneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var animals: [Animal]
    var isEmpty: Bool = false
    var cabinAssetName: String = "cabin_room_base_night_cutaway"
    var cabinContentMode: ArtImage.ContentMode = .fit
    var layoutProfile: CabinAnimalLayout.LayoutProfile = CabinAnimalLayout.nightCutawayRoom
    var animalGroupLiftRatio: CGFloat = 0
    var preservesAspectRatio: Bool = true

    var body: some View {
        scene
            .onAppear {
                guard reduceMotion == false else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }

    @ViewBuilder
    private var scene: some View {
        if preservesAspectRatio {
            sceneContent
                .frame(maxWidth: .infinity)
                .aspectRatio(layoutProfile.sourceSize.width / layoutProfile.sourceSize.height, contentMode: .fit)
        } else {
            sceneContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sceneContent: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let renderedRect = layoutProfile.renderedRect(in: size, contentMode: cabinContentMode)
            let placements = CabinAnimalLayout.placements(for: Array(animals.prefix(9)), in: layoutProfile)
            let verticalLiftRatio = min(max(animalGroupLiftRatio, 0), 0.025)

            ZStack {
                ArtImage(name: cabinAssetName, contentMode: cabinContentMode)
                    .frame(width: size.width, height: size.height)

                if isEmpty == false {
                    ForEach(placements) { placement in
                        let animationEntry = CabinAnimalAnimationCatalog.entry(for: placement.animal.id)
                        let aspectRatio = animationEntry?.aspectRatio ?? 1
                        let frame = placement.slot.frame(
                            in: renderedRect,
                            aspectRatio: aspectRatio,
                            verticalLiftRatio: verticalLiftRatio
                        )

                        cabinAnimalView(
                            for: placement.animal,
                            maxPixelSize: max(frame.width, frame.height) * UIScreen.main.scale
                        )
                            .frame(width: frame.width, height: frame.height)
                            .scaleEffect(x: placement.slot.isMirrored ? -1 : 1, y: 1, anchor: .center)
                            .scaleEffect(reduceMotion ? 1 : (isBreathing ? 1.012 : 0.996), anchor: .bottom)
                            .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cabinAnimalView(for animal: Animal, maxPixelSize: CGFloat) -> some View {
        if reduceMotion == false,
           let animationURL = CabinAnimalAnimationCatalog.animationURL(for: animal.id) {
            AnimatedGIFImage(
                url: animationURL,
                maxPixelSize: maxPixelSize,
                usesPingPongLoop: CabinAnimalAnimationCatalog.usesPingPongLoop(for: animal.id)
            )
                .accessibilityHidden(true)
        } else {
            ArtImage(name: animal.homeAssetName)
        }
    }
}

private struct AnimatedGIFImage: UIViewRepresentable {
    var url: URL
    var maxPixelSize: CGFloat = 256
    var usesPingPongLoop: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        let roundedMaxPixelSize = max(64, Int(maxPixelSize.rounded(.up)))
        guard context.coordinator.currentURL != url ||
                context.coordinator.currentMaxPixelSize != roundedMaxPixelSize ||
                context.coordinator.currentUsesPingPongLoop != usesPingPongLoop else {
            imageView.startAnimating()
            return
        }

        context.coordinator.currentURL = url
        context.coordinator.currentMaxPixelSize = roundedMaxPixelSize
        context.coordinator.currentUsesPingPongLoop = usesPingPongLoop
        imageView.image = UIImage.animatedGIF(
            from: url,
            maxPixelSize: roundedMaxPixelSize,
            usesPingPongLoop: usesPingPongLoop
        )
        imageView.startAnimating()
    }

    final class Coordinator {
        var currentURL: URL?
        var currentMaxPixelSize: Int?
        var currentUsesPingPongLoop: Bool?
    }
}

private final class AnimatedGIFCache {
    static let shared: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 18
        return cache
    }()
}

private extension UIImage {
    static func animatedGIF(from url: URL, maxPixelSize: Int, usesPingPongLoop: Bool) -> UIImage? {
        let cacheKey = "\(url.absoluteString)#\(maxPixelSize)#pingPong:\(usesPingPongLoop)" as NSString
        if let cached = AnimatedGIFCache.shared.object(forKey: cacheKey) {
            return cached
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0
        let frameOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        for index in 0..<frameCount {
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, index, frameOptions)
            let fullSizeImage = thumbnail ?? CGImageSourceCreateImageAtIndex(source, index, nil)
            guard let cgImage = fullSizeImage else { continue }
            images.append(UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up))
            totalDuration += frameDuration(at: index, source: source)
        }

        guard images.isEmpty == false else { return nil }

        if usesPingPongLoop, images.count > 2 {
            let reverseFrames = images.dropFirst().dropLast().reversed()
            images.append(contentsOf: reverseFrames)
            totalDuration *= 2
        }

        let animatedImage = UIImage.animatedImage(
            with: images,
            duration: max(totalDuration, TimeInterval(images.count) / 15.0)
        )
        if let animatedImage {
            AnimatedGIFCache.shared.setObject(animatedImage, forKey: cacheKey)
        }
        return animatedImage
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 1.0 / 15.0
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = unclampedDelay ?? gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 1.0 / 15.0
        return delay > 0.011 ? delay : 1.0 / 15.0
    }
}
