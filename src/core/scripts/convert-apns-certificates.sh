#!/bin/bash

# APNS Certificate Conversion Script
# Converts .p12 certificates to .pem format for use with Node.js APNS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Usage
usage() {
    echo "APNS Certificate Conversion Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --dev <file>     Development .p12 certificate file"
    echo "  -p, --prod <file>    Production .p12 certificate file"
    echo "  -o, --output <dir>   Output directory (default: ./certificates)"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -d dev_cert.p12 -p prod_cert.p12"
    echo "  $0 --dev MyApp_Development.p12 --prod MyApp_Production.p12 -o ./certs"
    echo ""
    echo "This script will:"
    echo "  1. Convert .p12 files to .pem format"
    echo "  2. Extract private keys"
    echo "  3. Generate environment variables for Railway"
    echo "  4. Validate certificate formats"
    echo ""
    echo "Prerequisites:"
    echo "  - OpenSSL installed"
    echo "  - .p12 certificate files from Apple Developer Portal"
}

# Variables
DEV_P12=""
PROD_P12=""
OUTPUT_DIR="./certificates"
TEMP_DIR="/tmp/apns_conversion_$$"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dev)
            DEV_P12="$2"
            shift 2
            ;;
        -p|--prod)
            PROD_P12="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$DEV_P12" ] && [ -z "$PROD_P12" ]; then
    error "At least one certificate file must be specified"
    usage
    exit 1
fi

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
    error "OpenSSL is required but not installed."
    echo "Install with: brew install openssl"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Function to convert p12 to pem
convert_p12_to_pem() {
    local p12_file="$1"
    local cert_name="$2"
    local env_prefix="$3"
    
    if [ ! -f "$p12_file" ]; then
        error "Certificate file not found: $p12_file"
        return 1
    fi
    
    log "Converting $cert_name certificate: $p12_file"
    
    # Prompt for password
    echo -n "Enter password for $cert_name certificate (press Enter if no password): "
    read -s password
    echo ""
    
    # Set password option
    local pass_option=""
    if [ -n "$password" ]; then
        pass_option="-passin pass:$password"
    else
        pass_option="-passin pass:"
    fi
    
    # Extract certificate
    log "Extracting certificate..."
    if ! openssl pkcs12 -in "$p12_file" -out "$TEMP_DIR/${cert_name}_cert.pem" -clcerts -nokeys $pass_option; then
        error "Failed to extract certificate from $p12_file"
        return 1
    fi
    
    # Extract private key
    log "Extracting private key..."
    if ! openssl pkcs12 -in "$p12_file" -out "$TEMP_DIR/${cert_name}_key.pem" -nocerts -nodes $pass_option; then
        error "Failed to extract private key from $p12_file"
        return 1
    fi
    
    # Combine certificate and key
    log "Combining certificate and key..."
    cat "$TEMP_DIR/${cert_name}_cert.pem" "$TEMP_DIR/${cert_name}_key.pem" > "$OUTPUT_DIR/${cert_name}.pem"
    
    # Create separate key file
    cp "$TEMP_DIR/${cert_name}_key.pem" "$OUTPUT_DIR/${cert_name}_key.pem"
    
    # Create separate cert file
    cp "$TEMP_DIR/${cert_name}_cert.pem" "$OUTPUT_DIR/${cert_name}_cert.pem"
    
    # Validate the certificate
    log "Validating certificate..."
    if openssl x509 -in "$TEMP_DIR/${cert_name}_cert.pem" -noout -text > /dev/null 2>&1; then
        success "Certificate validation passed"
        
        # Extract certificate info
        local subject=$(openssl x509 -in "$TEMP_DIR/${cert_name}_cert.pem" -noout -subject | sed 's/subject=//')
        local expiry=$(openssl x509 -in "$TEMP_DIR/${cert_name}_cert.pem" -noout -enddate | sed 's/notAfter=//')
        
        log "Certificate Subject: $subject"
        log "Expiry Date: $expiry"
    else
        error "Certificate validation failed"
        return 1
    fi
    
    # Generate environment variable content
    local pem_content=$(cat "$OUTPUT_DIR/${cert_name}.pem" | base64 | tr -d '\n')
    echo "${env_prefix}_CERT_BASE64=\"$pem_content\"" >> "$OUTPUT_DIR/railway_env_vars.txt"
    
    success "Converted $cert_name certificate successfully"
    success "Files created:"
    success "  - $OUTPUT_DIR/${cert_name}.pem (combined cert + key)"
    success "  - $OUTPUT_DIR/${cert_name}_cert.pem (certificate only)"
    success "  - $OUTPUT_DIR/${cert_name}_key.pem (private key only)"
    
    return 0
}

