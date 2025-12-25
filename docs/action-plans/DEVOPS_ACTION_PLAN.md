# DevOps & Infrastructure Lead - Action Plan
**Agent**: DevOps & Infrastructure Lead
**Domain**: Deployment, Infrastructure, Monitoring, CI/CD
**Current Status**: 56% Infrastructure Maturity

---

## Mission Statement
Transform the infrastructure from a minimal deployment setup into a production-ready, observable, scalable system with proper monitoring, logging, backup strategies, and disaster recovery capabilities.

---

## Phase 1: Foundation Hardening (Week 1-2)

### Week 1: Logging & Monitoring Foundation

#### Task 1.1: Implement Structured Logging
**Priority**: 🔴 Critical
**Estimated Time**: 4 hours
**Dependencies**: Backend agent Winston implementation

**Subtasks**:
1. Coordinate with Backend agent on Winston setup (they own implementation)

2. Configure log aggregation in Railway:
   ```bash
   # Railway automatically captures stdout/stderr
   # Ensure JSON format for parsing
   ```

3. Create log parsing and alerting:
   - Set up log queries for errors
   - Configure alerts for critical errors
   - Set up daily log summaries

4. Document logging standards:
   ```markdown
   # Logging Standards

   ## Log Levels
   - ERROR: System failures requiring immediate attention
   - WARN: Degraded functionality, should be investigated
   - INFO: Normal operations, major state changes
   - DEBUG: Detailed debugging info (dev only)

   ## Log Format
   {
     "timestamp": "ISO8601",
     "level": "ERROR|WARN|INFO|DEBUG",
     "service": "backend|ios|watch",
     "message": "Human readable message",
     "context": {
       "userId": "...",
       "requestId": "...",
       "endpoint": "..."
     },
     "error": {
       "message": "...",
       "stack": "..."
     }
   }
   ```

**Success Criteria**:
- ✅ All logs structured as JSON
- ✅ Log levels used appropriately
- ✅ Errors automatically captured
- ✅ Logging documentation complete

---

#### Task 1.2: Set Up Error Tracking
**Priority**: 🔴 Critical
**Estimated Time**: 3 hours
**Dependencies**: None

**Subtasks**:
1. Create Sentry account (free tier sufficient to start)

2. Add Sentry to backend (coordinate with Backend agent):
   ```bash
   npm install @sentry/node
   ```

3. Configure Sentry in Railway:
   ```env
   SENTRY_DSN=https://...@sentry.io/...
   SENTRY_ENVIRONMENT=production
   SENTRY_RELEASE=<git-sha>
   ```

4. Set up Sentry alerts:
   - Email on new errors
   - Slack notifications for critical errors
   - Daily digest of error trends

5. Add source maps for better stack traces:
   ```yaml
   # .github/workflows/deploy.yml
   - name: Upload Source Maps to Sentry
     run: |
       npx @sentry/cli releases files $RELEASE upload-sourcemaps ./dist
   ```

6. Configure iOS crash reporting:
   ```swift
   // In iOS app
   import Sentry

   SentrySDK.start { options in
       options.dsn = "https://...@sentry.io/..."
       options.environment = "production"
   }
   ```

**Success Criteria**:
- ✅ Backend errors tracked in Sentry
- ✅ iOS crashes tracked in Sentry
- ✅ Alerts configured and tested
- ✅ Source maps working (readable stack traces)
- ✅ Team trained on Sentry UI

---

### Week 2: Production Database & Backups

#### Task 2.1: Database Backup Strategy
**Priority**: 🔴 Critical
**Estimated Time**: 6 hours
**Dependencies**: Backend database implementation

