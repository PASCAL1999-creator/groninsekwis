//
//  ContentView.swift
//  Dizze Kwis is Nait Normaal
//
//  Created by Pascal Koster on 21/06/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import AudioToolbox
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

// MARK: - Haptics
#if canImport(UIKit)
enum Haptics {
    static func success(enabled: Bool = true) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error(enabled: Bool = true) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func selection(enabled: Bool = true) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
#endif

// MARK: - Sounds (iOS)
#if canImport(UIKit)
enum Sounds {
    static func correct(enabled: Bool = true) {
        guard enabled else { return }
        // "Tink"
        AudioServicesPlaySystemSound(1104)
    }
    static func wrong(enabled: Bool = true) {
        guard enabled else { return }
        // "Tock"
        AudioServicesPlaySystemSound(1106)
    }
    static func warning(enabled: Bool = true) {
        guard enabled else { return }
        // "Beep-beep"
        AudioServicesPlaySystemSound(1053)
    }
}
#endif

// MARK: - Speech (TTS)
#if canImport(AVFoundation)
final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking: Bool = false
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, language: String = "nl-NL", rate: Float = 0.5, pitch: Float = 1.0) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "nl-NL")
        // iOS default ~0.5. Houd de range prettig verstaanbaar.
        utterance.rate = max(0.2, min(0.6, rate))
        utterance.pitchMultiplier = max(0.8, min(1.2, pitch))
        utterance.postUtteranceDelay = 0.05
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
#else
// Fallback stub wanneer AVFoundation niet beschikbaar is
final class SpeechManager: ObservableObject {
    @Published var isSpeaking: Bool = false
    func speak(_ text: String, language: String = "nl-NL", rate: Float = 0.5, pitch: Float = 1.0) {}
    func stop() {}
}
#endif

// MARK: - Highscores
struct Highscore: Codable, Equatable {
    let correct: Int
    let points: Int
}

enum HighscoreManager {
    static func key(for level: QuizLevel) -> String { "highscore_\(level.rawValue)" }
    
    static func load(for level: QuizLevel) -> Highscore? {
        let k = key(for: level)
        guard let data = UserDefaults.standard.data(forKey: k) else { return nil }
        return try? JSONDecoder().decode(Highscore.self, from: data)
    }
    
    @discardableResult
    static func updateIfBetter(level: QuizLevel, correct: Int, points: Int) -> Bool {
        let new = Highscore(correct: correct, points: points)
        if let existing = load(for: level) {
            // Beter als meer punten, of bij gelijke punten meer goede antwoorden
            if new.points > existing.points || (new.points == existing.points && new.correct > existing.correct) {
                save(new, for: level)
                return true
            } else {
                return false
            }
        } else {
            save(new, for: level)
            return true
        }
    }
    
    static func save(_ highscore: Highscore, for level: QuizLevel) {
        let k = key(for: level)
        if let data = try? JSONEncoder().encode(highscore) {
            UserDefaults.standard.set(data, forKey: k)
        }
    }
    
    static func reset(for level: QuizLevel) {
        UserDefaults.standard.removeObject(forKey: key(for: level))
    }
    
    static func resetAll() {
        QuizLevel.allCases.forEach { reset(for: $0) }
    }
}

// MARK: - Reusable Styles
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            )
    }
}
extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
        )
    }
}

// MARK: - Circular Timer View
struct CircularTimerView: View {
    let total: Double
    let remaining: Double
    var color: Color = GroningseKleuren.blauw

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, remaining / total))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            VStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(GroningseKleuren.wit.opacity(0.9))
                Text("\(Int(remaining))")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(remaining <= 3 ? GroningseKleuren.rood : GroningseKleuren.wit)
            }
        }
        .frame(width: 64, height: 64)
        .glassCard(cornerRadius: 32)
    }
}

// MARK: - Confetti (iOS)
#if canImport(UIKit)
struct ConfettiView: UIViewRepresentable {
    let colors: [UIColor]
    let intensity: Float

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)

        func makeCell(_ color: UIColor, symbol: String) -> CAEmitterCell {
            let cell = CAEmitterCell()
            cell.birthRate = 8 * intensity
            cell.lifetime = 6
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 6
            cell.spin = 3.5
            cell.spinRange = 4
            cell.scale = 0.5
            cell.scaleRange = 0.3
            let image = UIImage(systemName: symbol)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
            cell.contents = image?.cgImage
            return cell
        }

        emitter.emitterCells = colors.flatMap { color in
            [
                makeCell(color, symbol: "circle.fill"),
                makeCell(color, symbol: "square.fill"),
                makeCell(color, symbol: "triangle.fill")
            ]
        }

        view.layer.addSublayer(emitter)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif

// Quiz vraag structuur
struct QuizVraag {
    let vraag: String
    let antwoorden: [String]
    let juisteAntwoord: Int
    let uitleg: String
    let level: QuizLevel
    let punten: Int
}

// Quiz levels
enum QuizLevel: String, CaseIterable {
    case makkelijk = "Makkelijk"
    case gemiddeld = "Gemiddeld"
    case moeilijk = "Moeilijk"
    
