//
//  MediaRemote.swift
//  nowplaying
//
//  Created by Charles Surett on 12/21/22.
//

import Foundation

let BUNDLE_LOCATION = "/System/Library/PrivateFrameworks/MediaRemote.framework"


let MediaTypes = ["MRMediaRemoteMediaTypeMusic": "Music",
                  "kMRMediaRemoteNowPlayingInfoTypeVideo": "Video"]

struct NowPlayingNotificationsChanges {
    static let info = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
    static let queue = Notification.Name("kMRNowPlayingPlaybackQueueChangedNotification")
    static let isPlaying = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")
    static let application = Notification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification")
    static let all = [info, queue, isPlaying, application]
}

class NowPlayingInfo {
    var info: [String : Any]
    init(info: [String : Any]) {
        self.info = info
    }
    
    var title: String? {
        return self.info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? nil
    }
    var album: String? {
        return self.info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? nil
    }
    var artist: String? {
        return self.info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? nil
    }
    
    var composer: String? {
        return self.info["kMRMediaRemoteNowPlayingInfoComposer"] as? String ?? nil
    }
    
    var genre: String? {
        return self.info["kMRMediaRemoteNowPlayingInfoGenre"] as? String ?? nil
    }
    
    var trackNumber: Int32? {
        return self.info["kMRMediaRemoteNowPlayingInfoTrackNumber"] as? Int32 ?? nil
    }
    
    var trackCount: Int32? {
        return self.info["kMRMediaRemoteNowPlayingInfoTotalTrackCount"] as? Int32 ?? nil
    }
    
    var mediaType: String {
        return MediaTypes[self.info["kMRMediaRemoteNowPlayingInfoMediaType"] as? String ?? "Unknown"] ?? "Unknown"
    }
    
    var duration: Double? {
        return self.info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? nil
    }
    
    var artwork: Data? {
        return self.info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data ?? nil
    }
    
    func string() -> String {
        var returnString = ""
        if (self.title != nil) {
            returnString += "\(title!)"
        }
        if (self.artist != nil) {
            returnString += " by \(artist!)"
        }
        if (self.album != nil) {
            returnString += " (\(album!))"
        }
        return returnString
    }
    
    var songID: Int? {
        return info["kMRMediaRemoteNowPlayingInfoiTunesStoreIdentifier"] as? Int
    }
    var albumID: Int? {
        return info["kMRMediaRemoteNowPlayingInfoAlbumiTunesStoreAdamIdentifier"] as? Int
    }
    
    private func strToUrl(string: String?) -> URL? {
        if string != nil {
            return URL(string: string!)
        } else {
            return nil
        }
    }
    
    func songLinkStr() -> String? {
        if songID != nil {
            return String(format: "https://song.link/i/%d", songID!)
        } else {
            return nil
        }
    }
    
    func albumLinkStr() -> String? {
        if albumID != nil {
            return String(format: "https://album.link/i/%d", albumID!)
        } else {
            return nil
        }
    }
    
func songLink() -> URL? {
        return strToUrl(string: songLinkStr())
    }
    
    func albumLink() -> URL? {
        return strToUrl(string: albumLinkStr())
    }
}


// Helper struct for Media Remote functions
struct MediaRemoteBridge {
    // MediaRemote types
    typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
    typealias MRMediaRemoteUnregisterForNowPlayingNotificationsFunction = @convention(c) () -> Void
    typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    typealias MRNowPlayingClientGetBundleIdentifierFunction = @convention(c) (AnyObject?) -> String
    typealias MRNowPlayingClientGetDisplayNameFunction = @convention(c) (AnyObject?) -> String
    typealias MRMediaRemoteGetNowPlayingClientFunction = @convention(c) (DispatchQueue, @escaping (AnyObject) -> Void) -> Void
    
    var MRMediaRemoteRegisterForNowPlayingNotifications: MRMediaRemoteRegisterForNowPlayingNotificationsFunction
    var MRMediaRemoteUnregisterForNowPlayingNotifications: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction
    var MRMediaRemoteGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction
    var MRMediaRemoteGetNowPlayingApplicationIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction
    var MRNowPlayingClientGetBundleIdentifier: MRNowPlayingClientGetBundleIdentifierFunction
    var MRNowPlayingClientGetDisplayName: MRNowPlayingClientGetDisplayNameFunction
    var MRMediaRemoteGetNowPlayingClient: MRMediaRemoteGetNowPlayingClientFunction
    