**Subtasks**:
1. Create backup script `/home/user/navi/scripts/backup-database.sh`:
   ```bash
   #!/bin/bash
   set -e

   BACKUP_DIR="/app/backups"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   DB_PATH="${DATABASE_URL:-/app/data/navi.db}"
   BACKUP_FILE="$BACKUP_DIR/navi_$TIMESTAMP.db"

   echo "Starting database backup..."

   # Create backup directory
   mkdir -p "$BACKUP_DIR"

   # SQLite backup
   sqlite3 "$DB_PATH" ".backup '$BACKUP_FILE'"

   # Compress
   gzip "$BACKUP_FILE"

   echo "Backup created: ${BACKUP_FILE}.gz"

   # Upload to Railway volume (persistent storage)
   if [ -n "$RAILWAY_VOLUME_MOUNT_PATH" ]; then
       cp "${BACKUP_FILE}.gz" "$RAILWAY_VOLUME_MOUNT_PATH/"
       echo "Backup uploaded to Railway volume"
   fi

   # Cleanup old backups (keep last 30 days)
   find "$BACKUP_DIR" -name "navi_*.db.gz" -mtime +30 -delete
   echo "Old backups cleaned up"

   # Verify backup
   if gunzip -t "${BACKUP_FILE}.gz"; then
       echo "Backup verified successfully"
   else
       echo "ERROR: Backup verification failed!"
       exit 1
   fi
   ```

2. Make script executable:
   ```bash
   chmod +x scripts/backup-database.sh
   ```

3. Configure Railway persistent storage:
   ```json
   // railway.json
   {
     "volumes": [
       {
         "mountPath": "/app/data",
         "name": "navi-database"
       },
       {
         "mountPath": "/app/backups",
         "name": "navi-backups"
       }
     ]
   }
   ```

4. Add cron job for automated backups:
   ```bash
   # Add to Railway startup script
   echo "0 2 * * * /app/scripts/backup-database.sh" | crontab -
   ```

   OR use GitHub Actions:
   ```yaml
   # .github/workflows/backup.yml
   name: Database Backup

   on:
     schedule:
       - cron: '0 2 * * *' # Daily at 2 AM UTC
     workflow_dispatch:

   jobs:
     backup:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3

         - name: Trigger Backup
           run: |
             railway run --service backend ./scripts/backup-database.sh
           env:
             RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
   ```

5. Create restore script `/home/user/navi/scripts/restore-database.sh`:
   ```bash
   #!/bin/bash
   set -e

   if [ -z "$1" ]; then
       echo "Usage: ./restore-database.sh <backup-file.gz>"
       exit 1
   fi

   BACKUP_FILE="$1"
   DB_PATH="${DATABASE_URL:-/app/data/navi.db}"

   echo "WARNING: This will replace the current database!"
   read -p "Are you sure? (yes/no): " confirm

   if [ "$confirm" != "yes" ]; then
       echo "Restore cancelled"
       exit 0
   fi

   # Stop the application
   echo "Stopping application..."
   railway down

   # Backup current database first
   echo "Creating safety backup of current database..."
   sqlite3 "$DB_PATH" ".backup '${DB_PATH}.pre-restore'"

   # Restore from backup
   echo "Restoring from $BACKUP_FILE..."
   gunzip -c "$BACKUP_FILE" > "$DB_PATH"

   # Verify
   if sqlite3 "$DB_PATH" "PRAGMA integrity_check;"; then
       echo "Database restored and verified successfully"
       echo "Restarting application..."
       railway up
   else
       echo "ERROR: Database integrity check failed!"
       echo "Restoring previous database..."
       mv "${DB_PATH}.pre-restore" "$DB_PATH"
       railway up
       exit 1
   fi
   ```

6. Test backup and restore procedures

7. Document disaster recovery runbook

**Success Criteria**:
- ✅ Daily automated backups running
- ✅ Backups stored in persistent volume
- ✅ Restore procedure tested and documented
- ✅ 30-day backup retention implemented
- ✅ Backup verification automated

---

## Phase 2: Production Infrastructure (Week 3-5)

### Week 3: Monitoring & Alerting

#### Task 3.1: Health Monitoring System
**Priority**: 🟡 High
**Estimated Time**: 4 hours
**Dependencies**: Backend health endpoint enhancements

