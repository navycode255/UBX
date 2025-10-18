<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'API is running',
        'timestamp' => now()
    ]);
});

// Authentication routes
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// User routes
Route::prefix('user')->group(function () {
    Route::get('/profile/{userId}', [UserController::class, 'getProfile']);
    Route::put('/profile/{userId}', [UserController::class, 'updateProfile']);
    Route::post('/{userId}/profile-picture', [UserController::class, 'uploadProfilePicture']);
    Route::get('/{userId}/profile-picture', [UserController::class, 'getProfilePicture']);
    Route::delete('/{userId}/profile-picture', [UserController::class, 'deleteProfilePicture']);
});
