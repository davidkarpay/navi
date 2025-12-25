# iOS Development Lead - Action Plan
**Agent**: iOS Development Lead
**Domain**: iPhone Companion App (SwiftUI)
**Current Status**: 40% Production Ready

---

## Mission Statement
Transform the iOS companion app from a broken prototype with critical missing features into a fully functional, accessible, and production-ready application with working push notifications and Apple Watch integration.

---

## Phase 1: Critical Blockers (Week 1-2)

### Week 1: Push Notifications Foundation

#### Task 1.1: Add AppDelegate for Remote Notifications
**Priority**: 🔴 Critical
**Estimated Time**: 4 hours
**Dependencies**: None

**Subtasks**:
1. Create `/home/user/navi/ios/NaviPhone/AppDelegate.swift`:
   ```swift
   import UIKit
   import UserNotifications

   class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
       func application(_ application: UIApplication,
                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

           // Set notification delegate
           UNUserNotificationCenter.current().delegate = self

           // Register for remote notifications
           application.registerForRemoteNotifications()

           return true
       }

       func application(_ application: UIApplication,
                       didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
           let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
           print("Device token: \(token)")

           // Update NotificationManager with token
           Task {
               await NotificationManager.shared.updateDeviceToken(token)
           }
       }

       func application(_ application: UIApplication,
                       didFailToRegisterForRemoteNotificationsWithError error: Error) {
           print("Failed to register for remote notifications: \(error)")
       }

       func application(_ application: UIApplication,
                       didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                       fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

           // Handle remote notification
           if let tapData = userInfo["data"] as? [String: Any],
              let fromUserId = tapData["fromUserId"] as? String,
              let intensity = tapData["intensity"] as? String,
              let pattern = tapData["pattern"] as? String {

               // Trigger haptic and update UI
               Task {
                   await TapManager.shared.handleIncomingTap(
                       fromUserId: fromUserId,
                       intensity: intensity,
                       pattern: pattern
                   )
               }

               completionHandler(.newData)
           } else {
               completionHandler(.noData)
           }
       }

       // MARK: - UNUserNotificationCenterDelegate

       func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
           // Show notification even when app is in foreground
           completionHandler([.banner, .sound])
       }

       func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  didReceive response: UNNotificationResponse,
                                  withCompletionHandler completionHandler: @escaping () -> Void) {
           // Handle notification tap
           let userInfo = response.notification.request.content.userInfo

           if let tapData = userInfo["data"] as? [String: Any] {
               // Navigate to appropriate screen or update state
               print("User tapped notification: \(tapData)")
           }

           completionHandler()
       }
   }
   ```

2. Update `/home/user/navi/ios/NaviPhone/NaviApp.swift`:
   ```swift
   import SwiftUI

   @main
   struct NaviApp: App {
       @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

       @StateObject private var authManager = AuthManager()
       @StateObject private var pairingManager = PairingManager()
       @StateObject private var tapManager = TapManager()

       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environmentObject(authManager)
                   .environmentObject(pairingManager)
                   .environmentObject(tapManager)
           }
       }
   }
   ```

3. Update `/home/user/navi/ios/NaviPhone/Services/NotificationManager.swift`:
   ```swift
   // Add method to update device token with auth context
   func updateDeviceToken(_ token: String) async {
       self.deviceToken = token

       // Send to backend if authenticated
       if let userId = UserDefaults.standard.string(forKey: "userId"),
          let authToken = UserDefaults.standard.string(forKey: "authToken") {

           let baseURL = ProcessInfo.processInfo.environment["API_URL"]
                        ?? "https://navi-production-97dd.up.railway.app"

           guard let url = URL(string: "\(baseURL)/api/auth/device-token") else { return }

           var request = URLRequest(url: url)
           request.httpMethod = "PUT"
           request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           let body = ["userId": userId, "deviceToken": token]
           request.httpBody = try? JSONEncoder().encode(body)

           do {
               let (_, response) = try await URLSession.shared.data(for: request)
               if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                   print("Device token updated successfully")
               }
           } catch {
               print("Failed to update device token: \(error)")
           }
       }
   }
   ```

**Success Criteria**:
- ✅ AppDelegate receives device token callbacks
- ✅ Device token sent to backend after registration
- ✅ Remote notifications trigger haptic feedback
- ✅ Notifications shown when app in foreground/background