# Function to generate Railway deployment instructions
generate_deployment_instructions() {
    cat > "$OUTPUT_DIR/DEPLOYMENT_INSTRUCTIONS.md" << 'EOF'
# APNS Certificate Deployment Instructions

## Files Generated

- `development.pem` - Development certificate + private key
- `production.pem` - Production certificate + private key  
- `railway_env_vars.txt` - Environment variables for Railway
- `test_certificates.js` - Node.js test script

## Railway Deployment

### Method 1: Using Railway CLI

```bash
# Set environment variables from the generated file
source railway_env_vars.txt

# Or set them individually:
railway variables --set APNS_DEV_CERT_BASE64="$(cat development.pem | base64 | tr -d '\n')"
railway variables --set APNS_PROD_CERT_BASE64="$(cat production.pem | base64 | tr -d '\n')"

# Deploy the updated backend
railway up
```

### Method 2: Using Railway Dashboard

1. Go to your Railway project dashboard
2. Click on your service → Variables
3. Add new variables:
   - `APNS_DEV_CERT_BASE64`: Copy content from `railway_env_vars.txt`
   - `APNS_PROD_CERT_BASE64`: Copy content from `railway_env_vars.txt`
4. Save and redeploy

### Method 3: Using railway.json (Recommended for CI/CD)

Add to your `railway.json`:

```json
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "numReplicas": 1,
    "startCommand": "npm start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  },
  "variables": {
    "NODE_ENV": "production",
    "PORT": "3000",
    "APNS_DEV_CERT_BASE64": "$APNS_DEV_CERT_BASE64",
    "APNS_PROD_CERT_BASE64": "$APNS_PROD_CERT_BASE64"
  }
}
```

## Backend Code Updates

Update your `src/services/apns.js`:

```javascript
const apn = require('apn');

// Load certificates from environment
const loadCertificate = (envVar) => {
  const base64Cert = process.env[envVar];
  if (!base64Cert) {
    console.warn(`Certificate not found in ${envVar}`);
    return null;
  }
  return Buffer.from(base64Cert, 'base64');
};

// APNS Configuration
const apnsConfig = {
  development: {
    cert: loadCertificate('APNS_DEV_CERT_BASE64'),
    production: false
  },
  production: {
    cert: loadCertificate('APNS_PROD_CERT_BASE64'),
    production: true
  }
};

// Initialize APNS provider
const initAPNS = () => {
  const isProduction = process.env.NODE_ENV === 'production';
  const config = isProduction ? apnsConfig.production : apnsConfig.development;
  
  if (!config.cert) {
    console.log('APNS certificate not configured, skipping APNS initialization');
    return null;
  }
  
  return new apn.Provider({
    cert: config.cert,
    production: config.production
  });
};

module.exports = {
  provider: initAPNS(),
  sendNotification: (deviceToken, payload) => {
    if (!module.exports.provider) {
      console.warn('APNS not configured, notification not sent');
      return false;
    }
    
    const notification = new apn.Notification(payload);
    return module.exports.provider.send(notification, deviceToken);
  }
};
```

## Testing Certificates

Run the generated test script:

```bash
node test_certificates.js
```

## Security Notes

1. **Never commit certificates to version control**
2. **Use different certificates for development and production**
3. **Regularly rotate certificates (annually)**
4. **Monitor certificate expiry dates**
5. **Use environment variables, not hardcoded certificates**

## Troubleshooting

### Common Issues

**"Certificate verify failed"**
- Check certificate expiry date
- Ensure correct certificate for environment (dev/prod)
- Verify bundle ID matches app configuration

**"Invalid device token"**
- Device tokens change when app is restored from backup
- Tokens are different between development and production
- Re-register device token in app

**"Bad device token" errors**
- Token format is invalid
- Using production token with development certificate (or vice versa)

### Debugging Commands

```bash
# Check certificate details
openssl x509 -in development_cert.pem -noout -text

# Verify certificate and key match
openssl x509 -noout -modulus -in development_cert.pem | openssl md5
openssl rsa -noout -modulus -in development_key.pem | openssl md5

# Test certificate with Apple
openssl s_client -connect gateway.sandbox.push.apple.com:2195 -cert development_cert.pem -key development_key.pem
```

## Next Steps

1. Deploy certificates to Railway
2. Update your iOS app's bundle identifier
3. Test push notifications in development
4. Deploy to production and test
5. Monitor notification delivery rates

For more help, see the main README.md file.
EOF
}

