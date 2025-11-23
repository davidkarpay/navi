# watchOS Development Lead - Action Plan
**Agent**: watchOS Development Lead
**Domain**: Apple Watch App (SwiftUI + Complications)
**Current Status**: 15% Production Ready

---

## Mission Statement
Build the Apple Watch application from the ground up, creating an intuitive tap interface, implementing haptic feedback patterns, adding watch complications, and integrating with the iPhone companion app.

---

## Phase 1: Foundation (Week 1-2)

### Week 1: Core UI Implementation

#### Task 1.1: Create App Entry Point and Main Structure
**Priority**: 🔴 Critical
**Estimated Time**: 6 hours
**Dependencies**: None

**Subtasks**:
1. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/NaviWatchApp.swift`:
   ```swift
   import SwiftUI

   @main
   struct NaviWatchApp: App {
       @StateObject private var connectivityManager = WatchConnectivityManager.shared
       @StateObject private var hapticManager = HapticManager.shared

       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environmentObject(connectivityManager)
                   .environmentObject(hapticManager)
           }
       }
   }
   ```

2. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Views/ContentView.swift`:
   ```swift
   import SwiftUI

   struct ContentView: View {
       @EnvironmentObject var connectivityManager: WatchConnectivityManager
       @State private var showingSettings = false

       var body: some View {
           NavigationStack {
               Group {
                   if connectivityManager.isAuthenticated {
                       if connectivityManager.isPaired {
                           TapView()
                       } else {
                           PairingStatusView()
                       }
                   } else {
                       AuthenticationView()
                   }
               }
               .toolbar {
                   ToolbarItem(placement: .topBarTrailing) {
                       Button {
                           showingSettings = true
                       } label: {
                           Image(systemName: "gear")
                       }
                   }
               }
               .sheet(isPresented: $showingSettings) {
                   SettingsView()
               }
           }
       }
   }
   ```

**Success Criteria**:
- ✅ App launches without crashing
- ✅ Navigation structure in place
- ✅ Environment objects accessible throughout app

---

#### Task 1.2: Build Main Tap Interface
**Priority**: 🔴 Critical
**Estimated Time**: 8 hours
**Dependencies**: Task 1.1

**Subtasks**:
1. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Views/TapView.swift`:
   ```swift
   import SwiftUI

   struct TapView: View {
       @EnvironmentObject var connectivityManager: WatchConnectivityManager
       @EnvironmentObject var hapticManager: HapticManager

       @State private var selectedIntensity: String = "medium"
       @State private var selectedPattern: String = "single"
       @State private var isSending = false
       @State private var lastSentTime: Date?

       let intensities = ["light", "medium", "strong"]
       let patterns = ["single", "double", "triple", "heartbeat"]

       var body: some View {
           ScrollView {
               VStack(spacing: 16) {
                   // Partner status
                   if let partnerId = connectivityManager.partnerId {
                       Text("Paired")
                           .font(.caption)
                           .foregroundColor(.green)
                   }

                   // Main tap button
                   Button {
                       sendTap()
                   } label: {
                       VStack {
                           Image(systemName: "hand.tap.fill")
                               .font(.system(size: 44))
                           Text("Send Tap")
                               .font(.headline)
                       }
                       .frame(maxWidth: .infinity)
                       .padding()
                       .background(Color.blue)
                       .foregroundColor(.white)
                       .cornerRadius(12)
                   }
                   .disabled(isSending || !connectivityManager.isPaired)
                   .accessibilityLabel("Send tap to paired partner")

                   // Intensity selector
                   VStack(alignment: .leading, spacing: 8) {
                       Text("Intensity")
                           .font(.caption)
                           .foregroundColor(.secondary)

                       Picker("Intensity", selection: $selectedIntensity) {
                           ForEach(intensities, id: \.self) { intensity in
                               Text(intensity.capitalized).tag(intensity)
                           }
                       }
                       .pickerStyle(.segmented)
                   }

                   // Pattern selector
                   VStack(alignment: .leading, spacing: 8) {
                       Text("Pattern")
                           .font(.caption)
                           .foregroundColor(.secondary)

                       Picker("Pattern", selection: $selectedPattern) {
                           ForEach(patterns, id: \.self) { pattern in
                               Text(pattern.capitalized).tag(pattern)
                           }
                       }
                       .pickerStyle(.wheel)
                       .frame(height: 80)
                   }

                   // Last sent time
                   if let lastSent = lastSentTime {
                       Text("Last sent: \(formatRelativeTime(lastSent))")
                           .font(.caption2)
                           .foregroundColor(.secondary)
                   }
               }
               .padding()
           }
           .navigationTitle("Tap")
           .navigationBarTitleDisplayMode(.inline)
       }

       private func sendTap() {
           isSending = true
           hapticManager.playTapSentHaptic()

           Task {
               await connectivityManager.sendTap(
                   intensity: selectedIntensity,
                   pattern: selectedPattern
               )

               await MainActor.run {
                   lastSentTime = Date()
                   isSending = false
               }
           }
       }

       private func formatRelativeTime(_ date: Date) -> String {
           let formatter = RelativeDateTimeFormatter()
           formatter.unitsStyle = .short
           return formatter.localizedString(for: date, relativeTo: Date())
       }
   }
   ```

2. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Views/AuthenticationView.swift`:
   ```swift
   import SwiftUI

   struct AuthenticationView: View {
       @EnvironmentObject var connectivityManager: WatchConnectivityManager
       @State private var isWaiting = true

       var body: some View {
           VStack(spacing: 16) {
               Image(systemName: "applewatch.watchface")
                   .font(.system(size: 50))
                   .foregroundColor(.blue)

               Text("Waiting for iPhone")
                   .font(.headline)

               Text("Please log in on your iPhone to continue")
                   .font(.caption)
                   .foregroundColor(.secondary)
                   .multilineTextAlignment(.center)

               if isWaiting {
                   ProgressView()
                       .padding(.top)
               }
           }
           .padding()
       }
   }
   ```

3. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Views/PairingStatusView.swift`:
   ```swift
   import SwiftUI

   struct PairingStatusView: View {
       @EnvironmentObject var connectivityManager: WatchConnectivityManager

       var body: some View {
           VStack(spacing: 16) {
               Image(systemName: "person.2")
                   .font(.system(size: 50))
                   .foregroundColor(.orange)

               Text("Not Paired")
                   .font(.headline)

               Text("Use your iPhone to pair with someone")
                   .font(.caption)
                   .foregroundColor(.secondary)
                   .multilineTextAlignment(.center)
           }
           .padding()
       }
   }
   ```

4. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Views/SettingsView.swift`:
   ```swift
   import SwiftUI

   struct SettingsView: View {
       @EnvironmentObject var connectivityManager: WatchConnectivityManager
       @Environment(\.dismiss) var dismiss

       var body: some View {
           NavigationStack {
               List {
                   Section("Status") {
                       HStack {
                           Text("iPhone Connected")
                           Spacer()
                           Image(systemName: connectivityManager.isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                               .foregroundColor(connectivityManager.isReachable ? .green : .red)
                       }

                       HStack {
                           Text("Paired")
                           Spacer()
                           Image(systemName: connectivityManager.isPaired ? "checkmark.circle.fill" : "xmark.circle.fill")
                               .foregroundColor(connectivityManager.isPaired ? .green : .red)
                       }
                   }

                   Section("About") {
                       HStack {
                           Text("Version")
                           Spacer()
                           Text("1.0.0")
                               .foregroundColor(.secondary)
                       }
                   }
               }
               .navigationTitle("Settings")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .confirmationAction) {
                       Button("Done") {
                           dismiss()
                       }
                   }
               }
           }
       }
   }
   ```

**Success Criteria**:
- ✅ Complete UI for all states (auth, unpaired, paired)
- ✅ Tap button functional
- ✅ Intensity and pattern selectors working
- ✅ Settings view accessible
- ✅ Navigation smooth and intuitive

---

### Week 2: Haptic Feedback Enhancement

#### Task 2.1: Implement Advanced Haptic Patterns
**Priority**: 🟡 High
**Estimated Time**: 6 hours
**Dependencies**: Task 1.2

