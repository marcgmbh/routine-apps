import Foundation
import AVKit

final class DefaultMediaLoader: MediaLoader {
    func makePlayer(url: URL) -> AVPlayer { AVPlayer(url: url) }

    func preload(url: URL) {
        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {}
    }
}
