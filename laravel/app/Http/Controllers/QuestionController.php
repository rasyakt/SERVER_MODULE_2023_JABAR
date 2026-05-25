<?php

namespace App\Http\Controllers;

use App\Models\Form;
use App\Models\Question;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class QuestionController extends Controller
{
    public function store(Request $request, $slug)
    {
        $form = Form::where('slug', $slug)->first();

        if (!$form) {
            return response()->json([
                'message' => 'Form not found'
            ], 404);
        }

        // Only form creator can add questions
        if ($form->creator_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Forbidden access'
            ], 403);
        }

        $choiceTypes = ['short answer', 'paragraph', 'date', 'time', 'multiple choice', 'dropdown', 'checkboxes'];

        $request->validate([
            'name' => 'required|string',
            'choice_type' => ['required', Rule::in($choiceTypes)],
            'choices' => [
                Rule::requiredIf(in_array($request->choice_type, ['multiple choice', 'dropdown', 'checkboxes'])),
                'array'
            ],
            'is_required' => 'nullable|boolean',
        ]);

        $choicesStr = null;
        if (in_array($request->choice_type, ['multiple choice', 'dropdown', 'checkboxes']) && is_array($request->choices)) {
            $choicesStr = implode(',', $request->choices);
        }

        $question = Question::create([
            'form_id' => $form->id,
            'name' => $request->name,
            'choice_type' => $request->choice_type,
            'choices' => $choicesStr,
            'is_required' => $request->is_required ?? false,
        ]);

        return response()->json([
            'message' => 'Add question success',
            'question' => [
                'name' => $question->name,
                'choice_type' => $question->choice_type,
                'is_required' => (bool)$question->is_required,
                'choices' => $question->choices,
                'form_id' => $question->form_id,
                'id' => $question->id,
            ]
        ], 200);
    }

    public function destroy(Request $request, $slug, $question_id)
    {
        $form = Form::where('slug', $slug)->first();

        if (!$form) {
            return response()->json([
                'message' => 'Form not found'
            ], 404);
        }

        // Only form creator can remove questions
        if ($form->creator_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Forbidden access'
            ], 403);
        }

        $question = Question::where('id', $question_id)->where('form_id', $form->id)->first();

        if (!$question) {
            return response()->json([
                'message' => 'Question not found'
            ], 404);
        }

        $question->delete();

        return response()->json([
            'message' => 'Remove question success'
        ], 200);
    }
}