**Subtasks**:
1. Update `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Services/HapticManager.swift`:
   ```swift
   import Foundation
   import WatchKit

   class HapticManager: ObservableObject {
       static let shared = HapticManager()

       private init() {}

       // MARK: - Basic Haptics

       func playTapReceivedHaptic(intensity: String, pattern: String) {
           switch (intensity, pattern) {
           case ("light", "single"):
               playLightSingle()
           case ("light", "double"):
               playLightDouble()
           case ("light", "triple"):
               playLightTriple()
           case ("light", "heartbeat"):
               playLightHeartbeat()

           case ("medium", "single"):
               playMediumSingle()
           case ("medium", "double"):
               playMediumDouble()
           case ("medium", "triple"):
               playMediumTriple()
           case ("medium", "heartbeat"):
               playMediumHeartbeat()

           case ("strong", "single"):
               playStrongSingle()
           case ("strong", "double"):
               playStrongDouble()
           case ("strong", "triple"):
               playStrongTriple()
           case ("strong", "heartbeat"):
               playStrongHeartbeat()

           default:
               playMediumSingle()
           }
       }

       func playTapSentHaptic() {
           WKInterfaceDevice.current().play(.click)
       }

       func playSuccessHaptic() {
           WKInterfaceDevice.current().play(.success)
       }

       func playErrorHaptic() {
           WKInterfaceDevice.current().play(.failure)
       }

       // MARK: - Light Intensity Patterns

       private func playLightSingle() {
           WKInterfaceDevice.current().play(.click)
       }

       private func playLightDouble() {
           WKInterfaceDevice.current().play(.click)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.click)
           }
       }

       private func playLightTriple() {
           WKInterfaceDevice.current().play(.click)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.click)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               WKInterfaceDevice.current().play(.click)
           }
       }

       private func playLightHeartbeat() {
           WKInterfaceDevice.current().play(.click)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
               WKInterfaceDevice.current().play(.click)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
               WKInterfaceDevice.current().play(.click)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
               WKInterfaceDevice.current().play(.click)
           }
       }

       // MARK: - Medium Intensity Patterns

       private func playMediumSingle() {
           WKInterfaceDevice.current().play(.notification)
       }

       private func playMediumDouble() {
           WKInterfaceDevice.current().play(.notification)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.notification)
           }
       }

       private func playMediumTriple() {
           WKInterfaceDevice.current().play(.notification)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.notification)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               WKInterfaceDevice.current().play(.notification)
           }
       }

       private func playMediumHeartbeat() {
           WKInterfaceDevice.current().play(.notification)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
               WKInterfaceDevice.current().play(.notification)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
               WKInterfaceDevice.current().play(.notification)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
               WKInterfaceDevice.current().play(.notification)
           }
       }

       // MARK: - Strong Intensity Patterns

       private func playStrongSingle() {
           WKInterfaceDevice.current().play(.directionUp)
       }

       private func playStrongDouble() {
           WKInterfaceDevice.current().play(.directionUp)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.directionUp)
           }
       }

       private func playStrongTriple() {
           WKInterfaceDevice.current().play(.directionUp)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               WKInterfaceDevice.current().play(.directionUp)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               WKInterfaceDevice.current().play(.directionUp)
           }
       }

       private func playStrongHeartbeat() {
           WKInterfaceDevice.current().play(.directionUp)
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
               WKInterfaceDevice.current().play(.directionUp)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
               WKInterfaceDevice.current().play(.directionUp)
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
               WKInterfaceDevice.current().play(.directionUp)
           }
       }
   }
   ```

2. Update WatchConnectivityManager to call new haptic method with parameters
3. Test all 12 haptic combinations on physical Watch

**Success Criteria**:
- ✅ 12 distinct haptic patterns implemented (3 intensities × 4 patterns)
- ✅ Haptics play correctly when taps received
- ✅ Timing feels natural (tested on device)
- ✅ No haptic queuing issues

---

## Phase 2: Complications & Integration (Week 3-5)

### Week 3: Watch Complications

#### Task 3.1: Implement Complication Provider
**Priority**: 🟡 High
**Estimated Time**: 10 hours
**Dependencies**: iOS WatchConnectivity complete

