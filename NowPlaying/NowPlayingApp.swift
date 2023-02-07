//
//  NowPlayingApp.swift
//  NowPlaying
//
//  Created by Charles Surett on 12/21/22.
//

import SwiftUI
#if os(macOS)
import SwordRPC
#endif

@main
struct NowPlayingApp: App {
    var observableNowPlayingService: ObservableNowPlayingService
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    let discord = Discord()
    @State var discordState: String = "Connect Discord"
    #endif
    init() {
        self.observableNowPlayingService = ObservableNowPlayingService()
        #if os(macOS)
        NSApplication.shared.windows.forEach({ $0.tabbingMode = .disallowed
        })
        NSWindow.allowsAutomaticWindowTabbing = false
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(observableNowPlayingService: self.observableNowPlayingService)
            #if os(macOS)
                .onAppear{
                NSApplication.shared.mainMenu?.items.forEach({ item in
                    if (item.title == "Edit") {
                        NSApplication.shared.mainMenu?.removeItem(item)
                    }
                })
            }
            #endif
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            CommandGroup(replacing: .pasteboard, addition: {
                Button("Copy Nowplaying") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(self.observableNowPlayingService.nowPlaying?.songLinkStr() ?? "",
                                                   forType: NSPasteboard.PasteboardType.string)
                    #else
                    UIPasteboard.general.string = self.observableNowPlayingService.nowPlaying?.songLinkStr() ?? ""
                    #endif
                }.keyboardShortcut("C")
                Button("Copy Artwork") {
                    if (self.observableNowPlayingService.nowPlaying?.artwork != nil) {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setData(self.observableNowPlayingService.nowPlaying?.artwork, forType: NSPasteboard.PasteboardType.png)
                        #else
                        UIPasteboard.general.image = UIImage(data: (self.observableNowPlayingService.nowPlaying?.artwork)!)
                        #endif
                    }
                }.keyboardShortcut("K")

            })
            #if os(macOS)
            CommandMenu("Discord") {
                Button(self.discordState) {
                    if (self.discord.connected) {
                        self.discord.disconnect()
                        self.discordState = "Connect Discord"
                    } else {
                        self.discord.connect()
                        self.discord.listen()
                        if (self.discord.connected) {
                            self.discordState = "Disconnect Discord"
                        } else {
                            // If we fail to connect reset client once
                            self.discord.rpc = SwordRPC(appId: "1065440072826105896", handlerInterval: 2000)
                            self.discord.connect()
                            self.discord.listen()
                            if (self.discord.connected) {
                                self.discordState = "Disconnect Discord"
                            }
                        }
                    }
                }.keyboardShortcut("D")
            }
            #endif
            CommandGroup(replacing: .textEditing, addition: { })
            CommandGroup(replacing: .undoRedo, addition: { })
        }
        
    }
}

#if os(macOS)
public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    public func applicationWillFinishLaunching(_ notification: Notification) {
      UserDefaults.standard.set(true, forKey: "NSDisabledDictationMenuItem")
      UserDefaults.standard.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
    }
}
#endif
