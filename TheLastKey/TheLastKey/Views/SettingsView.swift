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
                Section {
                    Stepper("\(dailySessionSize) cards", value: $dailySessionSize, in: 3...15)
                } header: {
                    Label("Daily session", systemImage: "sun.and.horizon.fill")
                        .foregroundStyle(Theme.amberDeep)
                } footer: {
                    Text("How many cards each session includes.")
                }

                Section {
                    Picker("Voice", selection: $ttsVoiceIdentifier) {
                        Text("Default (en-US)").tag("")
                        ForEach(voices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rate")
                        HStack(spacing: 12) {
                            Text("Slower")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: $ttsRate,
                                in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate)
                            )
                            Text("Faster")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        SpeechService.shared.speak("He had to bite the bullet.")
                    } label: {
                        Label("Preview voice", systemImage: "play.circle.fill")
                            .foregroundStyle(Theme.amberDeep)
                    }
                } header: {
                    Label("Voice", systemImage: "waveform")
                        .foregroundStyle(Theme.amberDeep)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "key.fill")
                        .foregroundStyle(Theme.amberDeep)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
