import ImageIO
import SwiftUI
import UIKit

struct CabinAnimalLayout {
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
    }

    struct Placement: Identifiable {
        var id: String { animal.id }
        var animal: Animal
        var slot: Slot
    }

    static let slots: [Slot] = [
        Slot(
            animalId: "xiaoman_hamster",
            floor: .top,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.315, y: 0.505),
            heightRatio: 0.062
        ),
        Slot(
            animalId: "moji_cat",
            floor: .top,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.500, y: 0.435),
            heightRatio: 0.060
        ),
        Slot(
            animalId: "dengdeng_rabbit",
            floor: .top,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.695, y: 0.505),
            heightRatio: 0.062,
            isMirrored: true
        ),
        Slot(
            animalId: "tangyuan_puppy",
            floor: .middle,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.195, y: 0.610),
            heightRatio: 0.070
        ),
        Slot(
            animalId: "xiaolu_guinea_pig",
            floor: .middle,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.395, y: 0.617),
            heightRatio: 0.066
        ),
        Slot(
            animalId: "bear_visitor",
            floor: .middle,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.600, y: 0.617),
            heightRatio: 0.068,
            isMirrored: true
        ),
        Slot(
            animalId: "deer_visitor",
            floor: .bottom,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.805, y: 0.610),
            heightRatio: 0.066
        ),
        Slot(
            animalId: "fox_visitor",
            floor: .bottom,
            side: .leftLarge,
            footPointRatio: CGPoint(x: 0.355, y: 0.668),
            heightRatio: 0.070
        ),
        Slot(
            animalId: "feifei_parrot",
            floor: .bottom,
            side: .rightSmall,
            footPointRatio: CGPoint(x: 0.655, y: 0.668),
            heightRatio: 0.066
        )
    ]

    static func slot(for animalId: String) -> Slot? {
        slots.first { $0.animalId == animalId }
    }

    static func placements(for animals: [Animal]) -> [Placement] {
        let animalsById = Dictionary(animals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
    private let sceneAspectRatio: CGFloat = 1254.0 / 2712.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var animals: [Animal]
    var isEmpty: Bool = false
    var cabinAssetName: String = "cabin_room_base_night_cutaway"
    var cabinContentMode: ArtImage.ContentMode = .fit
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
                .aspectRatio(sceneAspectRatio, contentMode: .fit)
        } else {
            sceneContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sceneContent: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let placements = CabinAnimalLayout.placements(for: Array(animals.prefix(9)))

            ZStack {
                ArtImage(name: cabinAssetName, contentMode: cabinContentMode)
                    .frame(width: size.width, height: size.height)

                if isEmpty == false {
                    ForEach(placements) { placement in
                        let animationEntry = CabinAnimalAnimationCatalog.entry(for: placement.animal.id)
                        let aspectRatio = animationEntry?.aspectRatio ?? 1
                        let frame = placement.slot.frame(in: size, aspectRatio: aspectRatio)

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