    var color: Color {
        switch self {
        case .makkelijk: return GroningseKleuren.groen
        case .gemiddeld: return GroningseKleuren.blauw
        case .moeilijk: return GroningseKleuren.rood
        }
    }
    
    var icon: String {
        switch self {
        case .makkelijk: return "leaf.fill"
        case .gemiddeld: return "house.fill"
        case .moeilijk: return "crown.fill"
        }
    }
    
    var groningseNaam: String {
        switch self {
        case .makkelijk: return "Moi"
        case .gemiddeld: return "Gewoon"
        case .moeilijk: return "Moeilijk"
        }
    }
}

// Groningse kleuren gebaseerd op de vlag
struct GroningseKleuren {
    static let rood = Color(red: 216/255, green: 44/255, blue: 44/255)
    static let groen = Color(red: 0/255, green: 128/255, blue: 56/255)
    static let blauw = Color(red: 44/255, green: 82/255, blue: 156/255)
    static let wit = Color.white
    static let donkerGroen = Color(red: 0, green: 100/255, blue: 40/255)
}

// Quiz data in het Gronings met levels en punten
let groningseQuizVragen = [
    // Makkelijk level (10 punten)
    QuizVraag(
        vraag: "Wat betekent 'moi' in het Gronings?",
        antwoorden: ["Dag", "Mooi", "Goed", "Hallo"],
        juisteAntwoord: 0,
        uitleg: "'Moi' betekent 'dag' of 'hallo' in het Gronings!",
        level: .makkelijk,
        punten: 10
    ),
    QuizVraag(
        vraag: "Wat is de betekenis van 'nait'?",
        antwoorden: ["Niet", "Naar", "Nog", "Nu"],
        juisteAntwoord: 0,
        uitleg: "'Nait' betekent 'niet' in het Gronings!",
        level: .makkelijk,
        punten: 10
    ),
    QuizVraag(
        vraag: "Wat betekent 'kwis'?",
        antwoorden: ["Quiz", "Kwis", "Vraag", "Spel"],
        juisteAntwoord: 0,
        uitleg: "'Kwis' is gewoon 'quiz' in het Gronings!",
        level: .makkelijk,
        punten: 10
    ),
    QuizVraag(
        vraag: "Wat is 'normaal' in het Gronings?",
        antwoorden: ["Normaal", "Gewoon", "Gewoonlijk", "Altijd"],
        juisteAntwoord: 0,
        uitleg: "'Normaal' blijft 'normaal' in het Gronings!",
        level: .makkelijk,
        punten: 10
    ),
    
    // Gemiddeld level (20 punten)
    QuizVraag(
        vraag: "Wat betekent 'dizze'?",
        antwoorden: ["Deze", "Die", "Dat", "Het"],
        juisteAntwoord: 0,
        uitleg: "'Dizze' betekent 'deze' in het Gronings!",
        level: .gemiddeld,
        punten: 20
    ),
    QuizVraag(
        vraag: "Wat is 'is' in het Gronings?",
        antwoorden: ["Is", "Zijn", "Wordt", "Blijft"],
        juisteAntwoord: 0,
        uitleg: "'Is' blijft 'is' in het Gronings!",
        level: .gemiddeld,
        punten: 20
    ),
    QuizVraag(
        vraag: "Wat betekent 'wa' in het Gronings?",
        antwoorden: ["Wat", "Wie", "Waar", "Wanneer"],
        juisteAntwoord: 0,
        uitleg: "'Wa' betekent 'wat' in het Gronings!",
        level: .gemiddeld,
        punten: 20
    ),
    QuizVraag(
        vraag: "Wat is 'doe' in het Gronings?",
        antwoorden: ["Doe", "Doe je", "Doe het", "Doe maar"],
        juisteAntwoord: 0,
        uitleg: "'Doe' betekent 'doe' in het Gronings!",
        level: .gemiddeld,
        punten: 20
    ),
    
    // Moeilijk level (30 punten)
    QuizVraag(
        vraag: "Wat betekent 'zo' in het Gronings?",
        antwoorden: ["Zo", "Zus", "Zusje", "Zuster"],
        juisteAntwoord: 0,
        uitleg: "'Zo' betekent 'zo' in het Gronings!",
        level: .moeilijk,
        punten: 30
    ),
    QuizVraag(
        vraag: "Wat is 'mien' in het Gronings?",
        antwoorden: ["Mijn", "Me", "Mij", "Mijn"],
        juisteAntwoord: 0,
        uitleg: "'Mien' betekent 'mijn' in het Gronings!",
        level: .moeilijk,
        punten: 30
    ),
    QuizVraag(
        vraag: "Wat betekent 'bist' in het Gronings?",
        antwoorden: ["Ben je", "Bent", "Zijn", "Wordt"],
        juisteAntwoord: 0,
        uitleg: "'Bist' betekent 'ben je' in het Gronings!",
        level: .moeilijk,
        punten: 30
    ),
    QuizVraag(
        vraag: "Wat is 'komt' in het Gronings?",
        antwoorden: ["Komt", "Komen", "Gaan", "Lopen"],
        juisteAntwoord: 0,
        uitleg: "'Komt' betekent 'komt' in het Gronings!",
        level: .moeilijk,
        punten: 30
    )
]

