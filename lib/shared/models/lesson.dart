/// One daily lesson (Firestore `lessons/{id}` or bundled `assets/lessons.json`).
class Lesson {
  const Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.sourceVideoTitle,
    required this.youtubeId,
    required this.clipStartSec,
    required this.clipEndSec,
    required this.keyIdea,
    required this.action,
    required this.reflectionQuestion,
    required this.quiz,
    this.contentVersion = 1,
  });

  final String id;
  final int order;
  final String title;
  final String sourceVideoTitle;
  final String youtubeId;
  final int clipStartSec;
  final int clipEndSec;
  final List<String> keyIdea;
  final String action;
  final String reflectionQuestion;
  final List<QuizQuestion> quiz;
  final int contentVersion;

  factory Lesson.fromMap(String id, Map<String, dynamic> m) => Lesson(
        id: id,
        order: (m['order'] as num).toInt(),
        title: m['title'] as String,
        sourceVideoTitle: m['sourceVideoTitle'] as String? ?? '',
        youtubeId: m['youtubeId'] as String,
        clipStartSec: (m['clipStartSec'] as num).toInt(),
        clipEndSec: (m['clipEndSec'] as num).toInt(),
        keyIdea: List<String>.from(m['keyIdea'] as List),
        action: m['action'] as String,
        reflectionQuestion: m['reflectionQuestion'] as String,
        quiz: (m['quiz'] as List? ?? const [])
            .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
            .toList(),
        contentVersion: (m['contentVersion'] as num?)?.toInt() ?? 1,
      );

  /// Link that opens the full video in the YouTube app at the clip start.
  Uri get fullVideoUri =>
      Uri.parse('https://www.youtube.com/watch?v=$youtubeId&t=${clipStartSec}s');
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        question: m['question'] as String,
        options: List<String>.from(m['options'] as List),
        correctIndex: (m['correctIndex'] as num).toInt(),
        explanation: m['explanation'] as String? ?? '',
      );
}
