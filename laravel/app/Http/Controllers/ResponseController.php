<?php

namespace App\Http\Controllers;

use App\Models\Form;
use App\Models\Response;
use App\Models\Answer;
use App\Models\Question;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ResponseController extends Controller
{
    public function store(Request $request, $slug)
    {
        $form = Form::where('slug', $slug)->with(['allowedDomains', 'questions'])->first();

        if (!$form) {
            return response()->json([
                'message' => 'Form not found'
            ], 404);
        }

        $user = $request->user();

        // 1. Email domain check
        if ($form->allowedDomains->count() > 0) {
            $userEmail = $user->email;
            $userDomain = substr(strrchr($userEmail, "@"), 1);
            $allowedDomains = $form->allowedDomains->pluck('domain')->toArray();

            if (!in_array($userDomain, $allowedDomains)) {
                return response()->json([
                    'message' => 'Forbidden access'
                ], 403);
            }
        }

        // 2. Limit one response check
        if ($form->limit_one_response) {
            $alreadyResponded = Response::where('form_id', $form->id)
                ->where('user_id', $user->id)
                ->exists();

            if ($alreadyResponded) {
                return response()->json([
                    'message' => 'You can not submit form twice'
                ], 422);
            }
        }

        // 3. Validation
        $request->validate([
            'answers' => 'required|array',
        ]);

        $answersInput = $request->answers;
        $errors = [];

        // Verify required questions are answered
        foreach ($form->questions as $question) {
            $answered = false;
            $answerVal = null;

            foreach ($answersInput as $ans) {
                if (isset($ans['question_id']) && $ans['question_id'] == $question->id) {
                    $answered = true;
                    $answerVal = $ans['value'] ?? null;
                    break;
                }
            }

            if ($question->is_required && (!$answered || is_null($answerVal) || $answerVal === '')) {
                // Return invalid field
                return response()->json([
                    'message' => 'Invalid field',
                    'errors' => [
                        'answers' => [
                            'The answers field is required.'
                        ]
                    ]
                ], 422);
            }
        }

        // Save Response and Answers
        $response = Response::create([
            'form_id' => $form->id,
            'user_id' => $user->id,
            'date' => Carbon::now(),
        ]);

        foreach ($answersInput as $ans) {
            if (isset($ans['question_id'])) {
                Answer::create([
                    'response_id' => $response->id,
                    'question_id' => $ans['question_id'],
                    'value' => $ans['value'] ?? null,
                ]);
            }
        }

        return response()->json([
            'message' => 'Submit response success'
        ], 200);
    }

    public function index(Request $request, $slug)
    {
        $form = Form::where('slug', $slug)->first();

        if (!$form) {
            return response()->json([
                'message' => 'Form not found'
            ], 404);
        }

        // Only form creator can view responses
        if ($form->creator_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Forbidden access'
            ], 403);
        }

        $responses = Response::where('form_id', $form->id)
            ->with(['user', 'answers.question'])
            ->get();

        return response()->json([
            'message' => 'Get responses success',
            'responses' => $responses->map(function ($res) {
                $answersMap = [];
                foreach ($res->answers as $ans) {
                    if ($ans->question) {
                        $answersMap[$ans->question->name] = $ans->value;
                    }
                }

                return [
                    'date' => $res->date->format('Y-m-d H:i:s'),
                    'user' => [
                        'id' => $res->user->id,
                        'name' => $res->user->name,
                        'email' => $res->user->email,
                        'email_verified_at' => $res->user->email_verified_at,
                    ],
                    'answers' => (object)$answersMap,
                ];
            })
        ], 200);
    }
}
