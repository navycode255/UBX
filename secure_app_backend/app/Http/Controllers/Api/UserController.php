<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UserController extends Controller
{
    /**
     * Get user profile by ID
     */
    public function getProfile($userId)
    {
        try {
            $user = User::where('user_id', $userId)->with('profile')->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            $profileData = [
                'user_id' => $user->user_id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->profile ? $user->profile->phone_number : '',
                'profile_picture' => $user->profile ? $user->profile->profile_picture : '',
            ];

            return response()->json([
                'success' => true,
                'message' => 'Profile retrieved successfully',
                'data' => $profileData
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve profile: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update user profile
     */
    public function updateProfile(Request $request, $userId)
    {
        try {
            $user = User::where('user_id', $userId)->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            // Update user basic info
            if ($request->has('name')) {
                $user->name = $request->name;
            }
            if ($request->has('email')) {
                $user->email = $request->email;
            }
            $user->save();

            // Update profile info
            if ($user->profile) {
                if ($request->has('phone_number')) {
                    $user->profile->phone_number = $request->phone_number;
                }
                if ($request->has('profile_picture')) {
                    $user->profile->profile_picture = $request->profile_picture;
                }
                $user->profile->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'Profile updated successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update profile: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Upload profile picture
     */
    public function uploadProfilePicture(Request $request, $userId)
    {
        try {
            $user = User::where('user_id', $userId)->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            // Validate request
            if (!$request->has('image') || !$request->has('filename')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Image data and filename are required'
                ], 400);
            }

            $imageData = $request->input('image');
            $filename = $request->input('filename');

            // Validate base64 image
            if (!preg_match('/^data:image\/(\w+);base64,/', $imageData, $type)) {
                // If no data URL prefix, assume it's raw base64
                $imageData = 'data:image/jpeg;base64,' . $imageData;
                $type = ['', 'jpeg'];
            }

            $imageData = substr($imageData, strpos($imageData, ',') + 1);
            $imageData = base64_decode($imageData);

            if ($imageData === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid base64 image data'
                ], 400);
            }

            // Generate unique filename
            $extension = $type[1] ?? 'jpg';
            $uniqueFilename = 'profile_' . $userId . '_' . time() . '.' . $extension;

            // Store the image
            $path = 'profile-pictures/' . $uniqueFilename;
            Storage::disk('public')->put($path, $imageData);

            // Update user profile
            if (!$user->profile) {
                $user->profile()->create([
                    'user_id' => $userId,
                    'profile_picture' => $path
                ]);
            } else {
                // Delete old profile picture if exists
                if ($user->profile->profile_picture) {
                    Storage::disk('public')->delete($user->profile->profile_picture);
                }
                $user->profile->profile_picture = $path;
                $user->profile->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'Profile picture uploaded successfully',
                'data' => [
                    'image_url' => Storage::url($path),
                    'filename' => $uniqueFilename
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload profile picture: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get profile picture
     */
    public function getProfilePicture($userId)
    {
        try {
            $user = User::where('user_id', $userId)->with('profile')->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            if (!$user->profile || !$user->profile->profile_picture) {
                return response()->json([
                    'success' => false,
                    'message' => 'Profile picture not found'
                ], 404);
            }

            $imagePath = $user->profile->profile_picture;
            
            // Check if file exists
            if (!Storage::disk('public')->exists($imagePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Profile picture file not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Profile picture retrieved successfully',
                'data' => [
                    'image_url' => Storage::url($imagePath),
                    'filename' => basename($imagePath)
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get profile picture: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete profile picture
     */
    public function deleteProfilePicture($userId)
    {
        try {
            $user = User::where('user_id', $userId)->with('profile')->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            if (!$user->profile || !$user->profile->profile_picture) {
                return response()->json([
                    'success' => false,
                    'message' => 'Profile picture not found'
                ], 404);
            }

            $imagePath = $user->profile->profile_picture;

            // Delete file from storage
            if (Storage::disk('public')->exists($imagePath)) {
                Storage::disk('public')->delete($imagePath);
            }

            // Update database
            $user->profile->profile_picture = null;
            $user->profile->save();

            return response()->json([
                'success' => true,
                'message' => 'Profile picture deleted successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete profile picture: ' . $e->getMessage()
            ], 500);
        }
    }
}
