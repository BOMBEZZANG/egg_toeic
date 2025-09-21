import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseFirestore _firestore;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore = FirebaseFirestore.instance;

    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  FirebaseFirestore get firestore => _firestore;

  // Seed initial questions (for development only)
  Future<void> seedInitialQuestions() async {
    final batch = _firestore.batch();

    final sampleQuestions = _getSampleQuestions();

    for (final question in sampleQuestions) {
      final docRef = _firestore.collection('questions_part5').doc();
      batch.set(docRef, question);
    }

    await batch.commit();
    print('Seeded ${sampleQuestions.length} questions');
  }

  List<Map<String, dynamic>> _getSampleQuestions() {
    return [
      // Level 1 Questions (Beginner)
      {
        'questionText': 'The meeting _____ scheduled for 3 PM tomorrow.',
        'options': ['is', 'are', 'were', 'be'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"Is" is the correct form of the verb "to be" for singular subjects in present tense. "The meeting" is singular, so we use "is".',
        'grammarPoint': 'Subject-Verb Agreement',
        'tags': ['grammar', 'verb', 'present-tense'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'Please submit your report _____ Friday.',
        'options': ['by', 'in', 'at', 'on'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"By" indicates a deadline - the report must be submitted before or on Friday. "On" would mean specifically on Friday, but "by" is more appropriate for deadlines.',
        'grammarPoint': 'Prepositions of Time',
        'tags': ['grammar', 'preposition', 'time'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The new employee _____ very hardworking.',
        'options': ['is', 'are', 'has', 'have'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"Is" is correct because "the new employee" is singular and we need the verb "to be" to describe a characteristic.',
        'grammarPoint': 'Subject-Verb Agreement',
        'tags': ['grammar', 'verb', 'adjective'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'We need to buy _____ office supplies.',
        'options': ['some', 'any', 'much', 'many'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"Some" is used in positive statements with plural countable nouns like "office supplies".',
        'grammarPoint': 'Quantifiers',
        'tags': ['grammar', 'quantifier', 'countable'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The conference room is _____ the second floor.',
        'options': ['in', 'on', 'at', 'by'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 1,
        'explanation': '"On" is used with floors of buildings. We say "on the second floor", not "in the second floor".',
        'grammarPoint': 'Prepositions of Place',
        'tags': ['grammar', 'preposition', 'location'],
        'createdAt': DateTime.now().toIso8601String(),
      },

      // Level 2 Questions (Intermediate)
      {
        'questionText': 'The proposal _____ reviewed by the board next week.',
        'options': ['will be', 'would be', 'has been', 'is being'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 2,
        'explanation': '"Will be" forms the future passive voice. The proposal will receive the action (being reviewed) in the future (next week).',
        'grammarPoint': 'Passive Voice - Future',
        'tags': ['grammar', 'passive-voice', 'future-tense'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'If I _____ more time, I would finish the project today.',
        'options': ['have', 'had', 'would have', 'will have'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': 'This is a second conditional sentence (hypothetical present). We use "had" in the if-clause and "would + verb" in the main clause.',
        'grammarPoint': 'Conditional Sentences',
        'tags': ['grammar', 'conditional', 'hypothetical'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The manager suggested _____ the deadline.',
        'options': ['to extend', 'extending', 'extend', 'extended'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': 'After "suggest", we use the gerund form (-ing). "The manager suggested extending the deadline."',
        'grammarPoint': 'Gerunds and Infinitives',
        'tags': ['grammar', 'gerund', 'suggestion'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The company has been _____ rapidly over the past year.',
        'options': ['grown', 'growing', 'grew', 'grows'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': 'Present perfect continuous tense uses "has/have been + -ing". This shows an action that started in the past and continues to the present.',
        'grammarPoint': 'Present Perfect Continuous',
        'tags': ['grammar', 'tense', 'continuous'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': '_____ the heavy rain, the outdoor event was cancelled.',
        'options': ['Because', 'Due to', 'Since', 'Although'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': '"Due to" is followed by a noun phrase. "Because" and "since" are followed by clauses, and "although" shows contrast.',
        'grammarPoint': 'Cause and Effect',
        'tags': ['grammar', 'conjunction', 'cause'],
        'createdAt': DateTime.now().toIso8601String(),
      },

      // Level 3 Questions (Advanced)
      {
        'questionText': 'Not only _____ the project on time, but they also came under budget.',
        'options': [
          'did they complete',
          'they completed',
          'they did complete',
          'completed they'
        ],
        'correctAnswerIndex': 0,
        'difficultyLevel': 3,
        'explanation': 'After "Not only" at the beginning of a sentence, we use inverted word order (auxiliary verb + subject + main verb).',
        'grammarPoint': 'Inversion after Negative Adverbs',
        'tags': ['grammar', 'advanced', 'inversion'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The CEO insisted that the report _____ submitted by Friday.',
        'options': ['is', 'was', 'be', 'will be'],
        'correctAnswerIndex': 2,
        'difficultyLevel': 3,
        'explanation': 'After verbs like "insist", "demand", "require" we use the subjunctive mood with the base form of the verb (be, not is/was).',
        'grammarPoint': 'Subjunctive Mood',
        'tags': ['grammar', 'advanced', 'subjunctive'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'Had we known about the traffic, we _____ earlier.',
        'options': [
          'would leave',
          'would have left',
          'will leave',
          'had left'
        ],
        'correctAnswerIndex': 1,
        'difficultyLevel': 3,
        'explanation': 'This is a third conditional with inversion. "Had we known" = "If we had known", so the main clause uses "would have + past participle".',
        'grammarPoint': 'Third Conditional with Inversion',
        'tags': ['grammar', 'advanced', 'conditional', 'inversion'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The research team _____ to have made significant progress.',
        'options': ['appears', 'appear', 'appearing', 'appeared'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 3,
        'explanation': '"The research team" is treated as a singular unit, so we use "appears". This is followed by a perfect infinitive "to have made".',
        'grammarPoint': 'Collective Nouns and Perfect Infinitives',
        'tags': ['grammar', 'advanced', 'collective-noun'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'Scarcely _____ the presentation when the fire alarm went off.',
        'options': [
          'had she begun',
          'she had begun',
          'she began',
          'did she begin'
        ],
        'correctAnswerIndex': 0,
        'difficultyLevel': 3,
        'explanation': 'After negative adverbs like "scarcely", "hardly", "barely" we use inversion with past perfect tense.',
        'grammarPoint': 'Inversion with Negative Adverbs',
        'tags': ['grammar', 'advanced', 'inversion', 'past-perfect'],
        'createdAt': DateTime.now().toIso8601String(),
      },

      // Additional questions to reach minimum 20 total
      {
        'questionText': 'The team _____ working on this project for three months.',
        'options': ['is', 'are', 'has been', 'have been'],
        'correctAnswerIndex': 2,
        'difficultyLevel': 1,
        'explanation': '"Team" is a collective noun treated as singular, so we use "has been" with present perfect continuous.',
        'grammarPoint': 'Collective Nouns',
        'tags': ['grammar', 'collective-noun', 'present-perfect'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The documents _____ to all department heads yesterday.',
        'options': ['sent', 'were sent', 'was sent', 'sending'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': '"Documents" is plural, so we use "were sent" in the passive voice.',
        'grammarPoint': 'Passive Voice - Past',
        'tags': ['grammar', 'passive-voice', 'past-tense'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': '_____ the presentation was excellent, few people attended.',
        'options': ['Despite', 'Although', 'Because', 'Due to'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 2,
        'explanation': '"Although" introduces a contrast clause. "Despite" would need a noun phrase, not a clause.',
        'grammarPoint': 'Contrast and Concession',
        'tags': ['grammar', 'contrast', 'conjunction'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'The budget for next year _____ approved yet.',
        'options': ['has not been', 'was not', 'is not', 'will not be'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 2,
        'explanation': '"Yet" indicates present perfect tense. The passive form is "has not been approved".',
        'grammarPoint': 'Present Perfect Passive',
        'tags': ['grammar', 'present-perfect', 'passive-voice'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'It is essential that everyone _____ the safety regulations.',
        'options': ['follows', 'follow', 'following', 'to follow'],
        'correctAnswerIndex': 1,
        'difficultyLevel': 3,
        'explanation': 'After "It is essential that...", we use the subjunctive mood with the base form of the verb.',
        'grammarPoint': 'Subjunctive with Essential',
        'tags': ['grammar', 'subjunctive', 'essential'],
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }
}