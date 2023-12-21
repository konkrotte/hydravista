import SwiftUI
import AVKit

struct EntryVideoView: View {
    let video: (player: AVPlayer, looper: AVPlayerLooper)
    
    init(url: URL) {
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        
        queuePlayer.isMuted = true // TODO: Introduce a setting for this
        
        self.video = (queuePlayer, playerLooper)
    }
    var body: some View {
        VideoPlayer(player: video.player)
            .onAppear { video.player.play() }
            .onDisappear{ video.player.pause() }
    }
}
