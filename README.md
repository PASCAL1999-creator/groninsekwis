# Dizze Kwis is Nait Normaal

Een snelle en vrolijke Groningse taal-quiz gebouwd met SwiftUI. Kies je level, race tegen de klok, verdien punten (met tijdsbonus), en verbeter je highscore. Inclusief haptics, systeemgeluidjes en tekst-naar-spraak.

## Inhoud

- Drie levels: Makkelijk, Gemiddeld, Moeilijk
- Timer per vraag met visuele cirkel en waarschuwing in de laatste 3 seconden
- Punten per vraag + tijdsbonus
- Highscores per level (UserDefaults)
- Instellingen voor geluid, haptics, timer per level en spraak (TTS)
- Optionele TTS voor vragen en feedback/uitleg
- Animaties, glazen UI-kaarten en (iOS) confetti-effect
- Geen externe dependencies

## Screens

- Welkomscherm
- Startmenu (Start, Highscores, Instellingen)
- Levelselectie
- Quiz (vraag + antwoorden, timer, score, progressie)
- Resultaten (percentage, totaalpunten, highscore)
- Highscores-overzicht
- Instellingen (geluid, haptics, timers, TTS)

## Techniek

- SwiftUI voor UI en eenvoudige appstate-routering
- AVFoundation (AVSpeechSynthesizer) voor TTS
- UIKit (optioneel, via canImport) voor haptics en systeemgeluiden
- UserDefaults voor het opslaan van highscores
- Swift Testing (unit tests) en XCUITest-sjablonen aanwezig

## Vereisten

- Xcode 16 of hoger
- iOS 16.0 of hoger (iPadOS 16.0+ werkt ook)
- Swift 5.9+

## Bouwen en draaien

1. Open het project in Xcode: Dizze_Kwis_is_Nait_Normaal.xcodeproj
2. Selecteer een iOS-simulator of een aangesloten apparaat
3. Product -> Run (Cmd+R)

Er zijn geen extra frameworks of package dependencies nodig.

## Privacy & Permissies

- Tekst-naar-spraak (AVSpeechSynthesizer) gebruikt geen microfoon of opname en vereist geen runtime-permissies.
- Highscores worden lokaal opgeslagen met UserDefaults.
- Er worden geen gebruikersgegevens verzonden of verzameld.

## Instellingen

- Geluidseffecten: aan/uit
- Haptics: aan/uit
- Waarschuwingsgeluid (laatste 3 sec): aan/uit
- Tijd per level (makkelijk/gemiddeld/moeilijk): aanpasbaar
- Spraak:
  - Vraag/feedback uitspreken: aan/uit
  - Spreektempo (0.2–0.6)
  - Toonhoogte (0.8–1.2)
  - Taal (NL varianten)
  - Opmerking: er is geen aparte Groningse stem; Nederlands wordt gebruikt

## Architectuur in het kort

- ContentView.swift bevat:
  - AppState-routering tussen schermen (welcome, menu, levels, quiz, resultaten, highscores, instellingen)
  - Quizmodel (QuizVraag) en niveau-indeling (QuizLevel)
  - HighscoreManager (UserDefaults)
  - SpeechManager (AVSpeechSynthesizer + delegate)
  - UI-componenten: glazen kaarten, timer-ring, shake-effect, confetti (iOS)
- Dizze_Kwis_is_Nait_NormaalApp.swift start ContentView

## Tests

- Unit tests: Dizze_Kwis_is_Nait_NormaalTests (Swift Testing framework)
- UI tests: Dizze_Kwis_is_Nait_NormaalUITests en LaunchTests (XCUITest)

Run tests via Product -> Test (Cmd+U).

## Roadmap (suggesties)

- Meer vragen en categorieën
- Lokalisatie van UI-teksten
- iCloud-synchronisatie van highscores
- Toegankelijkheidslabels uitbreiden (VoiceOver hints)
- Game Center leaderboards (optioneel)

## Licentie

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