**Subtasks**:
1. Create `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Complications/ComplicationController.swift`:
   ```swift
   import ClockKit
   import SwiftUI

   class ComplicationController: NSObject, CLKComplicationDataSource {

       // MARK: - Complication Configuration

       func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
           let descriptors = [
               CLKComplicationDescriptor(
                   identifier: "navi-tap-status",
                   displayName: "Navi Tap Status",
                   supportedFamilies: [
                       .circularSmall,
                       .modularSmall,
                       .utilitarianSmall,
                       .graphicCircular,
                       .graphicCorner,
                       .graphicBezel
                   ]
               )
           ]

           handler(descriptors)
       }

       // MARK: - Timeline Configuration

       func getTimelineEndDate(for complication: CLKComplication,
                             withHandler handler: @escaping (Date?) -> Void) {
           // Update every hour
           handler(Date().addingTimeInterval(3600))
       }

       func getPrivacyBehavior(for complication: CLKComplication,
                             withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
           handler(.showOnLockScreen)
       }

       // MARK: - Timeline Population

       func getCurrentTimelineEntry(for complication: CLKComplication,
                                   withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
           let connectivityManager = WatchConnectivityManager.shared

           let template: CLKComplicationTemplate

           switch complication.family {
           case .circularSmall:
               let circularTemplate = CLKComplicationTemplateCircularSmallSimpleImage()
               circularTemplate.imageProvider = CLKImageProvider(
                   onePieceImage: UIImage(systemName: connectivityManager.isPaired ? "heart.fill" : "heart")!
               )
               template = circularTemplate

           case .modularSmall:
               let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
               modularTemplate.imageProvider = CLKImageProvider(
                   onePieceImage: UIImage(systemName: connectivityManager.isPaired ? "heart.fill" : "heart")!
               )
               template = modularTemplate

           case .graphicCircular:
               let graphicTemplate = CLKComplicationTemplateGraphicCircularImage()
               graphicTemplate.imageProvider = CLKFullColorImageProvider(
                   fullColorImage: UIImage(systemName: connectivityManager.isPaired ? "heart.fill" : "heart")!
               )
               template = graphicTemplate

           case .graphicCorner:
               let cornerTemplate = CLKComplicationTemplateGraphicCornerTextImage()
               cornerTemplate.textProvider = CLKSimpleTextProvider(
                   text: connectivityManager.isPaired ? "Paired" : "Unpaired"
               )
               cornerTemplate.imageProvider = CLKFullColorImageProvider(
                   fullColorImage: UIImage(systemName: "heart.fill")!
               )
               template = cornerTemplate

           default:
               handler(nil)
               return
           }

           let entry = CLKComplicationTimelineEntry(
               date: Date(),
               complicationTemplate: template
           )
           handler(entry)
       }

       func getTimelineEntries(for complication: CLKComplication,
                             after date: Date,
                             limit: Int,
                             withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
           // Provide future timeline entries if needed
           handler(nil)
       }

       // MARK: - Sample Templates

       func getLocalizableSampleTemplate(for complication: CLKComplication,
                                        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
           getCurrentTimelineEntry(for: complication) { entry in
               handler(entry?.complicationTemplate)
           }
       }
   }
   ```

2. Update Info.plist to register complications:
   ```xml
   <key>CLKComplicationPrincipalClass</key>
   <string>$(PRODUCT_MODULE_NAME).ComplicationController</string>
   <key>CLKComplicationSupportedFamilies</key>
   <array>
       <string>CLKComplicationFamilyCircularSmall</string>
       <string>CLKComplicationFamilyGraphicCircular</string>
       <string>CLKComplicationFamilyGraphicCorner</string>
       <string>CLKComplicationFamilyModularSmall</string>
   </array>
   ```

3. Update complications when pairing status changes:
   ```swift
   // In WatchConnectivityManager
   private func updateComplications() {
       let server = CLKComplicationServer.sharedInstance()
       server.activeComplications?.forEach { complication in
           server.reloadTimeline(for: complication)
       }
   }
   ```

**Success Criteria**:
- ✅ Complication shows on watch faces
- ✅ Updates when pairing status changes
- ✅ Tappable to launch app
- ✅ Supports multiple watch face families

---

### Week 4-5: WatchConnectivity Enhancement & Testing

#### Task 4.1: Enhanced WatchConnectivity Manager
**Priority**: 🟡 High
**Estimated Time**: 6 hours
**Dependencies**: iOS WatchConnectivity complete

