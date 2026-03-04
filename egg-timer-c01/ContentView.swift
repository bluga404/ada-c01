import SwiftUI
import UserNotifications
import AVFoundation

struct ContentView: View {
    
    // MARK: - ENVIRONMENT
    @Environment(\.scenePhase) var scenePhase
    
    // MARK: - ENUMS
    
    enum WaterType: String, CaseIterable {
        case airBiasa
        case airMendidih
    }
    
    enum EggDoneness: String, CaseIterable {
        case soft
        case medium
        case hard
    }
    
    // MARK: - STATES
    
    @State private var selectedWater: WaterType = .airBiasa
    @State private var selectedDoneness: EggDoneness = .soft
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var showAlert = false
    @State private var endDate: Date?
    
    // MARK: - BOILING TIME
    
    var boilingTime: Int {
        switch selectedWater {
        case .airBiasa:
            switch selectedDoneness {
            case .soft: return 1 * 20
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
    
    // MARK: - BODY
    
    var body: some View {
        ZStack {
            if isRunning {
                timerView
            } else {
                setupView
            }
        }
        .alert("Timer Selesai ⏰", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Telur kamu sudah matang!")
        }
        .onAppear {
            requestNotificationPermission()
        }
        .onChange(of: scenePhase) { newPhase in
            
            if newPhase == .background && isRunning {
                scheduleNotification()
            }
            
            if newPhase == .active && isRunning {
                updateRemainingTime()
            }
        }
    }
}

// MARK: - SETUP VIEW

extension ContentView {
    
    var setupView: some View {
        ZStack(alignment: .top) {
            
            Color.yellow
                .ignoresSafeArea()
                .frame(height: 220)
            
            VStack(alignment: .leading) {
                Spacer().frame(height: 60)
                
                Text("Set boiled details")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Text("Prepare eggs as you like!")
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 25) {
                
                Spacer().frame(height: 180)
                
                VStack(alignment: .leading, spacing: 25) {
                    
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
        }
    }
}

// MARK: - TIMER VIEW

extension ContentView {
    
    var timerView: some View {
        VStack(spacing: 40) {
            
            Spacer()
            
            Circle()
                .fill(Color.white)
                .frame(width: 200, height: 200)
                .shadow(radius: 10)
            
            Text(formattedTime)
                .font(.system(size: 60, weight: .bold))
            
            Text("Egg still cooking")
                .foregroundColor(.gray)
            
            Spacer()
            
            Button {
                stopTimer()
            } label: {
                Image(systemName: "pause.fill")
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
            }
            
            Spacer()
        }
        .background(Color.gray.opacity(0.05))
        .ignoresSafeArea()
    }
}

// MARK: - COMPONENTS

extension ContentView {
    
    func waterButton(_ type: WaterType, title: String) -> some View {
        Button {
            selectedWater = type
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selectedWater == type ?
                    Color.orange.opacity(0.2) :
                    Color.gray.opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            selectedWater == type ? Color.orange : Color.gray.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                .cornerRadius(15)
        }
    }
    
    func eggCard(_ level: EggDoneness, title: String) -> some View {
        Button {
            selectedDoneness = level
        } label: {
            VStack(spacing: 10) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 4)
                
                Text(title)
                    .bold()
                
                Text("boiled")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selectedDoneness == level ? Color.orange : Color.gray.opacity(0.3),
                        lineWidth: 2
                    )
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
                        .foregroundColor(.black)
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

// MARK: - TIMER LOGIC

extension ContentView {
    
    func startTimer() {
        endDate = Date().addingTimeInterval(TimeInterval(boilingTime))
        timeRemaining = boilingTime
        isRunning = true
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemainingTime()
        }
    }
    
    func updateRemainingTime() {
        guard let endDate = endDate else { return }
        
        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            timer?.invalidate()
            timerFinished()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        isRunning = false
        endDate = nil
        
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
    
    func timerFinished() {
        isRunning = false
        endDate = nil
        
        if scenePhase == .active {
            showAlert = true
            playAlarmSound()
        }
    }
}

// MARK: - NOTIFICATION

extension ContentView {
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func scheduleNotification() {
        guard let endDate = endDate else { return }
        
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Selesai ⏰"
        content.body = "Telur kamu sudah matang!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: remaining,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "EggTimerNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func playAlarmSound() {
        AudioServicesPlaySystemSound(1005)
    }
}
