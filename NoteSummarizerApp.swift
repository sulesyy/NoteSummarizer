//
//  NoteSummarizerApp.swift
//  NoteSummarizer
//
//  Created by Şule Yılmaz on 7.03.2026.
//

import SwiftUI

@main
struct NoteSummarizerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