**Testing**:
- Test on physical device (simulator won't work)
- Verify device token in backend logs
- Send test push via backend, verify received

---

#### Task 1.2: Fix TapMessage Model Mismatch
**Priority**: 🔴 Critical
**Estimated Time**: 1 hour
**Dependencies**: None

**Subtasks**:
1. Update `/home/user/navi/ios/Tests/NaviTests.swift` lines 9-12:
   ```swift
   // Change from:
   let tapMessage = TapMessage(senderId: senderId, receiverId: receiverId, ...)

   // To:
   let tapMessage = TapMessage(fromUserId: senderId, toUserId: receiverId, ...)
   ```

2. Update all test assertions to use correct property names
3. Run tests to verify they pass

**Success Criteria**:
- ✅ All tests compile without errors
- ✅ All tests pass
- ✅ TapMessage usage consistent across codebase

---

### Week 2: Configuration and Entitlements

#### Task 2.1: Configure App Groups
**Priority**: 🔴 Critical
**Estimated Time**: 3 hours
**Dependencies**: Integration Agent fixing Constants.swift

**Subtasks**:
1. Create entitlements file for NaviPhone (if doesn't exist):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.application-groups</key>
       <array>
           <string>group.Rosenbaum.Navi-app</string>
       </array>
       <key>aps-environment</key>
       <string>production</string>
   </dict>
   </plist>
   ```

2. Update all service managers to use App Group UserDefaults:
   ```swift
   // Instead of:
   let defaults = UserDefaults.standard

   // Use:
   let defaults = UserDefaults(suiteName: Constants.appGroup) ?? UserDefaults.standard
   ```

3. Update in these files:
   - `AuthManager.swift`
   - `PairingManager.swift`
   - `TapManager.swift`

4. Configure in Xcode project:
   - Select NaviPhone target
   - Signing & Capabilities tab
   - Add App Groups capability
   - Add `group.Rosenbaum.Navi-app`

**Success Criteria**:
- ✅ App Groups entitlement added to target
- ✅ All UserDefaults use App Group suite
- ✅ Data accessible from both iOS and watchOS apps
- ✅ App builds and runs without signing errors

---

#### Task 2.2: Fix Backend URL Configuration
**Priority**: 🔴 Critical
**Estimated Time**: 1 hour
**Dependencies**: Integration Agent updating backend URL

**Subtasks**:
1. Wait for Integration Agent to update correct backend URL in Constants.swift
2. Update all service managers to use centralized constant:
   ```swift
   // In AuthManager, PairingManager, TapManager:
   let baseURL = Constants.backendURL
   ```

3. Remove hardcoded URLs from:
   - `/home/user/navi/ios/NaviPhone/Services/AuthManager.swift:9`
   - `/home/user/navi/ios/NaviPhone/Services/PairingManager.swift:9`
   - `/home/user/navi/ios/NaviPhone/Services/TapManager.swift:7`

**Success Criteria**:
- ✅ Single source of truth for backend URL
- ✅ All API calls use centralized configuration
- ✅ Environment variable override still works
- ✅ All API calls succeed

---

## Phase 2: Core Features (Week 3-5)

### Week 3: WatchConnectivity Integration

#### Task 3.1: Implement iOS WatchConnectivity Manager
**Priority**: 🟡 High
**Estimated Time**: 6 hours
**Dependencies**: watchOS UI completion

**Subtasks**:
1. Create `/home/user/navi/ios/NaviPhone/Services/WatchConnectivityManager.swift`:
   ```swift
   import Foundation
   import WatchConnectivity

   @MainActor
   class WatchConnectivityManager: NSObject, ObservableObject {
       static let shared = WatchConnectivityManager()

       @Published var isReachable = false
       @Published var isPaired = false

       private var session: WCSession?

       override private init() {
           super.init()

           if WCSession.isSupported() {
               session = WCSession.default
               session?.delegate = self
               session?.activate()
           }
       }

       // Send authentication state to Watch
       func syncAuthState(userId: String, token: String) {
           guard let session = session, session.isReachable else { return }

           let message: [String: Any] = [
               "type": "auth",
               "userId": userId,
               "token": token
           ]

           session.sendMessage(message, replyHandler: nil) { error in
               print("Error syncing auth to Watch: \(error)")
           }
       }

       // Send pairing state to Watch
       func syncPairingState(paired: Bool, partnerId: String?) {
           guard let session = session, session.isReachable else {
               // Use transferUserInfo for guaranteed delivery even when not reachable
               let userInfo: [String: Any] = [
                   "type": "pairing",
                   "paired": paired,
                   "partnerId": partnerId ?? ""
               ]
               session?.transferUserInfo(userInfo)
               return
           }

           let message: [String: Any] = [
               "type": "pairing",
               "paired": paired,
               "partnerId": partnerId ?? ""
           ]

           session.sendMessage(message, replyHandler: nil) { error in
               print("Error syncing pairing to Watch: \(error)")
           }
       }

       // Send tap from Watch to backend
       func handleTapFromWatch(intensity: String, pattern: String) async {
           // Forward to TapManager to send via backend API
           await TapManager.shared.sendTap(intensity: intensity, pattern: pattern)
       }
   }

   extension WatchConnectivityManager: WCSessionDelegate {
       nonisolated func session(_ session: WCSession,
                               activationDidCompleteWith activationState: WCSessionActivationState,
                               error: Error?) {
           Task { @MainActor in
               isPaired = session.isPaired
               isReachable = session.isReachable
           }
       }

       nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
           Task { @MainActor in
               isReachable = session.isReachable
           }
       }

       nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
           // iOS only
       }

       nonisolated func sessionDidDeactivate(_ session: WCSession) {
           // iOS only - reactivate for Apple Watch switching
           session.activate()
       }

       nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
           Task { @MainActor in
               guard let type = message["type"] as? String else { return }

               switch type {
               case "tap":
                   if let intensity = message["intensity"] as? String,
                      let pattern = message["pattern"] as? String {
                       await handleTapFromWatch(intensity: intensity, pattern: pattern)
                   }
               default:
                   break
               }
           }
       }
   }
   ```

2. Integrate with existing managers:
   - Call `syncAuthState()` after successful registration
   - Call `syncPairingState()` after pairing/unpairing
   - Forward incoming taps from backend to Watch

3. Add to environment objects in NaviApp.swift

**Success Criteria**:
- ✅ iOS and Watch can communicate bidirectionally
- ✅ Auth state syncs to Watch after login
- ✅ Pairing state syncs automatically
- ✅ Taps sent from Watch reach backend
- ✅ Messages queued when Watch unreachable

---

### Week 4: Testing and Bug Fixes

#### Task 4.1: Add Comprehensive Unit Tests
**Priority**: 🟡 High
**Estimated Time**: 8 hours

**Subtasks**:
1. Create `/home/user/navi/ios/Tests/TapManagerTests.swift`:
   ```swift
   import XCTest
   @testable import NaviPhone

   final class TapManagerTests: XCTestCase {
       var tapManager: TapManager!

       override func setUp() {
           super.setUp()
           tapManager = TapManager()
       }

       func testSendTapRequiresAuthentication() async {
           // Test that sending tap without auth fails gracefully
       }

       func testSendTapFormatsRequestCorrectly() async {
           // Test request body contains correct fields
       }

       func testHandleIncomingTapTriggersHaptic() async {
           // Test that incoming tap triggers haptic feedback
       }

       func testTapHistoryStoresCorrectly() async {
           // Test tap history storage and retrieval
       }

       func testHapticPatternsExecuteCorrectly() {
           // Test each haptic pattern (single, double, triple, heartbeat)
       }
   }
   ```

2. Add tests for AppDelegate notification handling
3. Add tests for WatchConnectivityManager
4. Add UI tests for critical flows (registration, pairing, tap sending)

**Success Criteria**:
- ✅ TapManager has comprehensive test coverage
- ✅ All service managers tested
- ✅ Test coverage ≥70% for iOS app
- ✅ All tests pass consistently

---

#### Task 4.2: Fix Code Duplication
**Priority**: 🟡 High
**Estimated Time**: 4 hours
**Dependencies**: Decision on which codebase to keep

**Subtasks**:
1. **Decision Point**: Choose between `/ios/NaviPhone/` and `/Navi_app/Navi_app/`
   - Recommendation: Keep Navi_app (has Xcode project with Watch app)
   - Migrate any unique features from NaviPhone

2. Delete duplicate implementation:
   ```bash
   # After confirming Navi_app has all features
   rm -rf ios/NaviPhone/
   ```

3. Update Package.swift paths to point to correct location
4. Update CI/CD workflows to build correct target
5. Update all documentation references

**Success Criteria**:
- ✅ Single iOS app implementation
- ✅ All features preserved
- ✅ No duplicate service files
- ✅ CI/CD builds correct target

---

### Week 5: Accessibility and Polish

#### Task 5.1: Implement Accessibility Features
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Add accessibility labels to all views:
   ```swift
   // Example in PairedView:
   Button("Send Tap") { /* ... */ }
       .accessibilityLabel("Send tap to paired partner")
       .accessibilityHint("Double tap to send a tap notification")

   // In CreateCodeView:
   Text(code)
       .accessibilityLabel("Pairing code is \(codeSpokenFormat)")
   ```

2. Add accessibility identifiers for UI testing:
   ```swift
   Button("Get Started") { /* ... */ }
       .accessibilityIdentifier("welcomeGetStartedButton")
   ```

3. Test with VoiceOver:
   - Enable VoiceOver in Settings
   - Navigate through entire app
   - Ensure all elements are accessible
   - Fix any issues found

4. Support Dynamic Type:
   - Use system fonts throughout
   - Test at largest accessibility sizes
   - Ensure layouts don't break

5. Add accessibility documentation to README

**Success Criteria**:
- ✅ All interactive elements have labels
- ✅ App navigable via VoiceOver
- ✅ Dynamic Type supported
- ✅ Accessibility audit passed

---

#### Task 5.2: UI/UX Polish
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Add loading states with proper indicators
2. Improve error messages:
   - Make user-friendly
   - Provide actionable guidance
   - Add retry buttons where appropriate

3. Add animations:
   - Tap sending feedback
   - Pairing success celebration
   - Smooth transitions

4. Display last tap time in PairedView:
   ```swift
   // Fix the binding issue mentioned in status report
   if let lastTap = tapManager.lastReceivedTap {
       Text("Last tap: \(formatRelativeTime(lastTap.timestamp))")
           .font(.caption)
           .foregroundColor(.secondary)
   }
   ```

5. Dark mode optimization:
   - Test all screens in dark mode
   - Adjust colors if needed
   - Ensure proper contrast

**Success Criteria**:
- ✅ Loading states on all async operations
- ✅ Helpful error messages
- ✅ Smooth animations throughout
- ✅ Last tap time displayed correctly
- ✅ Looks great in dark mode

---

## Phase 3: Production Readiness (Week 6-8)

### Week 6-7: Integration Testing

#### Task 6.1: End-to-End Integration Tests
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Set up UI test target if not exists
2. Create UI tests for complete flows:
   ```swift
   func testCompleteRegistrationFlow() {
       // Test welcome → register → pairing screen
   }

   func testCompletePairingFlow() {
       // Test create code → share → join → paired
   }

   func testSendAndReceiveTapFlow() {
       // Test tap sending and receiving
   }

   func testUnpairFlow() {
       // Test unpairing and return to pairing screen
   }
   ```

3. Test error scenarios:
   - Network failures
   - Invalid pairing codes
   - Token expiration

4. Test offline mode:
   - Disable network
   - Verify graceful degradation
   - Test sync when reconnected

**Success Criteria**:
- ✅ UI tests cover critical user journeys
- ✅ Error scenarios handled gracefully
- ✅ Offline mode tested
- ✅ Tests run in CI

---

### Week 8: Documentation and Cleanup

#### Task 7.1: Code Documentation
**Priority**: 🟢 Medium
**Estimated Time**: 3 hours

**Subtasks**:
1. Add documentation comments to public interfaces:
   ```swift
   /// Manages user authentication and JWT token storage
   @MainActor
   class AuthManager: ObservableObject {
       /// The current authenticated user's ID
       @Published var userId: String?

       /// Registers a new user and stores authentication credentials
       /// - Returns: The user ID and auth token if successful
       /// - Throws: NetworkError if registration fails
       func register() async throws -> (userId: String, token: String) {
           // ...
       }
   }
   ```

2. Update README with iOS app architecture
3. Document WatchConnectivity integration
4. Add troubleshooting guide for common issues

**Success Criteria**:
- ✅ All public APIs documented
- ✅ README updated
- ✅ Architecture documented
- ✅ Troubleshooting guide complete

---

## Phase 4: Launch Preparation (Week 9-10)

### Week 9-10: Final Testing and Optimization

#### Task 8.1: Performance Optimization
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Profile app with Instruments:
   - Check for memory leaks
   - Optimize view rendering
   - Reduce CPU usage

2. Optimize network requests:
   - Add request caching where appropriate
   - Implement retry with exponential backoff
   - Batch operations where possible

3. Optimize battery usage:
   - Reduce background activity
   - Optimize WebSocket reconnection logic
   - Profile with Energy Log

**Success Criteria**:
- ✅ No memory leaks detected
- ✅ App launches in <2 seconds
- ✅ Smooth 60fps scrolling
- ✅ Reasonable battery impact

---

#### Task 8.2: App Store Preparation
**Priority**: 🟡 High
**Estimated Time**: 4 hours
**Dependencies**: DevOps Agent setting up TestFlight

**Subtasks**:
1. Create App Store assets:
   - App icon (all required sizes)
   - Screenshots (iPhone 15 Pro, iPhone 15 Pro Max)
   - App Store description
   - Keywords for ASO

2. Update Info.plist:
   - Privacy descriptions
   - Background modes
   - Required device capabilities

3. Test on multiple device sizes:
   - iPhone SE (small)
   - iPhone 15 (standard)
   - iPhone 15 Pro Max (large)

4. Create release notes for TestFlight
5. Submit for TestFlight beta testing

**Success Criteria**:
- ✅ App Store assets ready
- ✅ App runs on all supported devices
- ✅ Privacy descriptions complete
- ✅ TestFlight build submitted

---

## Ongoing Responsibilities

### Daily Tasks
- Respond to bug reports from QA
- Review PRs from other iOS developers
- Monitor Xcode Cloud build status
- Test on physical devices

### Weekly Tasks
- Update dependencies
- Review crash reports
- Sync with watchOS agent on WatchConnectivity
- Update UI/UX based on feedback

### On-Call Duties
- Fix critical iOS bugs
- Address App Store review issues
- Respond to user-reported issues

---

## Key Metrics to Track

### Development Phase
- Test coverage (target: ≥70%)
- Build success rate (target: 100%)
- Crash-free rate (target: ≥99%)
- Code review turnaround (target: <4 hours)

### Production Phase
- App Store rating (target: ≥4.5)
- Crash-free sessions (target: ≥99.5%)
- App launch time (target: <2s)
- Network request success rate (target: ≥95%)

---

## Dependencies on Other Agents

### From Backend Agent
- Push notification payload format
- API endpoint stability
- Error message formats

### From watchOS Agent
- WatchConnectivity message protocol
- Shared data requirements
- Haptic feedback specifications

### From Integration Agent
- Correct backend URL
- Shared package updates
- Data model consistency

### From QA Agent
- Test scenarios
- Bug reports
- Performance benchmarks

### From DevOps Agent
- TestFlight upload automation
- Certificate management
- App Store Connect configuration

---

## Success Criteria Summary

### Phase 1 Complete When:
- ✅ Push notifications fully functional
- ✅ Device tokens reaching backend
- ✅ Test failures fixed
- ✅ App Groups configured
- ✅ Backend URL corrected

### Phase 2 Complete When:
- ✅ WatchConnectivity implemented
- ✅ Tests comprehensive (≥70% coverage)
- ✅ Code duplication eliminated
- ✅ Accessibility implemented
- ✅ UI polished

### Phase 3 Complete When:
- ✅ Integration tests passing
- ✅ Documentation complete
- ✅ Error handling robust
- ✅ Code reviewed and clean

### Phase 4 Complete When:
- ✅ Performance optimized
- ✅ App Store assets ready
- ✅ TestFlight beta live
- ✅ Ready for App Store submission

---

## Estimated Total Time

- Phase 1: 9 hours (2 weeks @ 4.5h/week)
- Phase 2: 24 hours (3 weeks @ 8h/week)
- Phase 3: 9 hours (3 weeks @ 3h/week)
- Phase 4: 8 hours (2 weeks @ 4h/week)

**Total**: ~50 hours over 10 weeks

---

## Resources Needed

### Tools
- Xcode 15+
- Physical iPhone for testing
- Apple Watch for WatchConnectivity testing
- TestFlight access

### Documentation
- Apple Human Interface Guidelines
- WatchConnectivity documentation
- UserNotifications framework docs
- Accessibility guidelines

### Support
- Backend agent for API contracts
- watchOS agent for integration
- Integration agent for shared code
- DevOps agent for CI/CD

---

**Action Plan Owner**: iOS Development Lead
**Last Updated**: 2025-11-23
**Next Review**: End of Phase 1 (Week 2)
