import SwiftUI
import UserNotifications
import AVFoundation

struct ContentView: View {
    
    // MARK: - ENUMS
    
    enum WaterType: String, CaseIterable {
        case airBiasa
        case airMendidih
    }
    
    enum EggType: String, CaseIterable {
        case ayam = "Telur Ayam"
        case puyuh = "Telur Puyuh"
    }
    
    enum EggDoneness: String, CaseIterable {
        case soft
        case medium
        case hard
        
        var imageName: String {
            switch self {
            case .soft: return "Setengah Matang"
            case .medium: return "Matang"
            case .hard: return "Matang Sempurna"
            }
        }
    }
    
    // MARK: - STATES
    
    @State private var selectedWater: WaterType = .airBiasa
    @State private var selectedDoneness: EggDoneness = .soft
    @State private var selectedEggType: EggType = .ayam
    
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAlarmActive = false
    @State private var expiryDate: Date?
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - BOILING TIME
    
    var boilingTime: Int {
        var baseTime: Int
        
        switch selectedWater {
        case .airBiasa:
            switch selectedDoneness {
            case .soft: baseTime = 8 * 1
            case .medium: baseTime = 11 * 60
            case .hard: baseTime = 14 * 60
            }
        case .airMendidih:
            switch selectedDoneness {
            case .soft: baseTime = 6 * 60
            case .medium: baseTime = 9 * 60
            case .hard: baseTime = 12 * 60
            }
        }
        
        if selectedEggType == .puyuh {
            baseTime /= 2
        }
        
        return baseTime
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - BODY
    
    var body: some View {
        ZStack {
            if isRunning {
                timerView
            } else {
                setupView
            }
        }
        .onAppear {
            requestNotificationPermission()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                syncWithRealTime()
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - SETUP VIEW
////////////////////////////////////////////////////////////

extension ContentView {
    
    var setupView: some View {
        ZStack(alignment: .topTrailing) {
            
            Color.yellow
                .ignoresSafeArea()
                .frame(height: 220)
            
            VStack(spacing: 25) {
                
                Spacer().frame(height: 80)
                
                VStack(alignment: .leading, spacing: 25) {
                    
                    VStack(alignment: .leading) {
                        Text("BoiliT!")
                            .font(.title)
                            .bold()
                        
                        Text("Prepare eggs as you like!")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Egg Type")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            eggTypeButton(.ayam)
                            eggTypeButton(.puyuh)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Water condition")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            waterButton(.airBiasa, title: "Air Mentah")
                            waterButton(.airMendidih, title: "Air Mendidih")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Egg boiled type")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            eggCard(.soft, title: "Soft")
                            eggCard(.medium, title: "Medium")
                            eggCard(.hard, title: "Hard")
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                Spacer()
                
                bottomBar
            }
            
            Image("Telur")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 40)
                .padding(.trailing, -20)
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - TIMER VIEW
////////////////////////////////////////////////////////////

extension ContentView {
    
    var timerView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 220, height: 220)
                    .shadow(color: isAlarmActive ? .red.opacity(0.5) : .black.opacity(0.1), radius: 15)
                
                VStack {
                    Text(formattedTime)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(isAlarmActive ? .red : .primary)
                    
                    if isAlarmActive {
                        Text("WAKTU HABIS!")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.red)
                    }
                }
            }
            
            Text(isAlarmActive ? "Angkat telur sekarang!" : "Egg still cooking")
                .foregroundColor(.gray)
            
            Spacer()
            
            if isAlarmActive {
                Button(action: stopAlarm) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("STOP ALARM")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 70)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
                }
            } else {
                Button {
                    timer?.invalidate()
                    isRunning = false
                } label: {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                }
            }
            
            Spacer()
        }
        .background(isAlarmActive ? Color.red.opacity(0.05) : Color.gray.opacity(0.05))
        .ignoresSafeArea()
    }
}

////////////////////////////////////////////////////////////
// MARK: - COMPONENTS
////////////////////////////////////////////////////////////

extension ContentView {
    
    func eggTypeButton(_ type: EggType) -> some View {
        Button {
            selectedEggType = type
        } label: {
            Text(type.rawValue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedEggType == type ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(selectedEggType == type ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(15)
        }
    }
    
    func waterButton(_ type: WaterType, title: String) -> some View {
        Button {
            selectedWater = type
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedWater == type ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(selectedWater == type ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(15)
        }
    }
    
    func eggCard(_ level: EggDoneness, title: String) -> some View {
        Button {
            selectedDoneness = level
        } label: {
            VStack(spacing: 10) {
                Image(level.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                Text(title).bold()
                
                Text("boiled")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selectedDoneness == level ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(20)
        }
    }
    
    var bottomBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Estimated boiled time")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(boilingTime / 60):00 Min")
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
            
            Button(action: startTimer) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 4)
            }
        }
        .padding()
        .background(Color.white)
    }
}

////////////////////////////////////////////////////////////
// MARK: - TIMER ENGINE + AUDIO
////////////////////////////////////////////////////////////

extension ContentView {
    
    func startTimer() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        isAlarmActive = false
        timeRemaining = boilingTime
        isRunning = true
        
        expiryDate = Date().addingTimeInterval(TimeInterval(boilingTime))
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timeRemaining = 0
                    timerFinished()
                }
            }
        }
        
        scheduleNotification(in: TimeInterval(boilingTime))
    }
    
    func syncWithRealTime() {
        guard let expiry = expiryDate,
              isRunning,
              !isAlarmActive else { return }
        
        let remaining = Int(expiry.timeIntervalSinceNow)
        
        if remaining <= 0 {
            timeRemaining = 0
            timerFinished()
        } else {
            timeRemaining = remaining
        }
    }
    
    func timerFinished() {
        timer?.invalidate()
        timer = nil
        isAlarmActive = true
        playAlarmSound()
    }
    
    func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmActive = false
        isRunning = false
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func scheduleNotification(in time: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Selesai ⏰"
        content.body = "Telur kamu sudah matang!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, time),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "BoiliT_Timer",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func playAlarmSound() {
        guard let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
