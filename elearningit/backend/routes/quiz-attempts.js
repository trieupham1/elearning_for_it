const express = require('express');
const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const Question = require('../models/Question');
const { authMiddleware, instructorOnly } = require('../middleware/auth');

const router = express.Router();

// Start a new quiz attempt
router.post('/start', authMiddleware, async (req, res) => {
  try {
    const { quizId } = req.body;
    const studentId = req.user.userId;

    // Get quiz details with populated questions
    const quiz = await Quiz.findById(quizId).populate('selectedQuestions');
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }

    // Check if quiz is available
    const now = new Date();
    if (quiz.openDate && now < quiz.openDate) {
      return res.status(400).json({ message: 'Quiz has not started yet' });
    }
    if (quiz.closeDate && now > quiz.closeDate) {
      return res.status(400).json({ message: 'Quiz has ended' });
    }

    // Check attempt limit
    const attemptCount = await QuizAttempt.getAttemptCount(quizId, studentId);
    if (quiz.maxAttempts !== -1 && attemptCount >= quiz.maxAttempts) {
      return res.status(400).json({ 
        message: `Maximum attempts (${quiz.maxAttempts}) reached` 
      });
    }

    // Check if there's an active attempt
    const activeAttempt = await QuizAttempt.findOne({
      quizId,
      studentId,
      status: 'in_progress'
    });

    if (activeAttempt) {
      // Check if it's expired and auto-submit
      await activeAttempt.autoSubmitIfExpired();
      if (activeAttempt.status === 'in_progress') {
        return res.status(400).json({ 
          message: 'You already have an active attempt', 
          attemptId: activeAttempt._id 
        });
      }
    }

    // Create questions array with snapshot of current question data
    const questions = quiz.selectedQuestions.map(question => ({
      questionId: question._id,
      questionText: question.questionText,
      choices: question.choices.map(choice => ({
        text: choice.text,
        isCorrect: choice.isCorrect
      })),
      difficulty: question.difficulty,
      selectedAnswer: [],
      isCorrect: false,
      timeSpent: 0
    }));

    // Shuffle questions if enabled
    if (quiz.randomizeQuestions) {
      for (let i = questions.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [questions[i], questions[j]] = [questions[j], questions[i]];
      }
    }

    // Create new attempt
    const newAttempt = new QuizAttempt({
      quizId,
      studentId,
      attemptNumber: attemptCount + 1,
      startTime: now,
      duration: quiz.duration,
      questions,
      totalQuestions: questions.length,
      totalPoints: quiz.totalPoints || 100,
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    await newAttempt.save();

    // Return attempt without correct answers
    const attemptResponse = {
      ...newAttempt.toObject(),
      questions: newAttempt.questions.map(q => ({
        questionId: q.questionId,
        questionText: q.questionText,
        choices: q.choices.map(choice => ({ text: choice.text })), // Remove isCorrect
        difficulty: q.difficulty,
        selectedAnswer: q.selectedAnswer,
        timeSpent: q.timeSpent
      }))
    };

    res.status(201).json(attemptResponse);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get current attempt
router.get('/:attemptId', authMiddleware, async (req, res) => {
  try {
    const { attemptId } = req.params;
    const studentId = req.user.userId;

    const attempt = await QuizAttempt.findOne({
      _id: attemptId,
      studentId
    }).populate('quizId', 'title duration');

    if (!attempt) {
      return res.status(404).json({ message: 'Attempt not found' });
    }

    // Auto-submit if expired
    await attempt.autoSubmitIfExpired();

    // Return without correct answers if still in progress
    const attemptResponse = {
      ...attempt.toObject(),
      questions: attempt.questions.map(q => ({
        questionId: q.questionId,
        questionText: q.questionText,
        choices: attempt.status === 'in_progress' 
          ? q.choices.map(choice => ({ text: choice.text }))
          : q.choices, // Show correct answers after submission
        difficulty: q.difficulty,
        selectedAnswer: q.selectedAnswer,
        isCorrect: q.isCorrect,
        timeSpent: q.timeSpent
      }))
    };

    res.json(attemptResponse);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update question answer
router.put('/:attemptId/answer', authMiddleware, async (req, res) => {
  try {
    const { attemptId } = req.params;
    const { questionId, selectedAnswer, timeSpent } = req.body;
    const studentId = req.user.userId;

    const attempt = await QuizAttempt.findOne({
      _id: attemptId,
      studentId,
      status: 'in_progress'
    });

    if (!attempt) {
      return res.status(404).json({ message: 'Active attempt not found' });
    }

    // Check if expired
    if (attempt.isExpired()) {
      await attempt.autoSubmitIfExpired();
      return res.status(400).json({ message: 'Attempt has expired' });
    }

    // Find and update the question
    const questionIndex = attempt.questions.findIndex(
      q => q.questionId.toString() === questionId
    );

    if (questionIndex === -1) {
      return res.status(404).json({ message: 'Question not found in attempt' });
    }

    const question = attempt.questions[questionIndex];
    question.selectedAnswer = Array.isArray(selectedAnswer) ? selectedAnswer : [selectedAnswer];
    question.timeSpent = timeSpent || 0;

    // Check if answer is correct
    const correctChoices = question.choices
      .filter(choice => choice.isCorrect)
      .map(choice => choice.text);
    
    question.isCorrect = correctChoices.length === question.selectedAnswer.length &&
      correctChoices.every(correct => question.selectedAnswer.includes(correct));

    await attempt.save();

    res.json({ 
      message: 'Answer saved',
      questionId,
      selectedAnswer: question.selectedAnswer,
      timeSpent: question.timeSpent
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Submit quiz attempt
router.post('/:attemptId/submit', authMiddleware, async (req, res) => {
  try {
    const { attemptId } = req.params;
    const studentId = req.user.userId;

    const attempt = await QuizAttempt.findOne({
      _id: attemptId,
      studentId,
      status: 'in_progress'
    });

    if (!attempt) {
      return res.status(404).json({ message: 'Active attempt not found' });
    }

    // Submit the attempt
    const now = new Date();
    attempt.endTime = now;
    attempt.submissionTime = now;
    attempt.timeSpent = Math.floor((now - attempt.startTime) / 1000); // in seconds
    attempt.status = 'submitted';

    await attempt.save(); // This will trigger the pre-save hook to calculate score

    // Return full results including correct answers
    const result = {
      ...attempt.toObject(),
      questions: attempt.questions.map(q => ({
        questionId: q.questionId,
        questionText: q.questionText,
        choices: q.choices,
        difficulty: q.difficulty,
        selectedAnswer: q.selectedAnswer,
        isCorrect: q.isCorrect,
        timeSpent: q.timeSpent
      }))
    };

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get student's attempts for a quiz
router.get('/quiz/:quizId/student', authMiddleware, async (req, res) => {
  try {
    const { quizId } = req.params;
    const studentId = req.user.userId;

    const attempts = await QuizAttempt.find({
      quizId,
      studentId
    }).sort({ attemptNumber: -1 }).populate('quizId', 'title maxAttempts');

    res.json(attempts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get all attempts for a quiz (instructor only)
router.get('/quiz/:quizId/all', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const { quizId } = req.params;

    const attempts = await QuizAttempt.find({ quizId })
      .populate('studentId', 'firstName lastName username email')
      .populate('quizId', 'title')
      .sort({ submissionTime: -1, studentId: 1, attemptNumber: -1 });

    // Get quiz to find all enrolled students
    const quiz = await Quiz.findById(quizId).populate('courseId');
    
    // Create summary with completion status
    const summary = {
      quiz: quiz.title,
      totalAttempts: attempts.length,
      uniqueStudents: [...new Set(attempts.map(a => a.studentId._id.toString()))].length,
      completedAttempts: attempts.filter(a => ['submitted', 'auto_submitted'].includes(a.status)).length,
      averageScore: attempts.length > 0 
        ? Math.round(attempts.reduce((sum, a) => sum + a.score, 0) / attempts.length)
        : 0,
      attempts: attempts
    };

    res.json(summary);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Auto-submit expired attempts (cleanup job)
router.post('/cleanup-expired', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const expiredAttempts = await QuizAttempt.find({ status: 'in_progress' });
    
    let submittedCount = 0;
    for (const attempt of expiredAttempts) {
      const wasExpired = attempt.isExpired();
      await attempt.autoSubmitIfExpired();
      if (wasExpired) submittedCount++;
    }

    res.json({ 
      message: `Cleaned up ${submittedCount} expired attempts`,
      submittedCount 
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;