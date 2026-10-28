import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Nichiji")
            .font(.largeTitle)
            .accessibilityIdentifier("title")
    }
}

#Preview {
    ContentView()
}
