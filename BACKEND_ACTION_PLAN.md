# Backend Development Lead - Action Plan
**Agent**: Backend Development Lead
**Domain**: Node.js/Express API, Database, WebSocket, APNs
**Current Status**: 50% Production Ready

---

## Mission Statement
Transform the backend from an in-memory prototype to a production-ready API with persistent storage, push notifications, comprehensive testing, and enterprise-grade error handling.

---

## Phase 1: Critical Blockers (Week 1-2)

### Week 1: Database Persistence

#### Task 1.1: Implement SQLite Database Schema
**Priority**: 🔴 Critical
**Estimated Time**: 8 hours
**Dependencies**: None

**Subtasks**:
1. Create `/home/user/navi/backend/src/db/schema.sql`:
   ```sql
   CREATE TABLE users (
     id TEXT PRIMARY KEY,
     device_token TEXT,
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
   );

   CREATE TABLE pairings (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     user_id_a TEXT NOT NULL,
     user_id_b TEXT NOT NULL,
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (user_id_a) REFERENCES users(id),
     FOREIGN KEY (user_id_b) REFERENCES users(id),
     UNIQUE(user_id_a, user_id_b)
   );

   CREATE TABLE pairing_codes (
     code TEXT PRIMARY KEY,
     creator_id TEXT NOT NULL,
     expires_at DATETIME NOT NULL,
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (creator_id) REFERENCES users(id)
   );

   CREATE TABLE taps (
     id TEXT PRIMARY KEY,
     from_user_id TEXT NOT NULL,
     to_user_id TEXT NOT NULL,
     intensity TEXT NOT NULL,
     pattern TEXT NOT NULL,
     timestamp DATETIME NOT NULL,
     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (from_user_id) REFERENCES users(id),
     FOREIGN KEY (to_user_id) REFERENCES users(id)
   );

   CREATE INDEX idx_pairings_user_a ON pairings(user_id_a);
   CREATE INDEX idx_pairings_user_b ON pairings(user_id_b);
   CREATE INDEX idx_taps_to_user ON taps(to_user_id, timestamp);
   CREATE INDEX idx_pairing_codes_expires ON pairing_codes(expires_at);
   ```

2. Update `/home/user/navi/backend/src/db/init.js`:
   ```javascript
   import sqlite3 from 'sqlite3';
   import { open } from 'sqlite';
   import fs from 'fs';
   import path from 'path';

   let db = null;

   export async function initDatabase() {
     const dbPath = process.env.DATABASE_URL || './data/navi.db';
     const schemaPath = path.join(__dirname, 'schema.sql');

     db = await open({
       filename: dbPath,
       driver: sqlite3.Database
     });

     const schema = fs.readFileSync(schemaPath, 'utf8');
     await db.exec(schema);

     console.log('Database initialized successfully');
     return db;
   }

   export function getDb() {
     if (!db) throw new Error('Database not initialized');
     return db;
   }
   ```

3. Migrate in-memory storage to database:
   - Update `/home/user/navi/backend/src/routes/auth.js` (replace Map with DB queries)
   - Update `/home/user/navi/backend/src/routes/pairing.js` (replace Maps with DB queries)
   - Update `/home/user/navi/backend/src/routes/tap.js` (replace Map with DB queries)

4. Add database cleanup cron for expired pairing codes

**Success Criteria**:
- ✅ Database file persists at `/app/data/navi.db`
- ✅ All API endpoints use database instead of in-memory storage
- ✅ Data survives server restart
- ✅ Existing test-api.sh passes with database

**Testing**:
```bash
# Test persistence
./scripts/test-api.sh -q
# Restart server
# Re-run tests - data should still exist
./scripts/test-api.sh -q
```

---

#### Task 1.2: Fix Security Vulnerabilities
**Priority**: 🔴 Critical
**Estimated Time**: 2 hours
**Dependencies**: None

**Subtasks**:
1. Run `npm audit fix` in backend directory
2. Force update jsonwebtoken: `npm install jsonwebtoken@latest`
3. Remove hardcoded JWT_SECRET fallbacks:
   - `/home/user/navi/backend/src/routes/auth.js:6`
   - `/home/user/navi/backend/src/middleware/auth.js:3`
   - `/home/user/navi/backend/src/services/websocket.js:4`

   Replace with:
   ```javascript
   const JWT_SECRET = process.env.JWT_SECRET;
   if (!JWT_SECRET && process.env.NODE_ENV === 'production') {
     throw new Error('JWT_SECRET must be set in production');
   }
   ```

4. Update Railway environment variables to include strong JWT_SECRET

**Success Criteria**:
- ✅ `npm audit` shows 0 high/critical vulnerabilities
- ✅ Server fails to start if JWT_SECRET missing in production
- ✅ All existing tests still pass

