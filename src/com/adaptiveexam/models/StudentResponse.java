package com.adaptiveexam.models;

public class StudentResponse {
    private int id;
    private int attemptId;
    private int questionId;
    private String questionText;  // joined
    private String difficulty;    // joined
    private String topic;         // joined
    private char selectedAnswer;
    private boolean isCorrect;
    private double marksAwarded;
    private char correctAnswer;   // joined

    public StudentResponse() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getAttemptId() { return attemptId; }
    public void setAttemptId(int attemptId) { this.attemptId = attemptId; }

    public int getQuestionId() { return questionId; }
    public void setQuestionId(int questionId) { this.questionId = questionId; }

    public String getQuestionText() { return questionText; }
    public void setQuestionText(String questionText) { this.questionText = questionText; }

    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }

    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }

    public char getSelectedAnswer() { return selectedAnswer; }
    public void setSelectedAnswer(char selectedAnswer) { this.selectedAnswer = selectedAnswer; }

    public boolean isCorrect() { return isCorrect; }
    public void setCorrect(boolean correct) { isCorrect = correct; }

    public double getMarksAwarded() { return marksAwarded; }
    public void setMarksAwarded(double marksAwarded) { this.marksAwarded = marksAwarded; }

    public char getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(char correctAnswer) { this.correctAnswer = correctAnswer; }
}
