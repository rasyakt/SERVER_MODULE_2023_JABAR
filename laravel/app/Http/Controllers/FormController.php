<?php

namespace App\Http\Controllers;

use App\Models\Form;
use App\Models\AllowedDomain;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FormController extends Controller
{
    public function index(Request $request)
    {
        $forms = Form::where('creator_id', $request->user()->id)->get();

        return response()->json([
            'message' => 'Get all forms success',
            'forms' => $forms->map(function ($form) {
                return [
                    'id' => $form->id,
                    'name' => $form->name,
                    'slug' => $form->slug,
                    'description' => $form->description,
                    'limit_one_response' => $form->limit_one_response ? 1 : 0,
                    'creator_id' => $form->creator_id,
                ];
            })
        ], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'slug' => [
                'required',
                'string',
                'unique:forms,slug',
                'regex:/^[a-zA-Z0-9.-]+$/' // alphanumeric, only dash and dot, no space
            ],
            'allowed_domains' => 'nullable|array',
            'description' => 'nullable|string',
            'limit_one_response' => 'nullable|boolean',
        ], [
            'slug.regex' => 'The slug must be alphanumeric with special characters only dash and dot and without space.',
        ]);

        $form = Form::create([
            'name' => $request->name,
            'slug' => $request->slug,
            'description' => $request->description,
            'limit_one_response' => $request->limit_one_response ?? false,
            'creator_id' => $request->user()->id,
        ]);

        $allowedDomains = [];
        if ($request->has('allowed_domains') && is_array($request->allowed_domains)) {
            foreach ($request->allowed_domains as $domain) {
                AllowedDomain::create([
                    'form_id' => $form->id,
                    'domain' => $domain,
                ]);
                $allowedDomains[] = $domain;
            }
        }

        return response()->json([
            'message' => 'Create form success',
            'form' => [
                'name' => $form->name,
                'slug' => $form->slug,
                'description' => $form->description,
                'limit_one_response' => (bool)$form->limit_one_response,
                'creator_id' => $form->creator_id,
                'id' => $form->id,
            ]
        ], 200);
    }

    public function show(Request $request, $slug)
    {
        $form = Form::where('slug', $slug)->with(['allowedDomains', 'questions'])->first();

        if (!$form) {
            return response()->json([
                'message' => 'Form not found'
            ], 404);
        }

        // Domain verification if the form has allowed domains
        if ($form->allowedDomains->count() > 0) {
            $userEmail = $request->user()->email;
            $userDomain = substr(strrchr($userEmail, "@"), 1);

            $allowedDomains = $form->allowedDomains->pluck('domain')->toArray();

            if (!in_array($userDomain, $allowedDomains)) {
                return response()->json([
                    'message' => 'Forbidden access'
                ], 403);
            }
        }

        return response()->json([
            'message' => 'Get form success',
            'form' => [
                'id' => $form->id,
                'name' => $form->name,
                'slug' => $form->slug,
                'description' => $form->description,
                'limit_one_response' => $form->limit_one_response ? 1 : 0,
                'creator_id' => $form->creator_id,
                'allowed_domains' => $form->allowedDomains->pluck('domain')->toArray(),
                'questions' => $form->questions->map(function ($question) {
                    return [
                        'id' => $question->id,
                        'form_id' => $question->form_id,
                        'name' => $question->name,
                        'choice_type' => $question->choice_type,
                        'choices' => $question->choices,
                        'is_required' => $question->is_required ? 1 : 0,
                    ];
                })
            ]
        ], 200);
    }
}