// App states
enum AppState {
    case welcome
    case startMenu
    case levelSelection
    case quiz
    case results
    case highscores
    case settings
}

struct ContentView: View {
    @State private var appState: AppState = .welcome
    @State private var huidigeVraagIndex = 0
    @State private var score = 0
    @State private var totaalPunten = 0
    @State private var toonAntwoord = false
    @State private var gekozenAntwoord: Int? = nil
    @State private var animatieOffset: CGFloat = 1000
    @State private var buttonScale: CGFloat = 1.0
    @State private var geselecteerdLevel: QuizLevel = .makkelijk
    @State private var timerSeconds = 10
    @State private var timerActive = false
    @State private var vragenVoorLevel: [QuizVraag] = []
    @State private var timerTotal = 10
    @StateObject private var speechManager = SpeechManager()
    
    // Instellingen (blijven bewaard)
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("warningSoundEnabled") private var warningSoundEnabled = true
    @AppStorage("timeEasy") private var timeEasy = 12
    @AppStorage("timeMedium") private var timeMedium = 10
    @AppStorage("timeHard") private var timeHard = 8
    
    // Spraak-instellingen
    @AppStorage("speechEnabled") private var speechEnabled = true
    @AppStorage("speechOnAnswer") private var speechOnAnswer = true
    @AppStorage("speechRate") private var speechRate: Double = 0.5
    @AppStorage("speechPitch") private var speechPitch: Double = 1.0
    @AppStorage("speechLang") private var speechLang: String = "nl-NL" // geen aparte Groningse stem, dus NL
    
    var body: some View {
        ZStack {
            // Groningse gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    GroningseKleuren.blauw.opacity(0.9),
                    GroningseKleuren.groen.opacity(0.7),
                    GroningseKleuren.rood.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Groningse patroon overlay
            GroningsePatroonView()
                .opacity(0.08)
                .ignoresSafeArea()
            
            switch appState {
            case .welcome:
                WelcomeView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        appState = .startMenu
                    }
                })
                .transition(.opacity)
                
            case .startMenu:
                StartMenuView(
                    easyTime: timeEasy,
                    mediumTime: timeMedium,
                    hardTime: timeHard,
                    onStartQuiz: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .levelSelection
                        }
                    },
                    onShowHighscores: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .highscores
                        }
                    },
                    onShowSettings: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .settings
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .leading)
                ))
                
            case .levelSelection:
                LevelSelectionView(
                    selectedLevel: $geselecteerdLevel,
                    onLevelSelected: {
                        startQuizForLevel()
                    },
                    onBackToMenu: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .startMenu
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .quiz:
                QuizView(
                    huidigeVraagIndex: $huidigeVraagIndex,
                    score: $score,
                    totaalPunten: $totaalPunten,
                    toonAntwoord: $toonAntwoord,
                    gekozenAntwoord: $gekozenAntwoord,
                    timerSeconds: $timerSeconds,
                    timerActive: $timerActive,
                    totalTime: timerTotal,
                    vragen: vragenVoorLevel,
                    soundsEnabled: soundsEnabled,
                    hapticsEnabled: hapticsEnabled,
                    warningSoundEnabled: warningSoundEnabled,
                    speechEnabled: speechEnabled,
                    speechOnAnswer: speechOnAnswer,
                    speechRate: Float(speechRate),
                    speechPitch: Float(speechPitch),
                    speechLang: speechLang,
                    speech: speechManager,
                    onQuizComplete: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .results
                        }
                    },
                    onBackToLevels: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .levelSelection
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .results:
                ResultsView(
                    score: score,
                    totaalPunten: totaalPunten,
                    totalQuestions: vragenVoorLevel.count,
                    level: geselecteerdLevel,
                    speech: speechManager,
                    speechEnabled: speechEnabled,
                    speechRate: Float(speechRate),
                    speechPitch: Float(speechPitch),
                    speechLang: speechLang,
                    onPlayAgain: {
                        startQuizForLevel()
                    },
                    onBackToLevels: {
                        resetQuiz()
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .levelSelection
                        }
                    },
                    onBackToMenu: {
                        resetQuiz()
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .startMenu
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .highscores:
                HighscoresView(
                    onBack: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .startMenu
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .settings:
                SettingsView(
                    soundsEnabled: $soundsEnabled,
                    hapticsEnabled: $hapticsEnabled,
                    warningSoundEnabled: $warningSoundEnabled,
                    timeEasy: $timeEasy,
                    timeMedium: $timeMedium,
                    timeHard: $timeHard,
                    speechEnabled: $speechEnabled,
                    speechOnAnswer: $speechOnAnswer,
                    speechRate: $speechRate,
                    speechPitch: $speechPitch,
                    speechLang: $speechLang,
                    onBack: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState = .startMenu
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
    
    private func timeForLevel(_ level: QuizLevel) -> Int {
        switch level {
        case .makkelijk: return timeEasy
        case .gemiddeld: return timeMedium
        case .moeilijk: return timeHard
        }
    }
    
    private func startQuizForLevel() {
        // Filter vragen voor geselecteerd level
        vragenVoorLevel = groningseQuizVragen.filter { $0.level == geselecteerdLevel }
        
        // Reset quiz state + adaptieve tijd
        timerTotal = timeForLevel(geselecteerdLevel)
        huidigeVraagIndex = 0
        score = 0
        totaalPunten = 0
        toonAntwoord = false
        gekozenAntwoord = nil
        timerSeconds = timerTotal
        timerActive = true
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            appState = .quiz
        }
    }
    
    private func resetQuiz() {
        huidigeVraagIndex = 0
        score = 0
        totaalPunten = 0
        toonAntwoord = false
        gekozenAntwoord = nil
        timerActive = false
        vragenVoorLevel = []
        timerTotal = 10
        timerSeconds = 10
    }
}

// MARK: - Groningse Patroon View
struct GroningsePatroonView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Groningse vlag patroon
                ForEach(0..<Int(geometry.size.height / 24), id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<Int(geometry.size.width / 24), id: \.self) { col in
                            Rectangle()
                                .fill(
                                    (row + col) % 2 == 0 ?
                                    GroningseKleuren.blauw.opacity(0.10) :
                                    GroningseKleuren.groen.opacity(0.10)
                                )
                                .frame(width: 24, height: 24)
                        }
                    }
                    .offset(y: CGFloat(row) * 24)
                }
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onComplete: () -> Void
    @State private var flagScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                GroningseVlagView()
                    .frame(width: 150, height: 100)
                    .scaleEffect(flagScale)
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
                
                Text("Welkom bie de Groningse Kwis!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(GroningseKleuren.wit)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .padding(.horizontal)
                    .glassCard()
            }
        }
        .onAppear {
            // Animate the entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                flagScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
                textOpacity = 1.0
            }

            // Transition to the start menu after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Start Menu View
