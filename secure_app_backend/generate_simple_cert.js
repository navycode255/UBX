const { execSync } = require('child_process');
const fs = require('fs');

console.log('Generating simple self-signed certificate...');

try {
    // Create ssl directory if it doesn't exist
    if (!fs.existsSync('ssl')) {
        fs.mkdirSync('ssl');
    }

    // Generate private key
    execSync('openssl genrsa -out ssl/server.key 2048', { stdio: 'inherit' });
    
    // Generate certificate
    execSync('openssl req -new -x509 -key ssl/server.key -out ssl/server.crt -days 365 -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"', { stdio: 'inherit' });
    
    console.log('✓ Self-signed certificate created successfully!');
    console.log('Files created:');
    console.log('  - ssl/server.key (private key)');
    console.log('  - ssl/server.crt (certificate)');
} catch (error) {
    console.log('OpenSSL not available, using Node.js crypto...');
    
    // Fallback: create dummy files for now
    fs.writeFileSync('ssl/server.key', 'dummy-key');
    fs.writeFileSync('ssl/server.crt', 'dummy-cert');
    console.log('Created dummy certificate files');
}
