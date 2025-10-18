const https = require('https');
const http = require('http');
const { exec } = require('child_process');
const fs = require('fs');

// Create self-signed certificate for development
const createSelfSignedCert = () => {
    const { execSync } = require('child_process');
    
    try {
        // Check if we have OpenSSL
        execSync('openssl version', { stdio: 'ignore' });
        
        // Generate private key
        execSync('openssl genrsa -out ssl/server.key 2048', { stdio: 'inherit' });
        
        // Generate certificate
        execSync('openssl req -new -x509 -key ssl/server.key -out ssl/server.crt -days 365 -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"', { stdio: 'inherit' });
        
        console.log('✓ Self-signed certificate created');
        return true;
    } catch (error) {
        console.log('OpenSSL not available, using Node.js crypto...');
        return false;
    }
};

// Start Laravel server
const startLaravel = () => {
    console.log('Starting Laravel server...');
    const laravel = exec('php artisan serve --host=127.0.0.1 --port=5000');
    
    laravel.stdout.on('data', (data) => {
        console.log('Laravel:', data.toString().trim());
    });
    
    laravel.stderr.on('data', (data) => {
        console.error('Laravel Error:', data.toString().trim());
    });
    
    return laravel;
};

// Start HTTPS proxy
const startHttpsProxy = () => {
    // Check if certificates exist
    if (!fs.existsSync('ssl/server.crt') || !fs.existsSync('ssl/server.key')) {
        console.log('Creating self-signed certificate...');
        if (!createSelfSignedCert()) {
            console.log('Could not create certificate. Please install OpenSSL or use HTTP.');
            return;
        }
    }
    
    // Load certificates
    const options = {
        key: fs.readFileSync('ssl/server.key'),
        cert: fs.readFileSync('ssl/server.crt')
    };
    
    // Create HTTPS server
    const server = https.createServer(options, (req, res) => {
        // Add CORS headers
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
        
        // Handle preflight requests
        if (req.method === 'OPTIONS') {
            res.writeHead(200);
            res.end();
            return;
        }
        
        // Proxy to Laravel
        const proxyReq = http.request({
            hostname: '127.0.0.1',
            port: 5000,
            path: req.url,
            method: req.method,
            headers: req.headers
        }, (proxyRes) => {
            res.writeHead(proxyRes.statusCode, proxyRes.headers);
            proxyRes.pipe(res);
        });
        
        req.pipe(proxyReq);
    });
    
    server.listen(5000, '0.0.0.0', () => {
        console.log('🚀 HTTPS Server running on https://0.0.0.0:5000');
        console.log('🔒 Using self-signed certificate (you may see a security warning)');
        console.log('📱 Your Flutter app can now connect via HTTPS');
        console.log('');
        console.log('Press Ctrl+C to stop the server');
    });
    
    return server;
};

// Main execution
console.log('🔧 Setting up HTTPS development environment...');
console.log('');

// Start Laravel in background
const laravelProcess = startLaravel();

// Wait for Laravel to start, then start HTTPS proxy
setTimeout(() => {
    startHttpsProxy();
}, 3000);

// Cleanup on exit
process.on('SIGINT', () => {
    console.log('\n🛑 Stopping servers...');
    laravelProcess.kill();
    process.exit(0);
});