# Function to generate test script
generate_test_script() {
    cat > "$OUTPUT_DIR/test_certificates.js" << 'EOF'
const fs = require('fs');
const apn = require('apn');

// Test APNS certificates
async function testCertificates() {
    console.log('Testing APNS Certificates...\n');
    
    const certificates = [
        { name: 'Development', file: 'development.pem', production: false },
        { name: 'Production', file: 'production.pem', production: true }
    ];
    
    for (const cert of certificates) {
        if (!fs.existsSync(cert.file)) {
            console.log(`❌ ${cert.name}: Certificate file not found (${cert.file})`);
            continue;
        }
        
        try {
            const provider = new apn.Provider({
                cert: fs.readFileSync(cert.file),
                production: cert.production
            });
            
            console.log(`✅ ${cert.name}: Certificate loaded successfully`);
            
            // Test connection
            try {
                await provider.shutdown();
                console.log(`✅ ${cert.name}: Connection test passed`);
            } catch (error) {
                console.log(`❌ ${cert.name}: Connection test failed - ${error.message}`);
            }
            
        } catch (error) {
            console.log(`❌ ${cert.name}: Failed to load certificate - ${error.message}`);
        }
        
        console.log('');
    }
    
    console.log('Certificate testing complete!');
    console.log('\nNext steps:');
    console.log('1. Upload certificates to Railway using the deployment instructions');
    console.log('2. Update your backend to use the certificates');
    console.log('3. Test push notifications with real device tokens');
}

// Check if apn module is installed
try {
    require('apn');
    testCertificates();
} catch (error) {
    console.log('❌ Missing dependency: npm install apn');
    console.log('Run "npm install apn" to install the required APNS module');
}
EOF
}

# Function to cleanup temp files
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    echo "======================================"
    echo "   APNS Certificate Converter"
    echo "======================================"
    echo "Output directory: $OUTPUT_DIR"
    echo ""
    
    # Initialize environment variables file
    echo "# Railway Environment Variables for APNS" > "$OUTPUT_DIR/railway_env_vars.txt"
    echo "# Generated on $(date)" >> "$OUTPUT_DIR/railway_env_vars.txt"
    echo "" >> "$OUTPUT_DIR/railway_env_vars.txt"
    
    # Convert development certificate
    if [ -n "$DEV_P12" ]; then
        if convert_p12_to_pem "$DEV_P12" "development" "APNS_DEV"; then
            log "Development certificate conversion completed"
        else
            error "Development certificate conversion failed"
            exit 1
        fi
        echo "" # Add spacing
    fi
    
    # Convert production certificate  
    if [ -n "$PROD_P12" ]; then
        if convert_p12_to_pem "$PROD_P12" "production" "APNS_PROD"; then
            log "Production certificate conversion completed"
        else
            error "Production certificate conversion failed"
            exit 1
        fi
        echo "" # Add spacing
    fi
    
    # Generate additional files
    log "Generating deployment instructions..."
    generate_deployment_instructions
    
    log "Generating test script..."
    generate_test_script
    
    # Set appropriate permissions
    chmod 600 "$OUTPUT_DIR"/*.pem 2>/dev/null || true
    chmod 644 "$OUTPUT_DIR"/*.md "$OUTPUT_DIR"/*.txt "$OUTPUT_DIR"/*.js 2>/dev/null || true
    
    # Summary
    echo ""
    echo "======================================"
    echo "         Conversion Complete!"
    echo "======================================"
    success "All certificates converted successfully!"
    echo ""
    echo "Generated files in $OUTPUT_DIR:"
    ls -la "$OUTPUT_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Review: $OUTPUT_DIR/DEPLOYMENT_INSTRUCTIONS.md"
    echo "2. Test certificates: cd $OUTPUT_DIR && node test_certificates.js"
    echo "3. Deploy to Railway using the environment variables"
    echo "4. Update your iOS app configuration"
    echo ""
    warning "Security reminder: Keep certificate files secure and never commit to version control!"
}

# Run main function
main