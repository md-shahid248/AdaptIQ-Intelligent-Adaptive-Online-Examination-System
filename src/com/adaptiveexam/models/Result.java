package com.adaptiveexam.models;

public class Result {
    private int id;
    private int attemptId;
    private int studentId;
    private String studentName; // joined
    private int examId;
    private String examTitle;   // joined
    private double totalScore;
    private double maxPossibleScore;
    private double percentage;
    private int rankInExam;

    public Result() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getAttemptId() { return attemptId; }
    public void setAttemptId(int attemptId) { this.attemptId = attemptId; }

    public int getStudentId() { return studentId; }
    public void setStudentId(int studentId) { this.studentId = studentId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public int getExamId() { return examId; }
    public void setExamId(int examId) { this.examId = examId; }

    public String getExamTitle() { return examTitle; }
    public void setExamTitle(String examTitle) { this.examTitle = examTitle; }

    public double getTotalScore() { return totalScore; }
    public void setTotalScore(double totalScore) { this.totalScore = totalScore; }

    public double getMaxPossibleScore() { return maxPossibleScore; }
    public void setMaxPossibleScore(double maxPossibleScore) { this.maxPossibleScore = maxPossibleScore; }

    public double getPercentage() { return percentage; }
    public void setPercentage(double percentage) { this.percentage = percentage; }

    public int getRankInExam() { return rankInExam; }
    public void setRankInExam(int rankInExam) { this.rankInExam = rankInExam; }
}
