# QA & Testing Lead - Action Plan
**Agent**: QA & Testing Lead
**Domain**: Testing, Quality Assurance, CI/CD
**Current Status**: 45% Test Coverage (Mixed)

---

## Mission Statement
Establish comprehensive testing coverage across all platforms, fix CI/CD issues that mask failures, implement quality gates, and ensure the application meets production quality standards through rigorous testing and validation.

---

## Phase 1: Critical CI/CD Fixes (Week 1-2)

### Week 1: Fix CI/CD Pipeline Issues

#### Task 1.1: Remove `continue-on-error` Flags
**Priority**: 🔴 Critical
**Estimated Time**: 4 hours
**Dependencies**: None

**Subtasks**:
1. Update `.github/workflows/tests.yml`:
   ```yaml
   # Line 78 - iOS Tests
   - name: Run iOS Tests
     run: |
       xcodebuild test \
         -project Navi_app/Navi_app.xcodeproj \
         -scheme Navi_app \
         -destination 'platform=iOS Simulator,name=iPhone 15'
     # REMOVE: continue-on-error: true

   # Line 106 - watchOS Build
   - name: Build watchOS
     run: |
       xcodebuild build \
         -project Navi_app/Navi_app.xcodeproj \
         -scheme "Navi_app Watch App" \
         -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
     # REMOVE: continue-on-error: true

   # Line 148 - ESLint
   - name: Run ESLint
     run: |
       cd backend
       npx eslint src/
     # REMOVE: continue-on-error: true

   # Line 161 - npm audit
   - name: Run npm audit
     run: |
       cd backend
       npm audit --production --audit-level=high
     # REMOVE: continue-on-error: true
   ```

2. Update `.github/workflows/deploy.yml`:
   ```yaml
   # Line 100 - TestFlight Upload
   - name: Upload to TestFlight
     run: |
       xcrun altool --upload-app \
         --type ios \
         --file "Navi.ipa" \
         --apiKey ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }} \
         --apiIssuer ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
     # REMOVE: continue-on-error: true
   ```

3. Fix underlying issues that caused need for `continue-on-error`:
   - iOS test failures (work with iOS agent)
   - watchOS build issues (work with watchOS agent)
   - ESLint violations (work with Backend agent)
   - npm audit vulnerabilities (work with Backend agent)

4. Test CI/CD pipeline on feature branch before merging

**Success Criteria**:
- ✅ All `continue-on-error: true` flags removed
- ✅ CI fails when tests fail (as it should)
- ✅ All CI jobs passing on main branch
- ✅ Team confident in CI results

**Testing**:
```bash
# Test locally before pushing
npm test # Backend
xcodebuild test # iOS
npx eslint src/ # Linting
npm audit --audit-level=high # Security
```

---

#### Task 1.2: Add Test Result Reporting
**Priority**: 🟡 High
**Estimated Time**: 3 hours
**Dependencies**: Task 1.1

**Subtasks**:
1. Add JUnit test result upload for backend:
   ```yaml
   - name: Run Backend Tests
     run: |
       cd backend
       npm test -- --reporter=junit --reporter-option output=test-results.xml

   - name: Upload Test Results
     if: always()
     uses: actions/upload-artifact@v3
     with:
       name: backend-test-results
       path: backend/test-results.xml
   ```

2. iOS tests already output JUnit (keep existing)

3. Add test summary to PR comments:
   ```yaml
   - name: Test Report
     uses: dorny/test-reporter@v1
     if: success() || failure()
     with:
       name: Test Results
       path: '**/test-results.xml'
       reporter: java-junit
   ```

4. Add coverage badges to README

**Success Criteria**:
- ✅ Test results visible in GitHub Actions UI
- ✅ Failed tests clearly highlighted
- ✅ Coverage metrics tracked over time
- ✅ PR comments show test summary

---

### Week 2: Backend Test Coverage

#### Task 2.1: Backend Integration Tests
**Priority**: 🔴 Critical
**Estimated Time**: 12 hours
**Dependencies**: Backend database implementation