    let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: BUNDLE_LOCATION))
    
    init() {
        guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteRegisterForNowPlayingNotifications")
        }
        self.MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        
        guard let MRMediaRemoteUnregisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteUnregisterForNowPlayingNotifications" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteUnregisterForNowPlayingNotifications")
        }
        self.MRMediaRemoteUnregisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteUnregisterForNowPlayingNotificationsPointer, to: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction.self)
        
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteGetNowPlayingInfo")
        }
        self.MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        
        guard let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteGetNowPlayingApplicationIsPlaying")
        }
        MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
        
        guard let MRNowPlayingClientGetBundleIdentifierPointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString) else {
            fatalError("Failed to get function pointer: MRNowPlayingClientGetBundleIdentifier")
        }
        MRNowPlayingClientGetBundleIdentifier = unsafeBitCast(MRNowPlayingClientGetBundleIdentifierPointer, to: MRNowPlayingClientGetBundleIdentifierFunction.self)
        
        guard let MRNowPlayingClientGetDisplayNamePointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetDisplayName" as CFString) else {
            fatalError("Failed to get function pointer: MRNowPlayingClientGetDisplayName")
        }
        MRNowPlayingClientGetDisplayName = unsafeBitCast(MRNowPlayingClientGetDisplayNamePointer, to: MRNowPlayingClientGetDisplayNameFunction.self)

        guard let MRMediaRemoteGetNowPlayingClientPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingClient" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteGetNowPlayingClient")
        }
        MRMediaRemoteGetNowPlayingClient = unsafeBitCast(MRMediaRemoteGetNowPlayingClientPointer, to: MRMediaRemoteGetNowPlayingClientFunction.self)
    }
}

class NowPlayingService {
    let mediaRemote = MediaRemoteBridge()
    private var observers: [NSObjectProtocol?]
    var nowPlaying: NowPlayingInfo?
    
    init() {
        observers = []
        for o in NowPlayingNotificationsChanges.all {
            observers.append(
                NotificationCenter.default.addObserver(forName: o, object: nil, queue: .main, using: { notification in
                    self.handleNowPlayingChanged(notification: notification)
                })
            )
        }
        self.mediaRemote.MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        updateSong()
    }
    
    deinit {
        for observer in observers {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    func updateSong() {
        (mediaRemote.MRMediaRemoteGetNowPlayingInfo)(DispatchQueue.main) { information in
            self.nowPlaying = NowPlayingInfo(info: information)
        }
    }
    func handleNowPlayingChanged(notification: Notification) {
        switch notification.name {
        case NowPlayingNotificationsChanges.info:
            updateSong()
            NSLog("nowPlayingInfoDidChangeNotification")
        case NowPlayingNotificationsChanges.queue:
            NSLog("nowPlayingPlaybackQueueChangedNotification")
        case NowPlayingNotificationsChanges.isPlaying:
            NSLog("nowPlayingApplicationIsPlayingDidChange")
        case NowPlayingNotificationsChanges.application:
            NSLog("nowPlayingApplicationChanged")
        default:
            NSLog("Other")
        }
    }
}

@available(macOS 10.15, *)
class ObservableNowPlayingService: ObservableObject {
    @Published var nowPlaying: NowPlayingInfo?
    private var mediaRemote = MediaRemoteBridge()
    private var observer: NSObjectProtocol?
    
    init() {
        self.observer = NotificationCenter.default.addObserver(forName: NowPlayingNotificationsChanges.info, object: nil, queue: .main, using: { notification in
            self.updateSongs()
        })
        self.mediaRemote.MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        updateSongs()
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    func updateSongs() {
        (self.mediaRemote.MRMediaRemoteGetNowPlayingInfo)(DispatchQueue.main) { information in
            self.nowPlaying = NowPlayingInfo(info: information)
        }
    }
}
