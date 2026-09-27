package com.adaptiveexam.models;

import java.sql.Timestamp;

public class ExamAttempt {
    private int attemptId;
    private int studentId;
    private String studentName; // joined
    private int examId;
    private String examTitle;   // joined
    private double score;
    private double accuracy;
    private Timestamp dateTime;
    private String difficultySummary;
    private String status; // Completed, Auto-Submitted, In-Progress

    public ExamAttempt() {}

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

    public double getScore() { return score; }
    public void setScore(double score) { this.score = score; }

    public double getAccuracy() { return accuracy; }
    public void setAccuracy(double accuracy) { this.accuracy = accuracy; }

    public Timestamp getDateTime() { return dateTime; }
    public void setDateTime(Timestamp dateTime) { this.dateTime = dateTime; }

    public String getDifficultySummary() { return difficultySummary; }
    public void setDifficultySummary(String difficultySummary) { this.difficultySummary = difficultySummary; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
