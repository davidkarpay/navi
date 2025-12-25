# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within Navi, please follow these steps:

1. **Do not** open a public GitHub issue
2. Email security concerns to the maintainers privately
3. Include a detailed description of the vulnerability
4. Provide steps to reproduce if possible

## Security Measures

### Backend Security
- JWT-based authentication
- Rate limiting on all endpoints
- Helmet.js security headers
- CORS configuration
- Input validation and sanitization

### Mobile App Security
- Secure keychain storage for tokens
- App Transport Security (ATS) enabled
- Certificate pinning (planned)
- No sensitive data in logs

### Infrastructure Security
- HTTPS-only communication
- Environment variables for secrets
- No secrets committed to repository
- Regular dependency updates

## Response Timeline

- Initial response: Within 48 hours
- Status update: Within 5 business days
- Resolution timeline: Depends on severity

## Security Updates

Security updates will be released as needed and announced through:
- GitHub Security Advisories
- Release notes