**Subtasks**:
1. Deploy monitoring script permanently:
   ```yaml
   # Deploy monitor-health.sh to separate Railway service
   # OR use external monitoring service (UptimeRobot, Pingdom)
   ```

2. Configure UptimeRobot (free tier):
   - Monitor: https://navi-production.up.railway.app/health
   - Interval: 5 minutes
   - Alerts: Email + Slack
   - Expected keyword: "ok"

3. Set up custom monitoring dashboard:
   ```bash
   # Create lightweight monitoring service
   # OR use Railway's built-in metrics
   ```

4. Configure alerting rules:
   - Health check fails: Immediate alert
   - Response time > 1s: Warning alert
   - Error rate > 5%: Critical alert
   - Database size > 80% capacity: Warning

5. Create on-call rotation schedule

**Success Criteria**:
- ✅ 24/7 uptime monitoring active
- ✅ Alerts delivered reliably
- ✅ Response time tracked
- ✅ False positive rate < 1%
- ✅ On-call schedule defined

---

#### Task 3.2: Application Performance Monitoring
**Priority**: 🟡 High
**Estimated Time**: 4 hours

**Subtasks**:
1. Evaluate APM options:
   - New Relic (free tier available)
   - Datadog (free trial)
   - Railway built-in metrics

2. Implement chosen APM (recommend New Relic):
   ```bash
   npm install newrelic
   ```

   ```javascript
   // backend/src/index.js
   import newrelic from 'newrelic';
   ```

   ```env
   NEW_RELIC_LICENSE_KEY=...
   NEW_RELIC_APP_NAME=Navi Backend
   ```

3. Configure custom metrics:
   - Tap delivery success rate
   - WebSocket connection count
   - Active user count
   - Pairing success rate

4. Create dashboards:
   - System health overview
   - API performance
   - User activity metrics
   - Error trends

5. Set up anomaly detection alerts

**Success Criteria**:
- ✅ APM collecting metrics
- ✅ Dashboards created and accessible
- ✅ Custom business metrics tracked
- ✅ Anomaly detection working
- ✅ Team trained on APM usage

---

### Week 4-5: Scalability & Reliability

#### Task 4.1: Infrastructure Scaling Preparation
**Priority**: 🟢 Medium
**Estimated Time**: 6 hours

**Subtasks**:
1. Update Railway configuration for scaling:
   ```json
   // railway.json
   {
     "deploy": {
       "numReplicas": 2, // Increase from 1
       "strategy": "rolling",
       "healthCheck": {
         "path": "/health",
         "port": 3000,
         "initialDelaySeconds": 30,
         "periodSeconds": 10
       }
     }
   }
   ```

2. Implement Redis for distributed state:
   ```bash
   # Add Redis service in Railway
   npm install ioredis
   ```

   ```javascript
   // Distributed rate limiting
   import RedisStore from 'rate-limit-redis';
   import Redis from 'ioredis';

   const client = new Redis(process.env.REDIS_URL);

   const limiter = rateLimit({
     store: new RedisStore({ client }),
     windowMs: 15 * 60 * 1000,
     max: 100
   });
   ```

3. Configure Redis for:
   - Rate limiting (distributed)
   - Session storage
   - WebSocket pub/sub (for multi-instance)
   - Cache layer

4. Implement WebSocket scaling strategy:
   ```javascript
   // Use Redis pub/sub for WebSocket broadcasting
   import { createAdapter } from '@socket.io/redis-adapter';

   const pubClient = new Redis(process.env.REDIS_URL);
   const subClient = pubClient.duplicate();

   io.adapter(createAdapter(pubClient, subClient));
   ```

5. Test with 2 replicas:
   - Verify load balancing
   - Verify WebSocket sticky sessions
   - Verify Redis state sharing

**Success Criteria**:
- ✅ Can scale to 2+ replicas
- ✅ Redis integrated for distributed state
- ✅ WebSocket works across replicas
- ✅ No single point of failure
- ✅ Load balancing verified

---