---

### Week 2: APNs Foundation

#### Task 2.1: APNs Setup and Configuration
**Priority**: 🔴 Critical
**Estimated Time**: 6 hours
**Dependencies**: Database implementation

**Subtasks**:
1. Obtain APNs certificate from Apple Developer Portal:
   - Create APNs Authentication Key (.p8 file)
   - Note Key ID, Team ID, Bundle ID
   - Store in `backend/certs/` (gitignored)

2. Update `/home/user/navi/backend/src/services/apns.js`:
   ```javascript
   import apn from 'apn';
   import fs from 'fs';

   let apnProvider = null;

   export function initAPNs() {
     if (process.env.NODE_ENV === 'test') {
       console.log('APNs initialized (mock for test environment)');
       return;
     }

     const options = {
       token: {
         key: fs.readFileSync(process.env.APNS_KEY_PATH),
         keyId: process.env.APNS_KEY_ID,
         teamId: process.env.APNS_TEAM_ID
       },
       production: process.env.NODE_ENV === 'production'
     };

     apnProvider = new apn.Provider(options);
     console.log('APNs initialized successfully');
   }

   export async function sendPushNotification(deviceToken, payload) {
     if (!apnProvider) {
       console.warn('APNs not initialized, skipping notification');
       return { success: false, reason: 'provider_not_initialized' };
     }

     const notification = new apn.Notification({
       alert: {
         title: payload.title || 'Tap Received',
         body: payload.message
       },
       topic: process.env.APNS_BUNDLE_ID,
       payload: {
         type: 'tap',
         data: payload
       },
       sound: 'default',
       badge: 1
     });

     try {
       const result = await apnProvider.send(notification, deviceToken);
       console.log('Push notification sent:', result);
       return { success: true, result };
     } catch (error) {
       console.error('Push notification failed:', error);
       return { success: false, error: error.message };
     }
   }

   export async function closeAPNs() {
     if (apnProvider) {
       await apnProvider.shutdown();
     }
   }
   ```

3. Update environment variables:
   ```env
   APNS_KEY_ID=ABC123XYZ
   APNS_TEAM_ID=DEF456UVW
   APNS_BUNDLE_ID=Rosenbaum.Navi-app
   APNS_KEY_PATH=./certs/AuthKey_ABC123XYZ.p8
   ```

4. Update tap sending to include APNs fallback:
   ```javascript
   // In /home/user/navi/backend/src/routes/tap.js
   // After WebSocket attempt, add:
   if (!wsDelivered) {
     const user = await db.get('SELECT device_token FROM users WHERE id = ?', toUserId);
     if (user?.device_token) {
       await sendPushNotification(user.device_token, {
         message: `You received a ${intensity} ${pattern} tap`,
         fromUserId,
         intensity,
         pattern
       });
     }
   }
   ```

**Success Criteria**:
- ✅ APNs provider initializes without errors
- ✅ Push notifications sent when WebSocket unavailable
- ✅ Delivery status logged and tracked
- ✅ Certificate errors handled gracefully

