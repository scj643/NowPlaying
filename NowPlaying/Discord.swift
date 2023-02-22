//
//  Discord.swift
//  nowplaying
//
//  Created by Charles Surett on 1/24/23.
//
#if os(macOS)
import Foundation
import SwordRPC
import Combine

let remote = MediaRemoteBridge()
@available(macOS 11.0, *)
class Discord {
    private var observer: NSObjectProtocol?
    private var playingObserver: NSObjectProtocol?
    var rpc = SwordRPC(appId: "1065440072826105896", handlerInterval: 2000)
    var nowPlaying = NowPlayingInfo( info: ["Empty": true] )
    var app = ""
    var playing = false
    var connected = false
    
    
    init(rpc: SwordRPC = SwordRPC(appId: "1065440072826105896", handlerInterval: 2000)) {
        self.rpc = rpc
    }
    
    deinit {
        self.disconnect()
    }
    
    func connect() {
        self.rpc.onConnect { r in
            r.setPresence(self.getPresence())
        }
        self.connected = self.rpc.connect()
        // This needs to be called twice for osme reason
        self.rpc.setPresence(self.getPresence())
    }
    
    func disconnect() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        if let playingObserver = playingObserver {
            NotificationCenter.default.removeObserver(playingObserver)
        }
        self.rpc.disconnect()
        remote.MRMediaRemoteUnregisterForNowPlayingNotifications()
        self.connected = false
    }
    
    func getPresence() -> RichPresence {
        (remote.MRMediaRemoteGetNowPlayingInfo)(DispatchQueue.main) { information in
            self.nowPlaying = NowPlayingInfo(info: information)
        }
        (remote.MRMediaRemoteGetNowPlayingClient)(DispatchQueue.main) { clientObject in
            self.app = remote.MRNowPlayingClientGetDisplayName(clientObject)
        }
        (remote.MRMediaRemoteGetNowPlayingApplicationIsPlaying)(DispatchQueue.main) { isPlaying in
            self.playing = isPlaying
        }
        return self.npToPresence(song: self.nowPlaying, app: self.app, isPlaying: self.playing)
    }
    
    func listen() {
        self.observer = NotificationCenter.default.addObserver(forName: NowPlayingNotificationsChanges.info, object: nil, queue: nil, using: { notification in
            (remote.MRMediaRemoteGetNowPlayingClient)(DispatchQueue.main) { clientObject in
                self.app = remote.MRNowPlayingClientGetDisplayName(clientObject)
            }
            (remote.MRMediaRemoteGetNowPlayingInfo)(DispatchQueue.main) { information in
                let newNowPlaying = NowPlayingInfo(info: information)
                if newNowPlaying.string() != self.nowPlaying.string() {
                    self.nowPlaying = newNowPlaying
                    self.rpc.setPresence(self.getPresence())
                }
            }
        })
        self.playingObserver = NotificationCenter.default.addObserver(forName: NowPlayingNotificationsChanges.isPlaying, object: nil, queue: nil, using: { notification in
            (remote.MRMediaRemoteGetNowPlayingApplicationIsPlaying)(DispatchQueue.main) { isPlaying in
                self.playing = isPlaying
                self.rpc.setPresence(self.getPresence())
            }
        })
        remote.MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
    }
    
    func npToPresence(song: NowPlayingInfo, app: String, isPlaying: Bool) -> RichPresence {
        var presence = RichPresence()
        presence.instance = false
        if (app != "Music" && UserDefaults.standard.bool(forKey: "onlyMusicApp")) {
            return presence
        }
        presence.details = "\(song.title ?? "")"
        if (song.artist != nil) {
            presence.details = (presence.details ?? "") + " by \(song.artist ?? "")"
        }
        if (song.album != nil) {
            if (song.album != "") {
                presence.state = "(\(song.album ?? ""))"
            }
        }
        var buttons = [RPButton]()
        if (song.songID != nil) {
            if (song.songLinkStr() != nil) {
                buttons.append(RPButton(label: "Song Link", url: (song.songLinkStr())!))
            }
        }
        if (app != "") {
            buttons.append(RPButton(label: "App: \(self.app)", url: "about:blank"))
        }
        if (app == "Music") {
            presence.assets.largeImage = "https://apple-resources.s3.amazonaws.com/media-badges/app-icon-music/standard/en-us.png"
            presence.assets.largeText = "Apple Music"
        }
        if (isPlaying == true) {
            presence.assets.smallImage = "playback-start"
            presence.assets.smallText = "Playing"
            
        } else {
            presence.assets.smallImage = "playback-pause"
            presence.assets.smallText = "Paused"
        }
        presence.buttons = buttons
        if (song.albumID != nil) {
            struct AlbumResults: Decodable {
                var artworkUrl100: String
            }
            struct AlbumArtLookup: Decodable {
                var resultCount: Int
                var results: [AlbumResults]
            }
            let semaphore = DispatchSemaphore(value: 0)
            guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(song.albumID!)") else { return presence }
            let task = URLSession.shared.dataTask(with: url) {
                data, response, error in
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(AlbumArtLookup.self, from: data!)
                    if (decoded.resultCount == 1) {
                        let artUrl = decoded.results[0].artworkUrl100.replacingOccurrences(of: "100x100bb", with: "1024x1024bb")
                        print(artUrl)
                        presence.assets.largeImage = artUrl
                    }
                }
                catch {
                    print(error)
                }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
        return presence
    }
}
#endif
