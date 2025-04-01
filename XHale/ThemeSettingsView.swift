import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("themeColor") private var themeColor: String = "Blue"
    let themes = ["Blue", "Green", "Purple", "Red"]
    
    var body: some View {
        Form {
            Picker("Select Theme", selection: $themeColor) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme)
                }
            }
        }
        .navigationTitle("Theme Settings")
    }
}