**Subtasks**:
1. Update `/home/user/navi/Navi_app/Navi_app Watch App Watch App/Services/WatchConnectivityManager.swift`:
   ```swift
   import Foundation
   import WatchConnectivity

   @MainActor
   class WatchConnectivityManager: NSObject, ObservableObject {
       static let shared = WatchConnectivityManager()

       @Published var isReachable = false
       @Published var isPaired = false
       @Published var isAuthenticated = false
       @Published var userId: String?
       @Published var authToken: String?
       @Published var partnerId: String?

       private var session: WCSession?

       override private init() {
           super.init()

           if WCSession.isSupported() {
               session = WCSession.default
               session?.delegate = self
               session?.activate()
           }

           // Load cached state from UserDefaults (App Group)
           loadCachedState()
       }

       // MARK: - State Management

       private func loadCachedState() {
           let defaults = UserDefaults(suiteName: Constants.appGroup) ?? UserDefaults.standard

           userId = defaults.string(forKey: "userId")
           authToken = defaults.string(forKey: "authToken")
           partnerId = defaults.string(forKey: "partnerId")

           isAuthenticated = userId != nil && authToken != nil
           isPaired = partnerId != nil
       }

       private func saveState() {
           let defaults = UserDefaults(suiteName: Constants.appGroup) ?? UserDefaults.standard

           defaults.set(userId, forKey: "userId")
           defaults.set(authToken, forKey: "authToken")
           defaults.set(partnerId, forKey: "partnerId")
       }

       // MARK: - Tap Sending

       func sendTap(intensity: String, pattern: String) async {
           guard let session = session, session.isReachable else {
               // Queue for later if iPhone not reachable
               queueTap(intensity: intensity, pattern: pattern)
               return
           }

           let message: [String: Any] = [
               "type": "tap",
               "intensity": intensity,
               "pattern": pattern,
               "timestamp": ISO8601DateFormatter().string(from: Date())
           ]

           session.sendMessage(message, replyHandler: nil) { error in
               print("Error sending tap: \(error)")
               Task { @MainActor in
                   HapticManager.shared.playErrorHaptic()
               }
           }
       }

       private func queueTap(intensity: String, pattern: String) {
           // Use transferUserInfo for guaranteed delivery
           let userInfo: [String: Any] = [
               "type": "tap",
               "intensity": intensity,
               "pattern": pattern,
               "timestamp": ISO8601DateFormatter().string(from: Date())
           ]

           session?.transferUserInfo(userInfo)
       }

       // MARK: - Message Handling

       private func handleAuthMessage(_ message: [String: Any]) {
           guard let userId = message["userId"] as? String,
                 let token = message["token"] as? String else { return }

           self.userId = userId
           self.authToken = token
           self.isAuthenticated = true
           saveState()
       }

       private func handlePairingMessage(_ message: [String: Any]) {
           guard let paired = message["paired"] as? Bool else { return }

           self.isPaired = paired

           if paired {
               self.partnerId = message["partnerId"] as? String
           } else {
               self.partnerId = nil
           }

           saveState()

           // Update complications
           updateComplications()
       }

       private func handleIncomingTap(_ message: [String: Any]) {
           guard let intensity = message["intensity"] as? String,
                 let pattern = message["pattern"] as? String else { return }

           HapticManager.shared.playTapReceivedHaptic(
               intensity: intensity,
               pattern: pattern
           )
       }

       private func updateComplications() {
           // Implementation from Task 3.1
       }
   }

   // MARK: - WCSessionDelegate

   extension WatchConnectivityManager: WCSessionDelegate {
       nonisolated func session(_ session: WCSession,
                               activationDidCompleteWith activationState: WCSessionActivationState,
                               error: Error?) {
           Task { @MainActor in
               isReachable = session.isReachable
           }
       }

       nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
           Task { @MainActor in
               isReachable = session.isReachable
           }
       }

       nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
           Task { @MainActor in
               guard let type = message["type"] as? String else { return }

               switch type {
               case "auth":
                   handleAuthMessage(message)
               case "pairing":
                   handlePairingMessage(message)
               case "tap":
                   handleIncomingTap(message)
               default:
                   break
               }
           }
       }

       nonisolated func session(_ session: WCSession,
                               didReceiveUserInfo userInfo: [String: Any]) {
           // Handle queued messages that arrived via transferUserInfo
           Task { @MainActor in
               session(session, didReceiveMessage: userInfo)
           }
       }
   }
   ```

2. Test message queueing when iPhone disconnected
3. Test state persistence across app restarts
4. Test complication updates