**Subtasks**:
1. Create test database helper `/home/user/navi/backend/tests/helpers/test-db.js`:
   ```javascript
   import { initDatabase } from '../../src/db/init.js';
   import fs from 'fs';

   let testDb;

   export async function setupTestDatabase() {
     // Use in-memory database for tests
     process.env.DATABASE_URL = ':memory:';

     testDb = await initDatabase();
     return testDb;
   }

   export async function teardownTestDatabase() {
     if (testDb) {
       await testDb.close();
     }
   }

   export async function clearDatabase() {
     await testDb.exec(`
       DELETE FROM taps;
       DELETE FROM pairing_codes;
       DELETE FROM pairings;
       DELETE FROM users;
     `);
   }
   ```

2. Create `/home/user/navi/backend/tests/integration/auth-api.test.js`:
   ```javascript
   import { describe, it, before, after, beforeEach } from 'node:test';
   import assert from 'node:assert';
   import request from 'supertest';
   import { app } from '../../src/index.js';
   import { setupTestDatabase, teardownTestDatabase, clearDatabase } from '../helpers/test-db.js';

   describe('Auth API Integration Tests', () => {
     before(async () => {
       await setupTestDatabase();
     });

     after(async () => {
       await teardownTestDatabase();
     });

     beforeEach(async () => {
       await clearDatabase();
     });

     it('should register a new user', async () => {
       const res = await request(app)
         .post('/api/auth/register')
         .send()
         .expect(200);

       assert(res.body.userId);
       assert(res.body.token);
       assert.strictEqual(typeof res.body.userId, 'string');
       assert.strictEqual(typeof res.body.token, 'string');
     });

     it('should get user by ID', async () => {
       // First register
       const registerRes = await request(app)
         .post('/api/auth/register')
         .send();

       const { userId, token } = registerRes.body;

       // Then get user
       const res = await request(app)
         .get(`/api/auth/users/${userId}`)
         .set('Authorization', `Bearer ${token}`)
         .expect(200);

       assert.strictEqual(res.body.id, userId);
     });

     it('should require authentication token', async () => {
       await request(app)
         .get('/api/auth/users/test-id')
         .expect(401);
     });

     it('should reject invalid token', async () => {
       await request(app)
         .get('/api/auth/users/test-id')
         .set('Authorization', 'Bearer invalid-token')
         .expect(403);
     });
   });
   ```

3. Create similar test files for:
   - `/home/user/navi/backend/tests/integration/pairing-api.test.js`
   - `/home/user/navi/backend/tests/integration/tap-api.test.js`

4. Test WebSocket integration:
   - `/home/user/navi/backend/tests/integration/websocket.test.js`

5. Install supertest: `npm install --save-dev supertest`

6. Update package.json test script:
   ```json
   "scripts": {
     "test": "node --test tests/**/*.test.js",
     "test:integration": "node --test tests/integration/*.test.js",
     "test:unit": "node --test tests/unit/*.test.js"
   }
   ```

**Success Criteria**:
- ✅ All API endpoints have integration tests
- ✅ Tests cover success and error scenarios
- ✅ Tests use isolated test database
- ✅ Backend test coverage ≥80%
- ✅ All tests passing consistently

---

## Phase 2: Platform Testing (Week 3-5)

### Week 3: iOS & watchOS Testing

#### Task 3.1: iOS TapManager Tests
**Priority**: 🔴 Critical
**Estimated Time**: 6 hours
**Dependencies**: iOS agent cooperation

**Subtasks**:
1. Create `/home/user/navi/Navi_app/Navi_appTests/TapManagerTests.swift` (see iOS action plan for full code)

2. Mock network requests:
   ```swift
   class MockURLSession: URLSession {
       var mockResponse: (Data?, URLResponse?, Error?)?

       override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
           if let error = mockResponse?.2 {
               throw error
           }
           return (mockResponse?.0 ?? Data(), mockResponse?.1 ?? URLResponse())
       }
   }
   ```

3. Test all TapManager methods:
   - `sendTap()`
   - `fetchTapHistory()`
   - `handleIncomingTap()`
   - Haptic patterns

4. Add tests to Xcode test target

5. Verify tests run in CI

**Success Criteria**:
- ✅ TapManager fully tested
- ✅ Network mocking works correctly
- ✅ Tests pass locally and in CI
- ✅ iOS test coverage ≥70%

---

#### Task 3.2: UI Testing Suite
**Priority**: 🟡 High
**Estimated Time**: 8 hours
**Dependencies**: iOS & watchOS UI complete

