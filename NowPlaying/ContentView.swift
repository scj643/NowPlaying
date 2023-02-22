//
//  ContentView.swift
//  NowPlaying
//
//  Created by Charles Surett on 12/21/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var observableNowPlayingService: ObservableNowPlayingService
    @AppStorage("onlyMusicApp") var onlyMusicApp = true
    var body: some View {
        VStack {
            Text(observableNowPlayingService.nowPlaying?.title ?? "None")
                .multilineTextAlignment(.center)
                .padding([.vertical], 5)
            if (observableNowPlayingService.nowPlaying?.artist != nil) {
                if (observableNowPlayingService.nowPlaying?.artist != "") {
                    Text("Artist: \(observableNowPlayingService.nowPlaying?.artist ?? "NA")")
                        .multilineTextAlignment(.center)
                }
            }
            if (observableNowPlayingService.nowPlaying?.album != nil) {
                if (observableNowPlayingService.nowPlaying?.album != ""){
                    Text("Album: \(observableNowPlayingService.nowPlaying?.album ?? "NA")")
                        .multilineTextAlignment(.center)
                }
            }
            
            
            if observableNowPlayingService.nowPlaying != nil {
                if (observableNowPlayingService.nowPlaying?.songLink() != nil) {
                    Link("Song Link", destination:
                            (observableNowPlayingService.nowPlaying?
                                .songLink()) ?? URL(string: "https://song.link")!)
                }
                if (observableNowPlayingService.nowPlaying?.albumLink() != nil) {
                    Link("Album Link", destination:
                            (observableNowPlayingService.nowPlaying?.albumLink()) ?? URL(string: "https://album.link")!)
                }
            }
            if observableNowPlayingService.nowPlaying?.artwork != nil {
                #if os(macOS)
                Image(nsImage: NSImage(data: (observableNowPlayingService.nowPlaying?.artwork)!)! )
                    .resizable()
                    .accessibilityLabel("Album Art")
                    .aspectRatio(contentMode: .fit)
                    .padding([.all], 10)
                    
                #elseif os(iOS)
                Image(uiImage:  UIImage(data: (observableNowPlayingService.nowPlaying?.artwork)!)! ).resizable().aspectRatio(contentMode: .fit).padding([.all], 10).accessibilityLabel("Album Artwork")
                #endif
            }
            if observableNowPlayingService.nowPlaying != nil {
                Button("Copy Nowplaying as string") {
#if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(self.observableNowPlayingService.nowPlaying?.string() ?? "",
                                                   forType: NSPasteboard.PasteboardType.string)
#else
                    UIPasteboard.general.string = self.observableNowPlayingService.nowPlaying?.string() ?? ""
#endif
                }
                #if DEBUG
                Button("Dump nowplaying to log") {
                    if (self.observableNowPlayingService.nowPlaying != nil) {
                        for (k, v) in self.observableNowPlayingService.nowPlaying!.info {
                            NSLog("%@ - %@", [k, v])
                        }
                    }
                    if (self.observableNowPlayingService.client != nil) {
                        print(self.observableNowPlayingService.client ?? "<NIL>")
                    }
                    
                }
                Button("Dump bundle to log") {
                    (self.observableNowPlayingService.remote.MRMediaRemoteGetNowPlayingClient)(DispatchQueue.main) { clientObject in
                        let appBundleIdentifier = self.observableNowPlayingService.remote.MRNowPlayingClientGetBundleIdentifier(clientObject)
                        print(appBundleIdentifier)
                    }
                }
                #endif
                if (observableNowPlayingService.nowPlaying?.songLink() != nil) {
                    ShareLink("Song Link", item:
                                (observableNowPlayingService.nowPlaying?.songLink()) ?? URL(string: "https://song.link")!).padding([.all], 10)
                        .accessibilityLabel("Share song.link")
                }
                #if os(macOS)
                Toggle(isOn: $onlyMusicApp) {
                    Text("Only show Apple Music app in Discord")
                }
                .padding([.vertical], 10)
                #endif
            }
        }
        .padding([.horizontal], 5)
        .padding([.vertical], 5)
        .frame(minWidth: 300, minHeight: 450)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(observableNowPlayingService: ObservableNowPlayingService()).frame(width: 300, height: 450, alignment: .center)
    }
}
