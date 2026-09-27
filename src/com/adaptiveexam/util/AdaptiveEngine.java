package com.adaptiveexam.util;

import com.adaptiveexam.dao.QuestionDAO;
import com.adaptiveexam.models.Question;

import java.util.List;

/**
 * Core Adaptive Examination Engine.
 *
 * Difficulty transition rules:
 *   Medium + Correct  → Hard
 *   Medium + Wrong    → Easy
 *   Hard   + Correct  → Hard  (stay)
 *   Hard   + Wrong    → Medium
 *   Easy   + Correct  → Medium
 *   Easy   + Wrong    → Easy  (stay)
 *
 * Starting difficulty: Medium
 */
public class AdaptiveEngine {

    public static final String EASY   = "Easy";
    public static final String MEDIUM = "Medium";
    public static final String HARD   = "Hard";

    /** Every exam starts at Medium difficulty */
    public static String getStartDifficulty() {
        return MEDIUM;
    }

    /**
     * Determines the next difficulty based on current difficulty and whether
     * the last answer was correct.
     */
    public static String determineNextDifficulty(String currentDifficulty, boolean wasCorrect) {
        if (currentDifficulty == null) return MEDIUM;
        switch (currentDifficulty) {
            case MEDIUM: return wasCorrect ? HARD : EASY;
            case HARD:   return wasCorrect ? HARD : MEDIUM;
            case EASY:   return wasCorrect ? MEDIUM : EASY;
            default:     return MEDIUM;
        }
    }

    /**
     * Fetches the next adaptive question.
     * Falls back to adjacent difficulty levels if no question available at target.
     *
     * @param examId         The exam being attempted
     * @param targetDifficulty  Desired difficulty based on adaptive logic
     * @param askedIds       IDs of questions already asked (to avoid repeats)
     * @return Next Question, or null if no more questions available
     */
    public static Question getNextQuestion(int examId, String targetDifficulty,
                                           List<Integer> askedIds) {
        QuestionDAO dao = new QuestionDAO();

        // Try target difficulty first
        Question q = dao.getAdaptiveQuestion(examId, targetDifficulty, askedIds);
        if (q != null) return q;

        // Fallback: try adjacent difficulty
        String fallback1 = targetDifficulty.equals(HARD) ? MEDIUM
                         : targetDifficulty.equals(EASY) ? MEDIUM : EASY;
        q = dao.getAdaptiveQuestion(examId, fallback1, askedIds);
        if (q != null) return q;

        // Last resort: try any remaining difficulty
        for (String d : new String[]{EASY, MEDIUM, HARD}) {
            if (!d.equals(targetDifficulty) && !d.equals(fallback1)) {
                q = dao.getAdaptiveQuestion(examId, d, askedIds);
                if (q != null) return q;
            }
        }

        return null; // Exam complete — no more questions
    }

    /**
     * Returns a badge CSS class name for a difficulty string.
     * Used in JSP for colour-coding.
     */
    public static String getDifficultyClass(String difficulty) {
        if (difficulty == null) return "badge-medium";
        switch (difficulty) {
            case EASY:   return "badge-easy";
            case HARD:   return "badge-hard";
            default:     return "badge-medium";
        }
    }
}
