import SwiftUI

// The full-app preview lives here rather than in ContentView.swift, where the
// macOS preview harness launches the app entry point and crashes inside List.
#Preview("Stats Lab") {
    ContentView()
        .environment(ProgressStore())
        .frame(width: 1100, height: 700)
}

#Preview("Language switch") {
    LanguageSwitch()
        .padding(40)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}

#Preview("Code block · Python") {
    UserDefaults.standard.set(CodeLanguage.python.rawValue, forKey: "codeLanguage")
    UserDefaults.standard.set(false, forKey: "showsMplus")
    return CodeBlockView(sample: Curriculum.latentClass.blocks.compactMap {
        if case .code(let sample) = $0, sample.mplus != nil { sample } else { nil }
    }[0])
    .padding(24)
    .frame(width: 640)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Code block · R") {
    UserDefaults.standard.set(CodeLanguage.r.rawValue, forKey: "codeLanguage")
    UserDefaults.standard.set(false, forKey: "showsMplus")
    return CodeBlockView(sample: Curriculum.latentClass.blocks.compactMap {
        if case .code(let sample) = $0, sample.mplus != nil { sample } else { nil }
    }[0])
    .padding(24)
    .frame(width: 640)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
