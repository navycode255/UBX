<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Secure App Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains configuration for the secure app backend,
    | including HTTPS settings and security configurations.
    |
    */

    'https' => [
        'enabled' => env('HTTPS_ENABLED', false),
        'port' => env('HTTPS_PORT', 5000),
        'certificate' => env('HTTPS_CERT', 'ssl/secure_app_backend.pfx'),
        'password' => env('HTTPS_PASSWORD', 'secure_app_2025'),
    ],

    'security' => [
        'force_https' => env('FORCE_HTTPS', false),
        'hsts' => env('HSTS_ENABLED', true),
        'cors' => [
            'allowed_origins' => ['*'], // Configure for production
            'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
        ],
    ],
];
