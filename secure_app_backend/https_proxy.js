const https = require('https');
const http = require('http');
const fs = require('fs');
const { exec } = require('child_process');

// Certificate files
const certFile = './ssl/secure_app_backend.pfx';
const password = 'secure_app_2025';

// Convert PFX to PEM for Node.js
const convertPfxToPem = () => {
    return new Promise((resolve, reject) => {
        const command = `openssl pkcs12 -in "${certFile}" -out "./ssl/cert.pem" -nodes -passin pass:${password}`;
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.log('OpenSSL not available, trying alternative approach...');
                resolve(false);
            } else {
                console.log('Certificate converted successfully');
                resolve(true);
            }
        });
    });
};

// Start the HTTPS proxy
const startHttpsProxy = async () => {
    console.log('Setting up HTTPS proxy for Laravel...');
    
    // Try to convert certificate
    const converted = await convertPfxToPem();
    
    if (converted && fs.existsSync('./ssl/cert.pem')) {
        // Use the converted certificate
        const options = {
            key: fs.readFileSync('./ssl/cert.pem'),
            cert: fs.readFileSync('./ssl/cert.pem')
        };
        
        const server = https.createServer(options, (req, res) => {
            // Proxy to Laravel HTTP server
            const proxyReq = http.request({
                hostname: 'localhost',
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
        
        server.listen(5001, '0.0.0.0', () => {
            console.log('HTTPS proxy running on https://0.0.0.0:5001');
            console.log('Proxying to Laravel HTTP server on http://localhost:5000');
            console.log('Note: You may see a security warning due to self-signed certificate');
        });
    } else {
        console.log('Could not set up HTTPS. Please install OpenSSL or use a different approach.');
        console.log('Starting HTTP server instead...');
        
        // Fallback: Start Laravel directly
        exec('php artisan serve --host=0.0.0.0 --port=5000', (error, stdout, stderr) => {
            if (error) {
                console.error('Error starting Laravel:', error);
            }
        });
    }
};

// Start Laravel HTTP server in background
console.log('Starting Laravel HTTP server...');
const laravelProcess = exec('php artisan serve --host=0.0.0.0 --port=5000');

laravelProcess.stdout.on('data', (data) => {
    console.log('Laravel:', data);
});

laravelProcess.stderr.on('data', (data) => {
    console.error('Laravel Error:', data);
});

// Wait a moment for Laravel to start, then start HTTPS proxy
setTimeout(startHttpsProxy, 3000);