#### Task 4.2: Staging Environment
**Priority**: 🟡 High
**Estimated Time**: 4 hours

**Subtasks**:
1. Create staging Railway project:
   ```bash
   railway init --name navi-staging
   ```

2. Deploy backend to staging:
   ```yaml
   # .github/workflows/deploy-staging.yml
   name: Deploy Staging

   on:
     push:
       branches: [ develop ]

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3

         - name: Deploy to Railway Staging
           run: |
             cd backend
             railway up --service backend --environment staging
           env:
             RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN_STAGING }}
   ```

3. Configure staging environment variables:
   ```env
   NODE_ENV=staging
   DATABASE_URL=/app/data/navi-staging.db
   JWT_SECRET=<different-from-prod>
   ```

4. Set up staging iOS build:
   ```yaml
   # Xcode scheme for staging
   # Different bundle ID: Rosenbaum.Navi-app.staging
   # Different API URL
   ```

5. Document staging deployment process

**Success Criteria**:
- ✅ Staging environment operational
- ✅ Auto-deploys from develop branch
- ✅ Separate from production data
- ✅ iOS can target staging backend
- ✅ Team uses staging for testing

---

## Phase 3: Security & Compliance (Week 6-8)

### Week 6-7: Security Hardening

#### Task 5.1: SSL/TLS Configuration
**Priority**: 🟢 Medium
**Estimated Time**: 3 hours

**Subtasks**:
1. Railway provides SSL automatically, but enhance security headers:
   ```javascript
   // backend/src/index.js
   app.use(helmet({
     hsts: {
       maxAge: 31536000,
       includeSubDomains: true,
       preload: true
     },
     contentSecurityPolicy: {
       directives: {
         defaultSrc: ["'self'"],
         styleSrc: ["'self'", "'unsafe-inline'"],
         scriptSrc: ["'self'"],
         imgSrc: ["'self'", "data:", "https:"],
       }
     }
   }));
   ```

2. Implement custom domain (optional):
   - Register domain (e.g., api.navi.app)
   - Configure in Railway
   - Set up SSL certificate (automatic via Railway)

