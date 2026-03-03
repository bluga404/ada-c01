import SwiftUI
import UserNotifications
import AVFoundation

struct ContentView: View {
    
    enum WaterType: String, CaseIterable {
        case airBiasa = "Air Biasa"
        case airMendidih = "Air Mendidih"
    }
    
    enum EggDoneness: String, CaseIterable {
        case soft = "Setengah Matang"
        case medium = "Matang"
        case hard = "Matang Sempurna"
        
        var icon: String {
            switch self {
            case .soft: return "🥚"
            case .medium: return "🍳"
            case .hard: return "🟡"
            }
        }
    }
    
    @State private var selectedWater: WaterType = .airBiasa
    @State private var selectedDoneness: EggDoneness = .soft
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var boilingTime: Int {
        switch selectedWater {
        case .airBiasa:
            switch selectedDoneness {
            case .soft: return 9 * 60
            case .medium: return 11 * 60
            case .hard: return 14 * 60
            }
        case .airMendidih:
            switch selectedDoneness {
            case .soft: return 6 * 60
            case .medium: return 9 * 60
            case .hard: return 12 * 60
            }
        }
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                Text("Set Boiled Details")
                    .font(.title2)
                    .bold()
                
                // MARK: - Water Type
                VStack(alignment: .leading, spacing: 10) {
                    Text("Egg Temperature")
                        .font(.headline)
                    
                    Picker("", selection: $selectedWater) {
                        ForEach(WaterType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Doneness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Egg Boiled Type")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        ForEach(EggDoneness.allCases, id: \.self) { level in
                            VStack(spacing: 8) {
                                Text(level.icon)
                                    .font(.largeTitle)
                                
                                Text(level.rawValue)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedDoneness == level ?
                                Color.orange.opacity(0.3) :
                                Color.white
                            )
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.05), radius: 5)
                            .onTapGesture {
                                selectedDoneness = level
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Timer Display
                VStack(spacing: 8) {
                    Text("Estimated Boiled Time")
                        .font(.headline)
                    
                    Text(isRunning ? formattedTime :
                         "\(boilingTime / 60) MIN")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                // MARK: - Start Button
                Button(action: startTimer) {
                    Text(isRunning ? "Running..." : "Start")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunning ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .disabled(isRunning)
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(25)
            .padding()
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func startTimer() {
        timeRemaining = boilingTime
        isRunning = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                isRunning = false
                scheduleNotification()
                playAlarmSound()
            }
        }
    }
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Selesai ⏰"
        content.body = "Telur kamu sudah matang!"
        content.sound = .default   // pakai sound bawaan iOS
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func playAlarmSound() {
        AudioServicesPlaySystemSound(1005)
        // 1005 = sound bawaan iOS (mirip alarm/alert)
    }
}

#Preview {
    ContentView()
}
