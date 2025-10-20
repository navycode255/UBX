const http = require('http');
const { exec } = require('child_process');

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

// Start HTTP proxy
const startHttpProxy = () => {
    // Create HTTP server
    const server = http.createServer((req, res) => {
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
        console.log('🚀 HTTP Server running on http://0.0.0.0:5000');
        console.log('📱 Your Flutter app can now connect via HTTP');
        console.log('');
        console.log('Press Ctrl+C to stop the server');
    });
    
    return server;
};

// Main execution
console.log('🔧 Setting up HTTP development environment...');
console.log('');

// Start Laravel in background
const laravelProcess = startLaravel();

// Wait for Laravel to start, then start HTTP proxy
setTimeout(() => {
    startHttpProxy();
}, 3000);

// Cleanup on exit
process.on('SIGINT', () => {
    console.log('\n🛑 Stopping servers...');
    laravelProcess.kill();
    process.exit(0);
});