**Subtasks**:
1. Create UI test target if doesn't exist
2. Add UI tests for iOS:
   ```swift
   import XCTest

   final class NaviUITests: XCTestCase {
       var app: XCUIApplication!

       override func setUp() {
           super.setUp()
           continueAfterFailure = false
           app = XCUIApplication()
           app.launch()
       }

       func testRegistrationFlow() {
           // Test welcome screen → registration
           let getStartedButton = app.buttons["welcomeGetStartedButton"]
           XCTAssertTrue(getStartedButton.exists)
           getStartedButton.tap()

           // Should navigate to pairing screen
           XCTAssertTrue(app.staticTexts["Create or join a pairing"].waitForExistence(timeout: 3))
       }

       func testPairingCodeCreation() {
           // Navigate to pairing
           app.buttons["welcomeGetStartedButton"].tap()

           // Create pairing code
           app.buttons["Create Code"].tap()

           // Verify code displayed
           XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d{6}")).firstMatch.waitForExistence(timeout: 3))
       }

       func testPairingCodeEntry() {
           app.buttons["welcomeGetStartedButton"].tap()
           app.buttons["Join with Code"].tap()

           // Enter 6-digit code
           let codeField = app.textFields.firstMatch
           codeField.tap()
           codeField.typeText("123456")

           // Submit button should be enabled
           XCTAssertTrue(app.buttons["Join"].isEnabled)
       }
   }
   ```

3. Add UI tests for watchOS (if supported by Xcode version)

4. Add to CI pipeline

**Success Criteria**:
- ✅ Critical UI flows tested
- ✅ Tests run in CI on simulators
- ✅ Screenshots generated for failures
- ✅ UI tests catch regression bugs

---

### Week 4-5: End-to-End Testing

#### Task 4.1: Cross-Platform Integration Tests
**Priority**: 🟡 High
**Estimated Time**: 10 hours
**Dependencies**: All agents' integration work complete

**Subtasks**:
1. Create E2E test scenarios:
   - **Scenario 1: Complete Registration & Pairing**
     ```bash
     # iOS User A registers
     # iOS User A creates pairing code
     # iOS User B registers
     # iOS User B joins with code
     # Verify both show as paired
     ```

   - **Scenario 2: Send & Receive Tap**
     ```bash
     # User A sends tap via iOS
     # Verify backend receives tap
     # Verify User B iOS receives push notification
     # Verify User B Watch receives WatchConnectivity message
     # Verify haptic plays
     ```

   - **Scenario 3: Watch to iPhone to Backend**
     ```bash
     # User A sends tap from Watch
     # Watch sends to iPhone via WatchConnectivity
     # iPhone sends to backend
     # Backend delivers to User B
     ```

2. Implement E2E test framework:
   - Option 1: Extend test-api.sh with device orchestration
   - Option 2: Use XCUITest + backend mocks
   - Option 3: Detox or similar E2E framework

3. Automate E2E tests:
   ```yaml
   # .github/workflows/e2e-tests.yml
   name: E2E Tests

   on:
     schedule:
       - cron: '0 0 * * *' # Daily
     workflow_dispatch: # Manual trigger

   jobs:
     e2e:
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v3

         - name: Start Backend
           run: |
             cd backend
             npm install
             npm start &
             sleep 10

         - name: Run E2E Tests
           run: ./scripts/test-e2e.sh
   ```

4. Document E2E test scenarios

**Success Criteria**:
- ✅ Complete user journeys tested end-to-end
- ✅ Cross-platform interactions verified
- ✅ Tests can run automatically
- ✅ Failures provide clear diagnostics

---

## Phase 3: Quality Gates (Week 6-8)

### Week 6-7: Performance & Load Testing

#### Task 5.1: Backend Load Testing
**Priority**: 🟢 Medium
**Estimated Time**: 6 hours
**Dependencies**: Backend stable

**Subtasks**:
1. Install k6: `npm install --save-dev k6`