struct StartMenuView: View {
    let easyTime: Int
    let mediumTime: Int
    let hardTime: Int
    let onStartQuiz: () -> Void
    let onShowHighscores: () -> Void
    let onShowSettings: () -> Void
    
    @State private var titleOffset: CGFloat = -200
    @State private var subtitleOffset: CGFloat = 200
    @State private var buttonOffset: CGFloat = 300
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Groningse vlag icon
            VStack(spacing: 15) {
                GroningseVlagView()
                    .frame(width: 120, height: 80)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Title
                VStack(spacing: 20) {
                    Text("Dizze Kwis")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(GroningseKleuren.wit)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text("is Nait Normaal")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(GroningseKleuren.wit)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                    
                    Text("Groningse Taal Kwis")
                        .font(.title2)
                        .foregroundColor(GroningseKleuren.wit.opacity(0.9))
                        .padding(.top, 10)
                }
                .glassCard()
            }
            .offset(y: titleOffset)
            
            Spacer()
            
            // Start Button
            Button(action: {
                #if canImport(UIKit)
                Haptics.selection(enabled: true)
                #endif
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 0.9
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale = 1.0
                    }
                    onStartQuiz()
                }
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start Kwis")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(GroningseKleuren.wit)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [GroningseKleuren.groen, GroningseKleuren.donkerGroen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
            .scaleEffect(buttonScale)
            .offset(y: buttonOffset)
            
            // Extra knoppen
            HStack(spacing: 16) {
                Button(action: onShowHighscores) {
                    Label("Highscores", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.15)))
                }
                Button(action: onShowSettings) {
                    Label("Instellingen", systemImage: "gearshape.fill")
                        .font(.headline)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.15)))
                }
            }
            .offset(y: buttonOffset)
            
            Spacer()
            
            // Info
            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    GroningseInfoCard(icon: "timer", text: "\(easyTime)/\(mediumTime)/\(hardTime) sec", color: GroningseKleuren.blauw)
                    GroningseInfoCard(icon: "star.fill", text: "3 Levels", color: GroningseKleuren.groen)
                }
                
                HStack(spacing: 20) {
                    GroningseInfoCard(icon: "trophy.fill", text: "Punten", color: GroningseKleuren.rood)
                    GroningseInfoCard(icon: "brain.head.profile", text: "Gronings", color: GroningseKleuren.wit)
                }
            }
            .offset(y: buttonOffset)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                titleOffset = 0
            }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.4)) {
                subtitleOffset = 0
            }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.6)) {
                buttonOffset = 0
            }
        }
    }
}

