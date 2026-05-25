<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\FormController;
use App\Http\Controllers\QuestionController;
use App\Http\Controllers\ResponseController;

Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Form Management
        Route::post('/forms', [FormController::class, 'store']);
        Route::get('/forms', [FormController::class, 'index']);
        Route::get('/forms/{form_slug}', [FormController::class, 'show']);

        // Question Management
        Route::post('/forms/{form_slug}/questions', [QuestionController::class, 'store']);
        Route::delete('/forms/{form_slug}/questions/{question_id}', [QuestionController::class, 'destroy']);

        // Response Management
        Route::post('/forms/{form_slug}/responses', [ResponseController::class, 'store']);
        Route::get('/forms/{form_slug}/responses', [ResponseController::class, 'index']);
    });
});
