# Navi Scripts Directory

This directory contains automation scripts for managing your Navi Apple Watch pager app.

## 🎯 Quick Start

```bash
# Test your API endpoints
./test-api.sh

# Deploy updates
./deploy-update.sh all

# Monitor health
./monitor-health.sh -v

# Convert APNS certificates (when needed)
./convert-apns-certificates.sh -d MyApp_Dev.p12 -p MyApp_Prod.p12
```

## 📁 Script Overview

### `test-api.sh` - API Testing
Comprehensive test suite for all API endpoints.

**Usage:**
```bash
./test-api.sh              # Full test suite
./test-api.sh -v           # Verbose output
./test-api.sh -q           # Quick test (no load testing)
```

**Features:**
- Tests all endpoints (auth, pairing, tap sending)
- Error handling validation
- Rate limiting verification
- Concurrent operations testing
- Detailed reporting

### `deploy-update.sh` - Deployment Management
Automates backend deployment and iOS app builds.

**Usage:**
```bash
./deploy-update.sh all              # Deploy backend + build iOS
./deploy-update.sh backend          # Backend only
./deploy-update.sh ios              # iOS build only
./deploy-update.sh status           # Check status
./deploy-update.sh rollback         # Rollback deployment
```

**Features:**
- Git status validation
- Automated testing
- Railway deployment
- iOS app building
- Rollback capability
- Deployment reports

### `monitor-health.sh` - Health Monitoring
Continuous monitoring with alerts.

**Usage:**
```bash
./monitor-health.sh                 # Interactive mode
./monitor-health.sh -d              # Daemon mode
./monitor-health.sh -w 'webhook'    # With Slack/Discord alerts
```

**Features:**
- Continuous health checks
- Response time tracking
- Webhook alerts (Slack, Discord)
- Metrics collection
- Automatic recovery detection

### `convert-apns-certificates.sh` - APNS Setup
Converts Apple push notification certificates for production use.

**Usage:**
```bash
./convert-apns-certificates.sh -d dev.p12 -p prod.p12
```

**Features:**
- Converts .p12 to .pem format
- Generates Railway environment variables
- Certificate validation
- Deployment instructions
- Security best practices

## 🚀 Production Deployment Workflow

### 1. Initial Setup
```bash
# Convert APNS certificates
./convert-apns-certificates.sh -d MyApp_Development.p12 -p MyApp_Production.p12

# Upload certificates to Railway (follow generated instructions)
# Update environment variables in Railway dashboard
```

### 2. Development Cycle
```bash
# Test your changes
./test-api.sh -v

# Deploy updates
./deploy-update.sh all

# Start monitoring
./monitor-health.sh -d -w 'your-webhook-url'
```

### 3. Maintenance
```bash
# Check deployment status
./deploy-update.sh status

# View health metrics
./monitor-health.sh --verbose

# Rollback if needed
./deploy-update.sh rollback
```

## 🔧 Configuration

### Environment Variables
All scripts respect these environment variables:

- `API_URL` - Override default API base URL
- `RAILWAY_TOKEN` - Railway authentication token
- `WEBHOOK_URL` - Default webhook for alerts

### Script Configuration Files
- `test-api.sh` - Edit variables at top of script
- `deploy-update.sh` - Configure in script header
- `monitor-health.sh` - Command line options or edit defaults

## 📊 Monitoring & Alerting

### Health Check Metrics
The monitor script tracks:
- Response times
- Success/failure rates
- Consecutive failures
- Service uptime

### Alert Webhooks
Set up webhooks for:
- **Slack**: Use incoming webhook URL
- **Discord**: Use webhook URL from server settings
- **Generic**: Any JSON webhook endpoint

Example webhook payload:
```json
{
  "text": "🚨 Navi Alert: SERVICE_DOWN",
  "attachments": [
    {
      "color": "danger",
      "fields": [
        {
          "title": "Message",
          "value": "Service has failed 3 consecutive health checks"
        }
      ]
    }
  ]
}
```

## 🧪 Testing Scenarios

### Full Integration Test
```bash
# Run comprehensive tests
./test-api.sh

# Deploy to staging (if available)
API_URL="https://staging.example.com" ./deploy-update.sh backend

# Test against staging
API_URL="https://staging.example.com" ./test-api.sh -v

# Deploy to production
./deploy-update.sh all
```

### Load Testing
```bash
# Extended load test
./test-api.sh --verbose

# Monitor during load
./monitor-health.sh -i 10 -v  # Check every 10 seconds
```

### Rollback Testing
```bash
# Deploy a test version
./deploy-update.sh backend

# Verify it works
./test-api.sh -q

# Practice rollback
./deploy-update.sh rollback
```

## 🔐 Security Considerations

### Certificate Management
- Never commit .p12 or .pem files to git
- Use environment variables for certificates
- Rotate certificates annually
- Monitor certificate expiry dates

### API Security
- All endpoints use HTTPS
- JWT tokens for authentication
- Rate limiting enforced
- Input validation on all endpoints

### Monitoring Security
- Webhook URLs may contain secrets
- Log files may contain sensitive data
- Monitor access to log files
- Use secure webhook endpoints

## 🛠️ Troubleshooting

### Common Issues

**Script Permission Denied**
```bash
chmod +x scripts/*.sh
```

**Missing Dependencies**
```bash
# Install required tools
brew install jq curl openssl
npm install -g @railway/cli
```

**Railway Not Linked**
```bash
cd backend
railway link
```

**Health Check Failures**
```bash
# Check logs
./monitor-health.sh --verbose

# Manual test
curl -v https://lovely-vibrancy-production-2c30.up.railway.app/health
```

**Certificate Issues**
```bash
# Test certificates
cd certificates
node test_certificates.js
```

### Debug Commands

```bash
# API endpoint debugging
curl -v -X POST https://your-api-url/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"deviceToken": "test"}'

# Railway debugging
railway logs --tail 100

# Certificate debugging
openssl x509 -in certificate.pem -noout -text
```

## 📈 Performance Optimization

### Backend Optimization
- Monitor response times with health script
- Use Railway metrics for resource usage
- Optimize database queries
- Enable compression

### iOS App Optimization
- Test on physical devices
- Monitor memory usage
- Optimize network calls
- Test with poor network conditions

## 📚 Additional Resources

- [Main README](../SETUP_GUIDE.md) - Complete setup guide
- [API Documentation](../API_DOCUMENTATION.md) - Full API reference
- [Railway Documentation](https://docs.railway.app/) - Deployment platform
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications) - APNS guide

## 🤝 Contributing

When adding new scripts:
1. Follow the existing error handling patterns
2. Add comprehensive help text (`--help`)
3. Include verbose logging options
4. Add to this README
5. Test thoroughly before committing

---

**Last Updated**: August 8, 2025  
**Scripts Version**: 1.0  
**Navi App Version**: 1.0