// MARK: - Groningse Vlag View
struct GroningseVlagView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let crossWidth = width / 3.0
            
            ZStack {
                // Quadrants (red and blue)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        GroningseKleuren.rood
                        GroningseKleuren.blauw
                    }
                    HStack(spacing: 0) {
                        GroningseKleuren.blauw
                        GroningseKleuren.rood
                    }
                }
                
                // White cross (behind the green one)
                Rectangle()
                    .fill(GroningseKleuren.wit)
                    .frame(width: width, height: crossWidth)
                Rectangle()
                    .fill(GroningseKleuren.wit)
                    .frame(width: crossWidth, height: height)
                
                // Green cross
                Rectangle()
                    .fill(GroningseKleuren.groen)
                    .frame(width: width, height: crossWidth / 3.0)
                Rectangle()
                    .fill(GroningseKleuren.groen)
                    .frame(width: crossWidth / 3.0, height: height)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GroningseKleuren.wit.opacity(0.5), lineWidth: 2)
            )
        }
    }
}

// MARK: - Level Selection View
struct LevelSelectionView: View {
    @Binding var selectedLevel: QuizLevel
    let onLevelSelected: () -> Void
    let onBackToMenu: () -> Void
    
    @State private var levelOffset: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Button(action: onBackToMenu) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Terug")
                    }
                    .font(.title3)
                    .foregroundColor(GroningseKleuren.wit)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Kies je Level")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(GroningseKleuren.wit)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
            }
            .padding()
            .glassCard()
            
            Spacer()
            
            // Level Cards
            VStack(spacing: 20) {
                ForEach(QuizLevel.allCases, id: \.self) { level in
                    GroningseLevelCard(
                        level: level,
                        isSelected: selectedLevel == level,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedLevel = level
                            }
                        }
                    )
                }
            }
            .offset(y: levelOffset)
            
            Spacer()
            
            // Start Button
            Button(action: onLevelSelected) {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                    Text("Start \(selectedLevel.groningseNaam) Kwis")
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(GroningseKleuren.wit)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [selectedLevel.color, selectedLevel.color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
            .offset(y: levelOffset)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                levelOffset = 0
            }
        }
    }
}

struct GroningseLevelCard: View {
    let level: QuizLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    private var questionCount: Int {
        groningseQuizVragen.filter { $0.level == level }.count
    }
    
    private var maxPoints: Int {
        groningseQuizVragen.filter { $0.level == level }.reduce(0) { $0 + $1.punten }
    }
    
    private var highscore: Highscore? {
        HighscoreManager.load(for: level)
    }
    
    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            Haptics.selection(enabled: true)
            #endif
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                onTap()
            }
        }) {
            HStack(spacing: 20) {
                Image(systemName: level.icon)
                    .font(.system(size: 30))
                    .foregroundColor(level.color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(level.groningseNaam)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(GroningseKleuren.wit)
                    
                    Text("\(questionCount) vragen • Max \(maxPoints) punten")
                        .font(.caption)
                        .foregroundColor(GroningseKleuren.wit.opacity(0.8))
                    
                    if let hs = highscore {
                        Text("Highscore: \(hs.correct) goed • \(hs.points) pt")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(level.color)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(GroningseKleuren.groen)
                }
            }
            .padding()
            .glassCard()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? level.color.opacity(0.15) : Color.clear)
            )
        }
        .scaleEffect(scale)
    }
}

struct GroningseInfoCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(GroningseKleuren.wit)
        }
        .padding()
        .glassCard(cornerRadius: 15)
    }
}

// MARK: - Quiz View
struct QuizView: View {
    @Binding var huidigeVraagIndex: Int
    @Binding var score: Int
    @Binding var totaalPunten: Int
    @Binding var toonAntwoord: Bool
    @Binding var gekozenAntwoord: Int?
    @Binding var timerSeconds: Int
    @Binding var timerActive: Bool
    let totalTime: Int
    let vragen: [QuizVraag]
    let soundsEnabled: Bool
    let hapticsEnabled: Bool
    let warningSoundEnabled: Bool
    // Spraak
    let speechEnabled: Bool
    let speechOnAnswer: Bool
    let speechRate: Float
    let speechPitch: Float
    let speechLang: String
    @ObservedObject var speech: SpeechManager
    let onQuizComplete: () -> Void
    let onBackToLevels: () -> Void
    