2. Create `/home/user/navi/backend/tests/load/basic-load.js`:
   ```javascript
   import http from 'k6/http';
   import { check, sleep } from 'k6';

   export let options = {
     stages: [
       { duration: '2m', target: 100 }, // Ramp up to 100 users
       { duration: '5m', target: 100 }, // Stay at 100 users
       { duration: '2m', target: 0 },   // Ramp down to 0 users
     ],
     thresholds: {
       http_req_duration: ['p(95)<500'], // 95% of requests < 500ms
       http_req_failed: ['rate<0.01'],   // < 1% of requests fail
     },
   };

   const BASE_URL = 'https://navi-production.up.railway.app';

   export default function () {
     // Register user
     let registerRes = http.post(`${BASE_URL}/api/auth/register`);
     check(registerRes, {
       'registration successful': (r) => r.status === 200,
     });

     const { userId, token } = registerRes.json();

     // Create pairing code
     let pairingRes = http.post(
       `${BASE_URL}/api/pairing/create`,
       JSON.stringify({ userId }),
       {
         headers: {
           'Authorization': `Bearer ${token}`,
           'Content-Type': 'application/json',
         },
       }
     );
     check(pairingRes, {
       'pairing created': (r) => r.status === 200,
     });

     sleep(1);
   }
   ```

3. Create load test scenarios:
   - Concurrent registrations
   - Concurrent pairing operations
   - High-volume tap sending
   - WebSocket stress test (500 concurrent connections)

4. Run load tests against staging environment

5. Document performance benchmarks

**Success Criteria**:
- ✅ p95 response time < 500ms
- ✅ Support 500 concurrent users
- ✅ Handle 1000 taps/minute
- ✅ Graceful degradation under load
- ✅ No memory leaks detected

---

#### Task 5.2: iOS Performance Testing
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Profile with Instruments:
   - Time Profiler (CPU usage)
   - Allocations (memory usage)
   - Leaks (memory leaks)
   - Energy Log (battery impact)

2. Create performance test cases:
   ```swift
   func testAppLaunchPerformance() {
       measure(metrics: [XCTApplicationLaunchMetric()]) {
           XCUIApplication().launch()
       }
   }

   func testTapSendingPerformance() {
       measure {
           // Send 10 taps
           for _ in 0..<10 {
               tapManager.sendTap(intensity: "medium", pattern: "single")
           }
       }
   }
   ```

3. Set performance baselines

4. Add performance tests to CI

**Success Criteria**:
- ✅ App launch < 2 seconds
- ✅ No memory leaks
- ✅ Smooth 60fps UI
- ✅ Acceptable battery usage

---

### Week 8: Security Testing

#### Task 6.1: Security Test Suite
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Create security test scenarios:
   - SQL injection attempts (when DB implemented)
   - JWT token manipulation
   - Rate limiting bypass attempts
   - CORS violation attempts
   - WebSocket authentication bypass

2. Create `/home/user/navi/backend/tests/security/security.test.js`:
   ```javascript
   describe('Security Tests', () => {
     it('should reject expired JWT tokens', async () => {
       const expiredToken = jwt.sign({ userId: 'test' }, JWT_SECRET, { expiresIn: -1 });

       await request(app)
         .get('/api/auth/users/test')
         .set('Authorization', `Bearer ${expiredToken}`)
         .expect(403);
     });

     it('should enforce rate limiting', async () => {
       // Make 101 requests (limit is 100)
       const requests = Array(101).fill().map(() =>
         request(app).post('/api/auth/register')
       );

       const responses = await Promise.all(requests);
       const tooManyRequests = responses.filter(r => r.status === 429);

       assert(tooManyRequests.length > 0, 'Rate limiting not enforced');
     });

     it('should reject malicious input', async () => {
       await request(app)
         .post('/api/pairing/join')
         .send({ code: "'; DROP TABLE users;--" })
         .expect(400);
     });
   });
   ```

3. Add OWASP dependency check to CI:
   ```yaml
   - name: OWASP Dependency Check
     uses: dependency-check/Dependency-Check_Action@main
     with:
       project: 'Navi'
       path: '.'
       format: 'HTML'
   ```

4. Add secret scanning (TruffleHog already in place)

5. Penetration testing checklist

**Success Criteria**:
- ✅ JWT security verified
- ✅ Rate limiting effective
- ✅ Input validation comprehensive
- ✅ No SQL injection vulnerabilities
- ✅ OWASP dependency check passes

---

## Phase 4: Launch Readiness (Week 9-10)

