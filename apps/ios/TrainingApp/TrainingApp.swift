import SwiftData
import SwiftUI

@main
struct TrainingApp: App {
    @StateObject private var auth = AuthSession()

    init() {
        let defaults = UserDefaults.standard
        let oldURLs = [
            "https://pc.tail9b847f.ts.net/api/v1/",
            "http://100.67.143.48:8181/api/v1/"
        ]
        if let saved = defaults.string(forKey: "apiBaseURL"), oldURLs.contains(saved) {
            defaults.set("http://192.168.31.45:8181/api/v1/", forKey: "apiBaseURL")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .tint(.trainingLime)
                .preferredColorScheme(.dark)
        }
            .modelContainer(for: [Workout.self, WorkoutExercise.self, SetEntry.self])
    }
}