**Success Criteria**:
- ✅ State syncs from iPhone to Watch
- ✅ Taps queued when iPhone unreachable
- ✅ State persists across Watch app restarts
- ✅ Complications update automatically

---

#### Task 4.2: Comprehensive watchOS Testing
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Enhance `/home/user/navi/Navi_app/Navi_app Watch App Watch AppTests/WatchConnectivityTests.swift`
2. Add UI tests for Watch app
3. Test all haptic patterns on physical device
4. Test complications on multiple watch faces
5. Test offline/online scenarios

**Success Criteria**:
- ✅ Test coverage ≥70%
- ✅ All UI flows tested
- ✅ Haptics verified on device
- ✅ Integration with iPhone tested

---

## Phase 3: Polish & Optimization (Week 6-8)

### Week 6-7: Background Updates & Optimization

#### Task 5.1: Implement Background Updates
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Add Info.plist background modes:
   ```xml
   <key>WKBackgroundModes</key>
   <array>
       <string>remote-notification</string>
       <string>workout-processing</string>
   </array>
   ```

2. Schedule background refresh tasks:
   ```swift
   // In NaviWatchApp
   func scheduleBackgroundRefresh() {
       let targetDate = Date().addingTimeInterval(4 * 60 * 60) // 4 hours

       WKExtension.shared().scheduleBackgroundRefresh(
           withPreferredDate: targetDate,
           userInfo: nil
       ) { error in
           if let error = error {
               print("Failed to schedule background refresh: \(error)")
           }
       }
   }

   func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
       for task in backgroundTasks {
           if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
               // Sync state with iPhone if needed
               scheduleBackgroundRefresh() // Schedule next refresh
               refreshTask.setTaskCompletedWithSnapshot(false)
           } else {
               task.setTaskCompletedWithSnapshot(false)
           }
       }
   }
   ```

3. Optimize battery usage:
   - Reduce WatchConnectivity checks
   - Batch updates
   - Use efficient animations

**Success Criteria**:
- ✅ Background refresh scheduled
- ✅ State syncs even when app not active
- ✅ Battery usage reasonable (<5% per day)

---

### Week 8: Accessibility & Documentation

#### Task 6.1: Accessibility Implementation
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Add accessibility labels to all views
2. Test with VoiceOver on Watch
3. Support larger text sizes
4. Add accessibility identifiers for testing

**Success Criteria**:
- ✅ All elements accessible via VoiceOver
- ✅ Haptic feedback supplements visual cues
- ✅ Dynamic Type supported

---

## Phase 4: Launch (Week 9-10)

### Week 9-10: Final Testing & Polish

#### Task 7.1: End-to-End Integration Testing
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Test complete flow: iPhone pair → Watch send tap → iPhone receive
2. Test complications on all supported watch faces
3. Test with multiple Watch sizes (38mm-49mm)
4. Test airplane mode scenarios
5. Battery profiling with Instruments

**Success Criteria**:
- ✅ All user flows work end-to-end
- ✅ Works on all Watch sizes
- ✅ Complications functional on all faces
- ✅ Battery usage acceptable

---

## Success Criteria Summary

### Phase 1 Complete When:
- ✅ Complete Watch UI functional
- ✅ All views implemented
- ✅ 12 haptic patterns working
- ✅ Navigation smooth

### Phase 2 Complete When:
- ✅ Complications implemented
- ✅ WatchConnectivity fully functional
- ✅ State syncs reliably
- ✅ Test coverage ≥70%

### Phase 3 Complete When:
- ✅ Background updates working
- ✅ Accessibility complete
- ✅ Battery optimized
- ✅ Documentation updated

### Phase 4 Complete When:
- ✅ End-to-end testing passed
- ✅ Ready for App Store submission
- ✅ No critical bugs

---

## Estimated Total Time

- Phase 1: 14 hours (2 weeks @ 7h/week)
- Phase 2: 22 hours (3 weeks @ 7h/week)
- Phase 3: 8 hours (3 weeks @ 3h/week)
- Phase 4: 6 hours (2 weeks @ 3h/week)

**Total**: ~50 hours over 10 weeks

---

**Action Plan Owner**: watchOS Development Lead
**Last Updated**: 2025-11-23
**Next Review**: End of Phase 1 (Week 2)