3. Force HTTPS redirect:
   ```javascript
   app.use((req, res, next) => {
     if (req.header('x-forwarded-proto') !== 'https' && process.env.NODE_ENV === 'production') {
       res.redirect(`https://${req.header('host')}${req.url}`);
     } else {
       next();
     }
   });
   ```

4. Configure CORS properly:
   ```javascript
   const allowedOrigins = [
     'https://navi-production.up.railway.app',
     process.env.CUSTOM_DOMAIN
   ].filter(Boolean);

   app.use(cors({
     origin: (origin, callback) => {
       if (!origin || allowedOrigins.includes(origin)) {
         callback(null, true);
       } else {
         callback(new Error('Not allowed by CORS'));
       }
     },
     credentials: true
   }));
   ```

**Success Criteria**:
- ✅ HTTPS enforced
- ✅ Security headers configured
- ✅ CORS properly restricted
- ✅ SSL Labs A+ rating

---

#### Task 5.2: Secrets Management
**Priority**: 🟡 High
**Estimated Time**: 3 hours

**Subtasks**:
1. Audit all secrets:
   - JWT_SECRET
   - APNS certificates
   - Database credentials (future)
   - API keys
   - Railway tokens

2. Document secrets in password manager (1Password, LastPass)

3. Implement secret rotation policy:
   ```markdown
   # Secret Rotation Schedule
   - JWT_SECRET: Every 90 days
   - APNS certificates: Before expiry (1 year)
   - Railway tokens: Every 180 days
   - Database passwords: Every 90 days
   ```

4. Create secret rotation procedure:
   ```bash
   # scripts/rotate-jwt-secret.sh
   #!/bin/bash

   # Generate new secret
   NEW_SECRET=$(openssl rand -base64 32)

   # Update Railway
   railway variables set JWT_SECRET="$NEW_SECRET"

   # Deploy
   railway up

   echo "JWT_SECRET rotated successfully"
   ```

5. Set calendar reminders for rotation

**Success Criteria**:
- ✅ All secrets documented
- ✅ Secrets stored securely
- ✅ Rotation policy defined
- ✅ Rotation procedures tested

---

### Week 8: Docker & Deployment Optimization

#### Task 6.1: Docker Optimization
**Priority**: 🟢 Medium
**Estimated Time**: 3 hours

**Subtasks**:
1. Create `.dockerignore`:
   ```
   node_modules
   npm-debug.log*
   .env
   .env.*
   *.md
   .git
   .github
   tests/
   coverage/
   .DS_Store
   ```

2. Optimize Dockerfile:
   ```dockerfile
   FROM node:18-alpine AS base

   # Install dependencies
   FROM base AS dependencies
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production

   # Build stage
   FROM base AS build
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build # if applicable

   # Production stage
   FROM base AS production
   WORKDIR /app

   # Create non-root user
   RUN addgroup -g 1001 -S nodejs && \
       adduser -S nodejs -u 1001

   # Copy dependencies
   COPY --from=dependencies /app/node_modules ./node_modules
   COPY --from=build /app/dist ./dist
   COPY package*.json ./

   # Create data directory
   RUN mkdir -p data && chown nodejs:nodejs data

   # Switch to non-root user
   USER nodejs

   EXPOSE 3000

   # Health check
   HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
     CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); })"

   CMD ["npm", "start"]
   ```

3. Test Docker build locally:
   ```bash
   docker build -t navi-backend .
   docker run -p 3000:3000 navi-backend
   ```

4. Measure image size reduction

**Success Criteria**:
- ✅ Docker image < 150MB
- ✅ Non-root user implemented
- ✅ Health check in Dockerfile
- ✅ Build time < 2 minutes
- ✅ .dockerignore prevents sensitive files

---

## Phase 4: Operational Excellence (Week 9-10)

### Week 9-10: Documentation & Runbooks

#### Task 7.1: Infrastructure Documentation
**Priority**: 🟡 High
**Estimated Time**: 6 hours

**Subtasks**:
1. Create `/home/user/navi/docs/infrastructure/ARCHITECTURE.md`:
   ```markdown
   # Infrastructure Architecture

   ## Overview
   - Platform: Railway
   - Region: US-West
   - Backend: Node.js (Express)
   - Database: SQLite
   - Cache: Redis
   - Monitoring: Sentry + New Relic
   - CI/CD: GitHub Actions

   ## Components
   [Diagrams and descriptions]

   ## Environments
   - Production: navi-production
   - Staging: navi-staging
   - Development: Local

   ## Scaling Strategy
   [Horizontal scaling details]

   ## Disaster Recovery
   [DR procedures]
   ```

2. Create operational runbooks:
   - `/home/user/navi/docs/runbooks/DEPLOYMENT.md`
   - `/home/user/navi/docs/runbooks/INCIDENT_RESPONSE.md`
   - `/home/user/navi/docs/runbooks/DATABASE_OPERATIONS.md`
   - `/home/user/navi/docs/runbooks/ROLLBACK.md`

3. Document common operations:
   ```markdown
   # Common Operations

   ## Deploy to Production
   1. Merge PR to main
   2. CI runs tests
   3. Automatic deployment to Railway
   4. Health check verification
   5. Monitor error rates

   ## Rollback Deployment
   1. Identify bad deployment SHA
   2. Run: railway rollback --service backend
   3. Verify health check
   4. Notify team

   ## Scale Up
   1. Update railway.json: numReplicas
   2. Deploy changes
   3. Monitor load distribution

   ## Restore from Backup
   1. Stop application
   2. Run: ./scripts/restore-database.sh <backup-file>
   3. Verify data integrity
   4. Restart application
   ```

4. Create troubleshooting guide:
   ```markdown
   # Troubleshooting Guide

   ## Backend Not Responding
   1. Check Railway status
   2. Check logs: railway logs --service backend
   3. Check health endpoint
   4. Check database connection
   5. Restart if needed: railway restart

   ## High Error Rate
   1. Check Sentry for errors
   2. Check recent deployments
   3. Check database performance
   4. Consider rollback

   ## Database Full
   1. Check database size
   2. Run cleanup scripts
   3. Archive old data
   4. Consider migration to PostgreSQL
   ```

5. Create on-call handbook

**Success Criteria**:
- ✅ Complete infrastructure docs
- ✅ All runbooks created and tested
- ✅ Troubleshooting guide comprehensive
- ✅ Team trained on operations
- ✅ On-call procedures defined

---

#### Task 7.2: Monitoring Dashboard & Alerts Setup
**Priority**: 🟢 Medium
**Estimated Time**: 4 hours

**Subtasks**:
1. Create unified monitoring dashboard:
   - System health (CPU, memory, disk)
   - Application metrics (requests/sec, errors)
   - Business metrics (active users, taps sent)
   - Database metrics (connections, queries)

2. Configure alert thresholds:
   ```yaml
   alerts:
     critical:
       - service_down: immediate
       - error_rate > 10%: immediate
       - database_full > 95%: immediate

     warning:
       - response_time > 1s: 5 minutes
       - memory_usage > 80%: 15 minutes
       - error_rate > 5%: 10 minutes

     info:
       - deployment_started: immediate
       - deployment_completed: immediate
       - backup_completed: daily
   ```

3. Set up Slack integration for alerts

4. Create daily status report automation

5. Test all alert scenarios

**Success Criteria**:
- ✅ Unified dashboard accessible to team
- ✅ Alerts reliable and actionable
- ✅ False positive rate < 5%
- ✅ Alert fatigue avoided
- ✅ Daily reports automated

---

## Ongoing Responsibilities

### Daily Tasks
- Review monitoring dashboards
- Check backup success
- Review error rates in Sentry
- Monitor deployment pipeline
- Respond to alerts

### Weekly Tasks
- Review capacity metrics
- Update dependencies
- Review security scan results
- Test disaster recovery procedures
- Update documentation

### Monthly Tasks
- Review costs and optimize
- Conduct infrastructure health check
- Review and update runbooks
- Team training sessions
- Rotate secrets (if due)

---

## Key Metrics to Track

### Infrastructure Metrics
- Uptime (target: 99.9%)
- Response time p95 (target: <500ms)
- Error rate (target: <0.1%)
- CPU usage (target: <70%)
- Memory usage (target: <80%)

### Operational Metrics
- Deployment frequency
- Deployment success rate (target: ≥95%)
- Mean time to recovery (MTTR) (target: <30 min)
- Backup success rate (target: 100%)
- Alert response time (target: <15 min)

---

## Success Criteria Summary

### Phase 1 Complete When:
- ✅ Structured logging operational
- ✅ Error tracking with Sentry live
- ✅ Database backups automated
- ✅ Restore procedure tested

### Phase 2 Complete When:
- ✅ 24/7 monitoring active
- ✅ APM collecting metrics
- ✅ Can scale to 2+ replicas
- ✅ Staging environment operational

### Phase 3 Complete When:
- ✅ SSL/TLS optimized
- ✅ Secrets managed securely
- ✅ Docker optimized
- ✅ Security hardening complete

### Phase 4 Complete When:
- ✅ All documentation complete
- ✅ Runbooks tested
- ✅ Monitoring dashboard operational
- ✅ Team trained on operations

---

## Estimated Total Time

- Phase 1: 13 hours (2 weeks @ 6.5h/week)
- Phase 2: 18 hours (3 weeks @ 6h/week)
- Phase 3: 9 hours (3 weeks @ 3h/week)
- Phase 4: 10 hours (2 weeks @ 5h/week)

**Total**: ~50 hours over 10 weeks

---

**Action Plan Owner**: DevOps & Infrastructure Lead
**Last Updated**: 2025-11-23
**Next Review**: End of Phase 1 (Week 2)
