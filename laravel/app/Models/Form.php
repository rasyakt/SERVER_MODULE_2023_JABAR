<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Form extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'limit_one_response',
        'creator_id',
    ];

    protected $casts = [
        'limit_one_response' => 'boolean',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function allowedDomains(): HasMany
    {
        return $this->hasMany(AllowedDomain::class, 'form_id');
    }

    public function questions(): HasMany
    {
        return $this->hasMany(Question::class, 'form_id');
    }

    public function responses(): HasMany
    {
        return $this->hasMany(Response::class, 'form_id');
    }
}
