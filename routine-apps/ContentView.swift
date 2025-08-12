//
//  ContentView.swift
//  routine-apps
//
//  Created by marc on 09.08.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
            .task {
                try? await LocalNotificationScheduler().requestAuthorization()
            }
    }
}

#Preview {
    ContentView()
}
