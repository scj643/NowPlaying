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
                    self.rpc.setPresence(self.npToPresence(song: self.nowPlaying, app: self.app, isPlaying: self.playing))
                }
            }
        })
        self.playingObserver = NotificationCenter.default.addObserver(forName: NowPlayingNotificationsChanges.isPlaying, object: nil, queue: nil, using: { notification in
            (remote.MRMediaRemoteGetNowPlayingApplicationIsPlaying)(DispatchQueue.main) { isPlaying in
                self.playing = isPlaying
                self.rpc.setPresence(self.npToPresence(song: self.nowPlaying, app: self.app, isPlaying: self.playing))
            }
        })
        remote.MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
    }
    
    func npToPresence(song: NowPlayingInfo, app: String, isPlaying: Bool) -> RichPresence {
        var presence = RichPresence()
        presence.instance = false
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
        return presence
    }
}
#endif