### Week 9-10: Final QA & Documentation

#### Task 7.1: Regression Testing
**Priority**: 🟡 High
**Estimated Time**: 8 hours

**Subtasks**:
1. Create comprehensive regression test plan:
   - All user flows
   - All API endpoints
   - All error scenarios
   - All platform combinations

2. Manual testing checklist:
   ```markdown
   ## iOS Testing
   - [ ] Registration flow
   - [ ] Pairing code creation
   - [ ] Pairing code joining
   - [ ] Tap sending
   - [ ] Tap receiving with push notification
   - [ ] Unpair flow
   - [ ] Dark mode
   - [ ] Different device sizes (SE, 15, 15 Pro Max)

   ## watchOS Testing
   - [ ] Initial sync from iPhone
   - [ ] Tap sending from Watch
   - [ ] Tap receiving on Watch
   - [ ] Complications on different faces
   - [ ] Different Watch sizes

   ## Backend Testing
   - [ ] All endpoints functional
   - [ ] WebSocket connections stable
   - [ ] Push notifications delivering
   - [ ] Database persistence working
   ```

3. Execute regression tests on staging

4. Document all bugs found

5. Verify all P0/P1 bugs fixed

**Success Criteria**:
- ✅ All manual test cases passing
- ✅ All automated tests passing
- ✅ Zero P0/P1 bugs remaining
- ✅ Regression test suite documented

---

#### Task 7.2: Test Documentation & Training
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Create test documentation:
   - `/home/user/navi/docs/testing/TEST_STRATEGY.md`
   - `/home/user/navi/docs/testing/TEST_PLAN.md`
   - `/home/user/navi/docs/testing/MANUAL_TESTING_CHECKLIST.md`

2. Document test environments:
   - Local testing setup
   - Staging environment
   - Production testing approach

3. Create bug reporting template

4. Train team on:
   - Running tests locally
   - Interpreting CI results
   - Writing new tests
   - Bug triage process

**Success Criteria**:
- ✅ Complete test documentation
- ✅ Team trained on testing practices
- ✅ Clear bug reporting process
- ✅ Test maintenance plan in place

---

## Ongoing Responsibilities

### Daily Tasks
- Monitor CI/CD pipeline status
- Triage new bug reports
- Review test results
- Smoke test new features

### Weekly Tasks
- Run full regression suite
- Review test coverage metrics
- Update test documentation
- Security scan review

### On-Call Duties
- Fix broken CI/CD pipelines
- Investigate test failures
- Coordinate hotfix testing
- Performance monitoring

---

## Key Metrics to Track

### Development Phase
- Test coverage (target: ≥80% backend, ≥70% iOS/watchOS)
- CI pipeline success rate (target: ≥95%)
- Test execution time (target: <10 minutes)
- Bug detection rate (higher is better early on)

### Production Phase
- Crash-free rate (target: ≥99.5%)
- Bug escape rate (target: <5%)
- User-reported bugs (track and trend)
- Performance metrics against benchmarks

---

## Success Criteria Summary

### Phase 1 Complete When:
- ✅ All `continue-on-error` flags removed
- ✅ Backend integration tests ≥80% coverage
- ✅ CI/CD accurately reporting status
- ✅ Test results visible and tracked

### Phase 2 Complete When:
- ✅ iOS TapManager fully tested
- ✅ UI test suite operational
- ✅ E2E tests covering critical flows
- ✅ Cross-platform testing established

### Phase 3 Complete When:
- ✅ Load testing completed
- ✅ Performance benchmarks met
- ✅ Security testing passed
- ✅ Quality gates enforced

### Phase 4 Complete When:
- ✅ Full regression testing passed
- ✅ Documentation complete
- ✅ Team trained
- ✅ Zero critical bugs

---

## Estimated Total Time

- Phase 1: 16 hours (2 weeks @ 8h/week)
- Phase 2: 24 hours (3 weeks @ 8h/week)
- Phase 3: 16 hours (3 weeks @ 5h/week)
- Phase 4: 12 hours (2 weeks @ 6h/week)

**Total**: ~68 hours over 10 weeks

---

**Action Plan Owner**: QA & Testing Lead
**Last Updated**: 2025-11-23
**Next Review**: End of Phase 1 (Week 2)