**Testing**:
- Test with physical iOS device (simulator won't work for APNs)
- Disconnect WebSocket, send tap, verify push received

---

## Phase 2: Core Features (Week 3-5)

### Week 3: Enhanced Error Handling and Logging

#### Task 3.1: Implement Structured Logging
**Priority**: 🟡 High
**Estimated Time**: 4 hours

**Subtasks**:
1. Install Winston: `npm install winston`

2. Create `/home/user/navi/backend/src/utils/logger.js`:
   ```javascript
   import winston from 'winston';

   const logger = winston.createLogger({
     level: process.env.LOG_LEVEL || 'info',
     format: winston.format.combine(
       winston.format.timestamp(),
       winston.format.errors({ stack: true }),
       winston.format.json()
     ),
     defaultMeta: { service: 'navi-backend' },
     transports: [
       new winston.transports.Console({
         format: winston.format.combine(
           winston.format.colorize(),
           winston.format.simple()
         )
       }),
       new winston.transports.File({
         filename: 'logs/error.log',
         level: 'error'
       }),
       new winston.transports.File({
         filename: 'logs/combined.log'
       })
     ]
   });

   export default logger;
   ```

3. Replace all `console.log` and `console.error` calls with logger:
   - `console.log()` → `logger.info()`
   - `console.error()` → `logger.error()`
   - Add request IDs to track requests across logs

4. Add request logging middleware using morgan

**Success Criteria**:
- ✅ All logs structured as JSON
- ✅ Error logs include stack traces
- ✅ Request logs include timing and status codes
- ✅ No more console.log calls in production code

---

#### Task 3.2: Improve Error Response Format
**Priority**: 🟡 High
**Estimated Time**: 3 hours

**Subtasks**:
1. Create standardized error response format:
   ```javascript
   // /home/user/navi/backend/src/utils/errors.js
   export class ApiError extends Error {
     constructor(statusCode, code, message, details = null) {
       super(message);
       this.statusCode = statusCode;
       this.code = code;
       this.details = details;
     }
   }

   export const ErrorCodes = {
     INVALID_TOKEN: 'INVALID_TOKEN',
     PAIRING_EXPIRED: 'PAIRING_EXPIRED',
     PAIRING_NOT_FOUND: 'PAIRING_NOT_FOUND',
     USER_NOT_FOUND: 'USER_NOT_FOUND',
     INVALID_INPUT: 'INVALID_INPUT',
     INTERNAL_ERROR: 'INTERNAL_ERROR'
   };
   ```

2. Update error handler middleware to use new format
3. Update all route handlers to throw ApiError instances
4. Document error codes in API_DOCUMENTATION.md

**Success Criteria**:
- ✅ All errors follow consistent format
- ✅ Error codes documented
- ✅ Client can programmatically handle errors

---

### Week 4-5: Testing and Performance

#### Task 4.1: Comprehensive Backend Tests
**Priority**: 🟡 High
**Estimated Time**: 12 hours

**Subtasks**:
1. Create test suite structure:
   ```
   backend/tests/
   ├── unit/
   │   ├── auth.test.js
   │   ├── pairing-logic.test.js
   │   ├── tap-validation.test.js
   │   └── websocket.test.js
   ├── integration/
   │   ├── auth-api.test.js
   │   ├── pairing-api.test.js
   │   ├── tap-api.test.js
   │   └── websocket-integration.test.js
   └── helpers/
       ├── test-db.js
       └── test-server.js
   ```

2. Write unit tests for:
   - JWT token generation and validation
   - Pairing code generation and expiration
   - Tap validation (intensity, pattern)
   - WebSocket message handling

3. Write integration tests for:
   - Complete auth flow
   - Complete pairing flow
   - Complete tap sending flow
   - WebSocket authentication and messaging

4. Add test coverage reporting with c8

**Success Criteria**:
- ✅ Test coverage ≥80%
- ✅ All critical paths tested
- ✅ CI runs tests on every commit
- ✅ Tests run in isolated test database

---

#### Task 4.2: Performance Optimization
**Priority**: 🟢 Medium
**Estimated Time**: 6 hours

**Subtasks**:
1. Add database indexes (already in schema)
2. Implement caching for frequently accessed data:
   - Cache user pairings (5 minute TTL)
   - Cache pairing status lookups
3. Add request timeout middleware (30s default)
4. Optimize WebSocket connection management
5. Add connection pooling for database

**Success Criteria**:
- ✅ API response times <200ms (p95)
- ✅ Support 100 concurrent WebSocket connections
- ✅ Database queries optimized with EXPLAIN

---

## Phase 3: Production Readiness (Week 6-8)

### Week 6-7: Monitoring and Observability

#### Task 5.1: Add Error Tracking
**Priority**: 🟡 High
**Estimated Time**: 3 hours

**Subtasks**:
1. Install Sentry: `npm install @sentry/node`
2. Initialize Sentry in index.js
3. Add Sentry error handler middleware
4. Configure source maps for stack traces
5. Set up error alerting rules

**Success Criteria**:
- ✅ All errors tracked in Sentry
- ✅ Stack traces include source file references
- ✅ Alerts sent for critical errors

---

#### Task 5.2: Add Health Check Enhancements
**Priority**: 🟢 Medium
**Estimated Time**: 2 hours

**Subtasks**:
1. Enhance `/health` endpoint:
   ```javascript
   app.get('/health', async (req, res) => {
     const checks = {
       database: await checkDatabase(),
       websocket: checkWebSocketServer(),
       apns: checkAPNsProvider()
     };

     const healthy = Object.values(checks).every(c => c.status === 'ok');

     res.status(healthy ? 200 : 503).json({
       status: healthy ? 'ok' : 'degraded',
       timestamp: new Date().toISOString(),
       uptime: process.uptime(),
       checks
     });
   });
   ```

2. Add separate liveness and readiness endpoints
3. Add metrics endpoint for Prometheus scraping

**Success Criteria**:
- ✅ Health check detects database failures
- ✅ Health check detects APNs issues
- ✅ Railway health checks use enhanced endpoint

---

### Week 8: Documentation and Cleanup

#### Task 6.1: Update API Documentation
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Update API_DOCUMENTATION.md with:
   - New error codes and formats
   - Database persistence notes
   - APNs integration details
   - Rate limiting specifics
2. Add OpenAPI/Swagger spec
3. Add example requests/responses for all endpoints
4. Document WebSocket message protocol completely

**Success Criteria**:
- ✅ Documentation matches implementation
- ✅ All endpoints documented
- ✅ Error codes documented

---

## Phase 4: Launch Preparation (Week 9-10)

### Week 9-10: Final Polish

#### Task 7.1: Security Audit and Hardening
**Priority**: 🟡 High
**Estimated Time**: 4 hours

**Subtasks**:
1. Run OWASP dependency check
2. Review and tighten CORS settings
3. Add rate limiting per-endpoint customization
4. Review and update helmet configuration
5. Implement request size limits
6. Add SQL injection prevention review

**Success Criteria**:
- ✅ Zero high/critical security issues
- ✅ Security headers optimized
- ✅ Rate limits appropriate per endpoint

---

#### Task 7.2: Load Testing
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Create load test scenarios with k6 or Artillery
2. Test scenarios:
   - 100 concurrent users registering
   - 50 concurrent pairing operations
   - 1000 taps/minute
   - 500 concurrent WebSocket connections
3. Identify bottlenecks
4. Optimize as needed

**Success Criteria**:
- ✅ Support 500 concurrent users
- ✅ Handle 1000 taps/minute
- ✅ 99th percentile response time <500ms

---

## Ongoing Responsibilities

### Daily Tasks
- Monitor error logs and Sentry alerts
- Review and merge PRs from other agents
- Respond to backend-related questions

### Weekly Tasks
- Review database performance metrics
- Check for new security vulnerabilities
- Update dependency versions (minor updates)

### On-Call Duties
- Respond to production incidents
- Database backup verification
- Performance monitoring

---

## Key Metrics to Track

### Development Phase
- Test coverage percentage (target: ≥80%)
- API response times (target: p95 <200ms)
- Database query times (target: <50ms)
- Code review turnaround (target: <4 hours)

### Production Phase
- Error rate (target: <0.1%)
- API uptime (target: 99.9%)
- WebSocket connection success rate (target: >95%)
- Push notification delivery rate (target: >90%)
- Database size growth rate

---

## Dependencies on Other Agents

### From iOS Agent
- Device token format validation
- APNs payload format requirements
- Error message user-facing text

### From watchOS Agent
- WebSocket message format requirements
- Haptic intensity/pattern specifications

### From Integration Agent
- Correct backend URL endpoints
- Shared data model validation
- API contract verification

### From QA Agent
- Test scenarios and edge cases
- Performance benchmarks
- Bug reports and reproduction steps

### From DevOps Agent
- Railway deployment configuration
- Environment variable setup
- Database backup procedures

---

## Success Criteria for Backend Domain

### Phase 1 Complete When:
- ✅ Database persistence implemented and tested
- ✅ Security vulnerabilities resolved
- ✅ APNs foundation configured
- ✅ All data survives server restart

### Phase 2 Complete When:
- ✅ Structured logging implemented
- ✅ Error handling standardized
- ✅ Test coverage ≥80%
- ✅ Performance optimizations complete

### Phase 3 Complete When:
- ✅ Error tracking operational
- ✅ Enhanced health checks deployed
- ✅ Documentation up to date
- ✅ Monitoring dashboards created

### Phase 4 Complete When:
- ✅ Security audit passed
- ✅ Load testing successful
- ✅ Production deployment verified
- ✅ Team trained on operations

---

## Estimated Total Time

- Phase 1: 16 hours (2 weeks @ 8h/week)
- Phase 2: 25 hours (3 weeks @ 8h/week)
- Phase 3: 9 hours (3 weeks @ 3h/week)
- Phase 4: 8 hours (2 weeks @ 4h/week)

**Total**: ~58 hours over 10 weeks

---

## Resources Needed

### Tools
- SQLite browser (for database inspection)
- Postman/Insomnia (for API testing)
- Apple Developer Account (for APNs certificates)
- Sentry account (for error tracking)

### Documentation
- Node.js best practices
- SQLite documentation
- APNs documentation
- WebSocket protocol specs

### Support
- iOS agent for APNs payload testing
- DevOps agent for Railway configuration
- QA agent for test scenario definition

---

## Risk Mitigation

### Risk: Database migration breaks existing data
**Mitigation**: No production data exists yet; clean slate migration

### Risk: APNs certificate configuration errors
**Mitigation**: Test in sandbox first; comprehensive documentation

### Risk: Performance degrades with database
**Mitigation**: Proper indexing; connection pooling; caching strategy

### Risk: WebSocket scaling issues
**Mitigation**: Design for horizontal scaling; Redis pub/sub if needed

---

**Action Plan Owner**: Backend Development Lead
**Last Updated**: 2025-11-23
**Next Review**: End of Phase 1 (Week 2)