    @State private var questionOffset: CGFloat = 300
    @State private var answerOffset: CGFloat = 500
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 15) {
                HStack {
                    Button(action: onBackToLevels) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(GroningseKleuren.wit)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    
                    Spacer()
                    
                    Text("Vraag \(huidigeVraagIndex + 1) van \(vragen.count)")
                        .font(.headline)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 12)
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        Text("\(score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(GroningseKleuren.wit)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(GroningseKleuren.groen))
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                        
                        Text("\(totaalPunten)")
                            .font(.caption)
                            .foregroundColor(GroningseKleuren.wit.opacity(0.8))
                    }
                }
                
                // Timer as circular ring
                CircularTimerView(
                    total: Double(totalTime),
                    remaining: Double(timerSeconds),
                    color: timerSeconds <= 3 ? GroningseKleuren.rood : GroningseKleuren.blauw
                )
                
                ProgressView(value: Double(huidigeVraagIndex + 1), total: Double(vragen.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: GroningseKleuren.groen))
                    .scaleEffect(y: 2)
            }
            .padding()
            
            // Question
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Text(vragen[huidigeVraagIndex].vraag)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(GroningseKleuren.wit)
                        .contentTransition(.interpolate)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: huidigeVraagIndex)
                    
                    Spacer()
                    
                    // Level indicator
                    HStack(spacing: 6) {
                        Image(systemName: vragen[huidigeVraagIndex].level.icon)
                            .foregroundColor(vragen[huidigeVraagIndex].level.color)
                        Text("\(vragen[huidigeVraagIndex].punten)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(vragen[huidigeVraagIndex].level.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(vragen[huidigeVraagIndex].level.color.opacity(0.25))
                            .overlay(
                                Capsule().stroke(vragen[huidigeVraagIndex].level.color, lineWidth: 1)
                            )
                    )
                    
                    // Speak button
                    Button {
                        if speechEnabled {
                            if speech.isSpeaking {
                                speech.stop()
                            } else {
                                speech.speak(vragen[huidigeVraagIndex].vraag,
                                             language: speechLang,
                                             rate: speechRate,
                                             pitch: speechPitch)
                            }
                        }
                    } label: {
                        Image(systemName: (speechEnabled && speech.isSpeaking) ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(GroningseKleuren.wit)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    .disabled(!speechEnabled)
                }
                .padding()
                .glassCard()
                .offset(y: questionOffset)
                
                // Answers
                VStack(spacing: 15) {
                    ForEach(0..<vragen[huidigeVraagIndex].antwoorden.count, id: \.self) { index in
                        GroningseAnswerButton(
                            text: vragen[huidigeVraagIndex].antwoorden[index],
                            index: index,
                            isSelected: gekozenAntwoord == index,
                            isCorrect: toonAntwoord ? (index == vragen[huidigeVraagIndex].juisteAntwoord) : nil,
                            isWrong: toonAntwoord ? (gekozenAntwoord == index && index != vragen[huidigeVraagIndex].juisteAntwoord) : nil,
                            onTap: {
                                selectAnswer(index)
                            }
                        )
                        .offset(y: answerOffset)
                    }
                }
            }
            .padding()
            
            // Explanation
            if toonAntwoord {
                VStack {
                    Text(vragen[huidigeVraagIndex].uitleg)
                        .font(.body)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding()
                        .glassCard(cornerRadius: 15)
                        .padding(.horizontal)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .onAppear {
            startTimer()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                questionOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                answerOffset = 0
            }
            if speechEnabled {
                // Lees de vraag voor
                speech.speak(vragen[huidigeVraagIndex].vraag, language: speechLang, rate: speechRate, pitch: speechPitch)
            }
        }
        .onDisappear {
            stopTimer()
            speech.stop()
        }
        .onChange(of: timerSeconds) { oldValue, newValue in
            #if canImport(UIKit)
            if newValue > 0 && newValue <= 3 {
                Sounds.warning(enabled: warningSoundEnabled)
            }
            #endif
        }
    }
    
    private func startTimer() {
        timerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerActive && timerSeconds > 0 {
                timerSeconds -= 1
                
                if timerSeconds == 0 {
                    // Time's up!
                    if gekozenAntwoord == nil {
                        selectAnswer(-1) // No answer selected
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerActive = false
    }
    
    private func selectAnswer(_ index: Int) {
        guard gekozenAntwoord == nil else { return }
        
        stopTimer()
        gekozenAntwoord = index
        toonAntwoord = true
        
        let isCorrect = (index == vragen[huidigeVraagIndex].juisteAntwoord)
        if isCorrect {
            score += 1
            // Bonus points for quick answers
            let timeBonus = max(0, timerSeconds * 2)
            totaalPunten += vragen[huidigeVraagIndex].punten + timeBonus
            #if canImport(UIKit)
            Haptics.success(enabled: hapticsEnabled)
            Sounds.correct(enabled: soundsEnabled)
            #endif
        } else {
            #if canImport(UIKit)
            Haptics.error(enabled: hapticsEnabled)
            Sounds.wrong(enabled: soundsEnabled)
            #endif
        }
        
        // Spraak bij antwoord en uitleg
        if speechEnabled && speechOnAnswer {
            let feedback = isCorrect ? "Goed!" : "Nait goed."
            let uitleg = vragen[huidigeVraagIndex].uitleg
            speech.speak("\(feedback) \(uitleg)", language: speechLang, rate: speechRate, pitch: speechPitch)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        if huidigeVraagIndex < vragen.count - 1 {
            huidigeVraagIndex += 1
            toonAntwoord = false
            gekozenAntwoord = nil
            timerSeconds = totalTime
            
            // Reset animations for next question
            questionOffset = 300
            answerOffset = 500
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                questionOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                answerOffset = 0
            }
            
            startTimer()
            
            if speechEnabled {
                speech.speak(vragen[huidigeVraagIndex].vraag, language: speechLang, rate: speechRate, pitch: speechPitch)
            }
        } else {
            onQuizComplete()
        }
    }
}

struct GroningseAnswerButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let isWrong: Bool?
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var wrongShakes: CGFloat = 0
    @State private var correctPulse: Bool = false
    
    private var backgroundColor: Color {
        if let isCorrect = isCorrect, isCorrect {
            return GroningseKleuren.groen
        } else if let isWrong = isWrong, isWrong {
            return GroningseKleuren.rood
        } else if isSelected {
            return GroningseKleuren.blauw
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            Haptics.selection(enabled: true)
            #endif
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                Text("\(index + 1).")
                    .fontWeight(.bold)
                    .foregroundColor(GroningseKleuren.wit)
                    .frame(width: 30)
                
                Text(text)
                    .foregroundColor(GroningseKleuren.wit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                
                if let isCorrect = isCorrect, isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GroningseKleuren.wit)
                } else if let isWrong = isWrong, isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(GroningseKleuren.wit)
                }
            }
            .padding()
            .glassCard(cornerRadius: 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        (isCorrect == true ? GroningseKleuren.groen :
                            (isWrong == true ? GroningseKleuren.rood :
                                (isSelected ? GroningseKleuren.blauw : GroningseKleuren.wit.opacity(0.3))
                            )
                        ),
                        lineWidth: isSelected || isCorrect == true || isWrong == true ? 2 : 1
                    )
            )
        }
        .scaleEffect(correctPulse ? 1.05 : scale)
        .modifier(ShakeEffect(animatableData: wrongShakes))
        .onChange(of: isWrong ?? false) { _, newValue in
            if newValue {
                withAnimation(.default) {
                    wrongShakes += 1
                }
            }
        }
        .onChange(of: isCorrect ?? false) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    correctPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        correctPulse = false
                    }
                }
            }
        }
        .disabled(isSelected || isCorrect != nil || isWrong != nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
        .accessibilityHint(Text("Antwoord \(index + 1)"))
    }
}

