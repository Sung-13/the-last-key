import AVFoundation
import Foundation

final class SpeechService {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)

        let voiceID = UserDefaults.standard.string(forKey: "ttsVoiceIdentifier") ?? ""
        if !voiceID.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        if let storedRate = UserDefaults.standard.object(forKey: "ttsRate") as? Double {
            utterance.rate = Float(storedRate)
        } else {
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        }

        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    static var availableEnglishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }
}
