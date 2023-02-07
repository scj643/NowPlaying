//
//  ContentView.swift
//  NowPlaying
//
//  Created by Charles Surett on 12/21/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var observableNowPlayingService: ObservableNowPlayingService
    var body: some View {
        VStack {
            Text(observableNowPlayingService.nowPlaying?.title ?? "None").multilineTextAlignment(.center)
            Text(observableNowPlayingService.nowPlaying?.artist ?? "NA").multilineTextAlignment(.center)
            Text(observableNowPlayingService.nowPlaying?.album ?? "NA").multilineTextAlignment(.center)
            if observableNowPlayingService.nowPlaying != nil {
                if (observableNowPlayingService.nowPlaying?.songLink() != nil) {
                    Link("Song Link", destination:
                            (observableNowPlayingService.nowPlaying?.songLink()) ?? URL(string: "https://song.link")!)                }
                if (observableNowPlayingService.nowPlaying?.albumLink() != nil) {
                    Link("Album Link", destination:
                            (observableNowPlayingService.nowPlaying?.albumLink()) ?? URL(string: "https://album.link")!)
                }
            }
            if observableNowPlayingService.nowPlaying?.artwork != nil {
                #if os(macOS)
                Image(nsImage: NSImage(data: (observableNowPlayingService.nowPlaying?.artwork)!)! ).resizable().aspectRatio(contentMode: .fit).padding([.all], 10)		
                #elseif os(iOS)
                Image(uiImage:  UIImage(data: (observableNowPlayingService.nowPlaying?.artwork)!)! ).resizable().aspectRatio(contentMode: .fit).padding([.all], 10)
                #endif
            }
            if observableNowPlayingService.nowPlaying != nil {
                if (observableNowPlayingService.nowPlaying?.songLink() != nil) {
                    ShareLink("Song Link", item:
                                (observableNowPlayingService.nowPlaying?.songLink()) ?? URL(string: "https://song.link")!).padding([.all], 10)                }
            }
        }
        .padding([.horizontal], 5).frame(minWidth: 300, minHeight: 450)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(observableNowPlayingService: ObservableNowPlayingService()).frame(width: 300, height: 450, alignment: .center)
    }
}
