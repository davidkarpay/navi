# Data Handling Policy

## Overview

This document outlines how Navi handles user data across all platforms.

## Data Collection

### What We Collect
- Device tokens (for push notifications)
- Pairing codes (temporary, for device linking)
- Tap events (timestamps and device identifiers)
- User session information

### What We Don't Collect
- Personal identifying information (name, email, etc.)
- Location data
- Contact information
- Usage analytics beyond basic functionality

## Data Storage

### Backend (Railway)
- SQLite database for persistent storage
- Data encrypted at rest
- Regular backups (planned)
- Data retention: Active sessions only

### Mobile Devices
- Tokens stored in iOS Keychain
- No plaintext secrets in UserDefaults
- App Groups for secure data sharing between iOS and watchOS

## Data Transmission

- All API communication over HTTPS
- JWT tokens for authentication
- WebSocket connections secured with TLS
- Push notifications via APNs (encrypted)

## Data Retention

- Session data: Until logout or expiration
- Pairing codes: 5 minutes (auto-expire)
- Tap history: Configurable retention period

## User Rights

Users can:
- Delete their session data by logging out
- Request data deletion (contact maintainers)

## Compliance

- GDPR considerations implemented
- No third-party analytics or tracking
- Minimal data collection principle
