import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("dailySessionSize") private var dailySessionSize: Int = 5
    @AppStorage("ttsRate") private var ttsRate: Double = Double(AVSpeechUtteranceDefaultSpeechRate)
    @AppStorage("ttsVoiceIdentifier") private var ttsVoiceIdentifier: String = ""

    private var voices: [AVSpeechSynthesisVoice] {
        SpeechService.availableEnglishVoices
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily session") {
                    Stepper("\(dailySessionSize) cards", value: $dailySessionSize, in: 3...15)
                }

                Section("Voice") {
                    Picker("Voice", selection: $ttsVoiceIdentifier) {
                        Text("Default (en-US)").tag("")
                        ForEach(voices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Rate")
                        Slider(
                            value: $ttsRate,
                            in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate)
                        )
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
