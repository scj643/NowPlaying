//
//  NowPlayingApp.swift
//  NowPlaying
//
//  Created by Charles Surett on 12/21/22.
//

import SwiftUI

@main
struct NowPlayingApp: App {
    var observableNowPlayingService: ObservableNowPlayingService
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
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
            })
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
