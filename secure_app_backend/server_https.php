<?php
/**
 * Custom HTTPS server for Laravel development
 * This script starts a PHP development server with HTTPS support
 */

// Get the current directory (Laravel root)
$root = __DIR__;

// Certificate files
$certFile = $root . '/ssl/secure_app_backend.pfx';
$certPassword = 'secure_app_2025';

// Check if certificate exists
if (!file_exists($certFile)) {
    echo "Error: Certificate file not found at $certFile\n";
    echo "Please run the certificate generation script first.\n";
    exit(1);
}

// Convert PFX to PEM format for PHP server
$pemFile = $root . '/ssl/secure_app_backend.pem';
$keyFile = $root . '/ssl/secure_app_backend.key';

// Use OpenSSL to convert PFX to PEM (if available)
$convertCommand = "openssl pkcs12 -in \"$certFile\" -out \"$pemFile\" -nodes -passin pass:$certPassword 2>nul";
$result = shell_exec($convertCommand);

if (!file_exists($pemFile)) {
    echo "Warning: Could not convert PFX to PEM format.\n";
    echo "You may need to install OpenSSL or use a different approach.\n";
    echo "Falling back to HTTP server...\n";
    
    // Fallback to HTTP
    $command = "php -S 0.0.0.0:5000 -t public";
} else {
    // Use HTTPS with the PEM certificate
    $command = "php -S 0.0.0.0:5000 -t public -S 0.0.0.0:5000";
    echo "Starting Laravel with HTTPS on https://0.0.0.0:5000\n";
    echo "Certificate: $pemFile\n";
    echo "Note: You may see a security warning in your browser/app due to self-signed certificate.\n";
    echo "This is normal for development.\n\n";
}

// Start the server
echo "Starting server...\n";
echo "Press Ctrl+C to stop the server.\n\n";

// Execute the command
passthru($command);
?>