// MARK: - Results View
struct ResultsView: View {
    let score: Int
    let totaalPunten: Int
    let totalQuestions: Int
    let level: QuizLevel
    let speech: SpeechManager
    let speechEnabled: Bool
    let speechRate: Float
    let speechPitch: Float
    let speechLang: String
    let onPlayAgain: () -> Void
    let onBackToLevels: () -> Void
    let onBackToMenu: () -> Void
    
    @State private var resultOffset: CGFloat = 300
    @State private var buttonOffset: CGFloat = 500
    @State private var isNewHighscore: Bool = false
    
    private var percentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(score) / Double(totalQuestions)) * 100)
    }
    
    private var resultMessage: (text: String, color: Color) {
        if score == totalQuestions {
            return ("Perfect! Je bent een echte Groninger! 🏆", GroningseKleuren.groen)
        } else if score >= totalQuestions * 3 / 4 {
            return ("Goed gedaan! Je kent je Gronings! 👍", GroningseKleuren.groen)
        } else if score >= totalQuestions / 2 {
            return ("Niet slecht! Nog wat oefenen! 📚", GroningseKleuren.blauw)
        } else {
            return ("Oefen nog wat meer Gronings! 💪", GroningseKleuren.rood)
        }
    }
    
    private var previousHighscore: Highscore? {
        HighscoreManager.load(for: level)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Result
                VStack(spacing: 30) {
                    Image(systemName: score == totalQuestions ? "trophy.fill" : "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(GroningseKleuren.groen)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Quiz Voltooid!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(GroningseKleuren.wit)
                    
                    if isNewHighscore {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Nieuwe Highscore!")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color.yellow.opacity(0.2))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    VStack(spacing: 15) {
                        Text("\(score) van \(totalQuestions)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(GroningseKleuren.wit)
                        
                        Text("\(percentage)%")
                            .font(.title)
                            .foregroundColor(GroningseKleuren.wit.opacity(0.8))
                        
                        Text("\(totaalPunten) punten")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(level.color)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(level.color.opacity(0.3))
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(level.color, lineWidth: 1)
                                    )
                            )
                        
                        if let prev = previousHighscore, !isNewHighscore {
                            Text("Highscore: \(prev.correct) goed • \(prev.points) pt")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(GroningseKleuren.wit.opacity(0.9))
                                .padding(.top, 6)
                        }
                    }
                    
                    Text(resultMessage.text)
                        .font(.title2)
                        .foregroundColor(resultMessage.color)
                        .multilineTextAlignment(.center)
                        .padding()
                        .glassCard(cornerRadius: 15)
                }
                .offset(y: resultOffset)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 20) {
                    Button(action: onPlayAgain) {
                        HStack(spacing: 15) {
                            Image(systemName: "arrow.clockwise")
                            Text("Opnieuw Spelen")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [level.color, level.color.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    Button(action: onBackToLevels) {
                        HStack(spacing: 15) {
                            Image(systemName: "list.bullet")
                            Text("Ander Level")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [GroningseKleuren.groen, GroningseKleuren.donkerGroen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    Button(action: onBackToMenu) {
                        HStack(spacing: 15) {
                            Image(systemName: "house.fill")
                            Text("Terug naar Menu")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(GroningseKleuren.wit)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [GroningseKleuren.blauw, GroningseKleuren.blauw.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                }
                .offset(y: buttonOffset)
            }
            .padding()
            .onAppear {
                // Highscore bijwerken
                let newRecord = HighscoreManager.updateIfBetter(level: level, correct: score, points: totaalPunten)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                    isNewHighscore = newRecord
                }
                
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                    resultOffset = 0
                }
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.4)) {
                    buttonOffset = 0
                }
                
                if speechEnabled {
                    let tekst = "Klaar! Je hebt \(score) van \(totalQuestions) goed, en \(totaalPunten) punten."
                    speech.speak(tekst, language: speechLang, rate: speechRate, pitch: speechPitch)
                }
            }
        }
    }
}

// MARK: - Highscores View
struct HighscoresView: View {
    let onBack: () -> Void
    
    private func text(for level: QuizLevel) -> String {
        if let hs = HighscoreManager.load(for: level) {
            return "\(hs.correct) goed • \(hs.points) pt"
        } else {
            return "Nog geen score"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Terug")
                    }
                    .foregroundColor(.white)
                }
                Spacer()
                Text("Highscores")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Spacer().frame(width: 60)
            }
            .padding()
            .glassCard()
            
            VStack(spacing: 16) {
                ForEach(QuizLevel.allCases, id: \.self) { level in
                    HStack {
                        Label(level.groningseNaam, systemImage: level.icon)
                            .foregroundColor(.white)
                        Spacer()
                        Text(text(for: level))
                            .foregroundColor(level.color)
                    }
                    .padding()
                    .glassCard()
                    .contextMenu {
                        Button(role: .destructive) {
                            HighscoreManager.reset(for: level)
                        } label: {
                            Label("Reset \(level.groningseNaam)", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Button(role: .destructive) {
                HighscoreManager.resetAll()
            } label: {
                Label("Reset alle highscores", systemImage: "trash.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.6)))
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var soundsEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var warningSoundEnabled: Bool
    @Binding var timeEasy: Int
    @Binding var timeMedium: Int
    @Binding var timeHard: Int
    
    // Spraak
    @Binding var speechEnabled: Bool
    @Binding var speechOnAnswer: Bool
    @Binding var speechRate: Double
    @Binding var speechPitch: Double
    @Binding var speechLang: String
    
    let onBack: () -> Void
    
    private let languageOptions: [(code: String, name: String)] = [
        ("nl-NL", "Nederlands (NL)"),
        ("nl-BE", "Nederlands (BE)")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Terug")
                    }
                    .foregroundColor(.white)
                }
                Spacer()
                Text("Instellingen")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Spacer().frame(width: 60)
            }
            .padding()
            .glassCard()
            
            // Geluid en haptics
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $soundsEnabled) {
                    Label("Geluidseffecten", systemImage: "speaker.wave.2.fill")
                        .foregroundColor(.white)
                }
                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptics", systemImage: "iphone.radiowaves.left.and-right")
                        .foregroundColor(.white)
                }
                Toggle(isOn: $warningSoundEnabled) {
                    Label("Waarschuwingsgeluid (laatste 3 sec)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            // Tijden per level
            VStack(alignment: .leading, spacing: 16) {
                Text("Tijd per level (sec)")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    Label("Makkelijk", systemImage: QuizLevel.makkelijk.icon)
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("\(timeEasy)s", value: $timeEasy, in: 5...30)
                        .labelsHidden()
                }
                HStack {
                    Label("Gemiddeld", systemImage: QuizLevel.gemiddeld.icon)
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("\(timeMedium)s", value: $timeMedium, in: 5...30)
                        .labelsHidden()
                }
                HStack {
                    Label("Moeilijk", systemImage: QuizLevel.moeilijk.icon)
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("\(timeHard)s", value: $timeHard, in: 5...30)
                        .labelsHidden()
                }
                
                Text("Tip: kortere tijd = hogere spanning!")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            // Spraak (TTS)
            VStack(alignment: .leading, spacing: 16) {
                Text("Spraak (TTS)")
                    .font(.headline)
                    .foregroundColor(.white)
                Toggle(isOn: $speechEnabled) {
                    Label("Spreek vragen/teksten uit", systemImage: "speaker.wave.2.circle.fill")
                        .foregroundColor(.white)
                }
                Toggle(isOn: $speechOnAnswer) {
                    Label("Spreek feedback + uitleg bij antwoord", systemImage: "quote.bubble.fill")
                        .foregroundColor(.white)
                }
                HStack {
                    Text("Tempo")
                        .foregroundColor(.white)
                    Slider(value: $speechRate, in: 0.2...0.6)
                }
                HStack {
                    Text("Toonhoogte")
                        .foregroundColor(.white)
                    Slider(value: $speechPitch, in: 0.8...1.2)
                }
                HStack {
                    Text("Taal")
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Taal", selection: $speechLang) {
                        ForEach(languageOptions, id: \.code) { item in
                            Text(item.name).tag(item.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
                Text("Opmerking: er is geen aparte Groningse stem beschikbaar. We gebruiken Nederlands voor de uitspraak.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

#Preview {
    ContentView()
}
