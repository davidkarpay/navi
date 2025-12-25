# API Security Policy

## Authentication

### JWT Tokens
- Tokens issued on device registration
- 24-hour expiration
- Refresh mechanism available
- Tokens stored securely in iOS Keychain

### Token Validation
- All protected endpoints require valid JWT
- Token signature verified on each request
- Expired tokens rejected with 401

## Authorization

### Endpoint Access
| Endpoint | Auth Required | Rate Limit |
|----------|---------------|------------|
| POST /api/auth/register | No | 10/min |
| POST /api/pairing/create | Yes | 5/min |
| POST /api/pairing/join | Yes | 10/min |
| POST /api/tap/send | Yes | 60/min |
| GET /health | No | 100/min |

## Rate Limiting

- Implemented via express-rate-limit
- Per-IP limiting for unauthenticated endpoints
- Per-user limiting for authenticated endpoints
- 429 response when limit exceeded

## Input Validation

### Request Body
- JSON schema validation
- Maximum payload size: 10KB
- Content-Type enforcement

### Path Parameters
- UUID format validation
- SQL injection prevention
- XSS prevention

## Security Headers

Implemented via Helmet.js:
- Content-Security-Policy
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- Strict-Transport-Security
- X-XSS-Protection

## CORS Configuration

- Allowed origins: Configured per environment
- Credentials: Enabled for authenticated requests
- Exposed headers: Limited to necessary

## Error Handling

- Generic error messages to clients
- Detailed errors logged server-side
- No stack traces in production
- Consistent error response format

## Logging

### What We Log
- Request method and path
- Response status codes
- Authentication failures
- Rate limit violations

### What We Don't Log
- Full request/response bodies
- JWT tokens
- Passwords or secrets
- Personal user data
