import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'manager.dart';

/// GUI for a reading exercise app.
/// The core logic is pure dart, imported from manager.dart.

// Web debug asset paths:
// - images:  images/
// - audio:   audio/
// - json:    data/
// Apk build asset paths:
// - images:  assets/images/
// - audio:   audio/
// - json:    assets/data/

/// High-level UI state of one reading session.
/// Drives which screen is shown and whether the user
/// can interact with the current exercise.
// These are the stages of the app:
// - loading:   title view,     fetching json
// - title:     title view,     json is loaded
// - idle:      exercise view,  waiting for user action
// - ready:     exercise view,  user can submit
// - checking:  exercise view,  evaluation in progress
// - correct:   exercise view,  positive feedback
// - incorrect: exercise view,  negative feedback
// - ended:     end view
enum SessionStatus {
  loading,
  title,
  idle,
  ready,
  checking,
  correct,
  incorrect,
  ended,
  }

/// Coarse performance buckets derived from overall accuracy.
/// Used only to select the final feedback text on the end screen.
// accuracy level: see at the _calculateAccuracyLevel() in HomePageState
enum AccuracyLevel {poor, average, good}

/// Tappable visual for a single word choice in the exercise.
/// Purely presentational: behavior is injected via [onTap].
class WordCard extends StatelessWidget {
  final String word;
  final VoidCallback? onTap;
  const WordCard({
    required this.word,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        )
      )

    );
  }
}

/// Full-screen title / intro view.
/// Shown while loading and after data is ready, until the
/// user starts the exercise via [onStart].
class TitleView extends StatelessWidget {
  final VoidCallback? onStart;
  const TitleView({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[

          // title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Read every day!",
              style: TextStyle(
                fontSize: 36,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // titleimage
          Image.asset(
            'images/reading_girl.png',
            width: 180,
          ),

          // startbutton
          TextButton(
            onPressed: onStart,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                colorScheme.primaryContainer,
              ),
              foregroundColor: WidgetStatePropertyAll(
                colorScheme.onPrimaryContainer,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                onStart != null ? "Start" : "Wait...",
                style: TextStyle(
                  fontSize: 24,
                ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseView extends StatelessWidget {
  final VoidCallback? onSubmit;
  final List<Widget> sourceCards;
  final List<Widget> targetCards;
  final VoidCallback onPlaySentence;
  final int score;

/// Main exercise layout: source and target word banks, score,
/// sentence playback button and submit button.
/// Submit is enabled/disabled by passing a non-null/nullable [onSubmit].
  const ExerciseView({
    required this.onSubmit,
    required this.sourceCards,
    required this.targetCards,
    required this.onPlaySentence,
    required this.score,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[

        // source bank
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sourceCards,
            ),
          ),
        ),

        // target bank
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: targetCards,
            ),
          ),
        ),

        // bottom bar
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Score: $score",
                style: TextStyle(
                  fontSize: 24,
                  color: colorScheme.onSurface,
                  ),
              ),
              IconButton(
                onPressed: onPlaySentence,
                icon: const Icon(Icons.volume_up),
                iconSize: 36,
                tooltip: "Play sentence",
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.primaryContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSubmit,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.primaryContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onPrimaryContainer,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 24,
                    ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

  /// Final summary screen after the last exercise.
  /// Shows total [score] and a message based on [accuracyLevel],
  /// or an error-style message if accuracy is unavailable.
 class EndView extends StatelessWidget {
  final int score;
  final AccuracyLevel? accuracyLevel;

  const EndView({required this.score, this.accuracyLevel, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          switch(accuracyLevel) {
            AccuracyLevel.poor =>
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    height: 1.82,
                  ),
                  children: [
                    const TextSpan(
                      text: "Better luck next time! You reached\n",
                    ),
                    TextSpan(
                      text: '$score\n',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: 'points. Thanks for playing!'),
                  ],
                ),
              ),
            AccuracyLevel.average =>
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    height: 1.82,
                  ),
                  children: [
                    const TextSpan(
                      text: "Not bad! You reached\n",
                    ),
                    TextSpan(
                      text: '$score\n',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: 'points. Thanks for playing!'),
                  ],
                ),
              ),
            AccuracyLevel.good =>
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    height: 1.82,
                  ),
                  children: [
                    const TextSpan(
                      text: "You did great reaching\n",
                    ),
                    TextSpan(
                      text: '$score\n',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: 'points. Thanks for playing!'),
                  ],
                ),
              ),
            null =>
              Text(
                "It's not you, it's us.\nFailed to fetch exercises.\nSorry for your experience!",
                      style: const TextStyle(
                        fontSize: 24,
                      ),
              ),
          },
          Image.asset(
            'images/reading_girl.png',
            width: 180,
          ),
        ],
      ),
    );
  }
}

/// Root widget configuring Material theming and bootstrapping
/// the reading flow via [HomePage].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(title: 'Reading Exercise'),
    );
  }
}

/// Shell page for the reading exercise feature.
/// Holds the static title and delegates behavior to [_HomePageState].
class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Coordinates a complete reading session:
/// loads data, advances exercises, tracks [SessionStatus],
/// and drives audio / visual feedback.
// HomePage is the only stateful widget;
// its state holds the UI side logic.
class _HomePageState extends State<HomePage> {
  final ExerciseManager _manager = ExerciseManager();
  SessionStatus _status = SessionStatus.loading;
  final AudioPlayer _correctPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _wrongPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _fanfarePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _popPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _sentencePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  @override
  void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _fanfarePlayer.dispose();
    _popPlayer.dispose();
    _sentencePlayer.dispose();
    super.dispose();
  }

  /// One-shot loader for exercise sentences from JSON assets.
  /// Populates the [ExerciseManager], creates the first exercise,
  /// then moves the session into the title state.
  // loads data from json,
  // and passes it to the exercise manager
  Future<void> _loadExerciseData() async {
    // relative path for web; should be
    //   assets/data/exercises.json
    // for android
    List<String> data = await loadExercises('data/exercises.json');
    _manager.setData(data);
    _manager.generateExercise();
    if (!mounted) return;
    setState(() {
      _status = SessionStatus.title;
    });
  }

  /// Transitions from the title screen into the first exercise
  /// and immediately plays the current sentence audio.
  void _startSession() {
    setState(() => _status = SessionStatus.idle);
    _playSentence();
  }

  /// Builds [WordCard]s for the given IDs and wires tap behavior:
  /// toggling selection in the manager, playing a pop sound, and
  /// updating [_status] between idle and ready. Disabled while
  /// showing correct/incorrect feedback.
  List<Widget> _buildWordCards(List<int> ids) {
    return [
      for (int id in ids) WordCard(
        word: _manager.labelFor(id),
        onTap: _status != SessionStatus.correct && _status != SessionStatus.incorrect
          ? () {
            setState(() {
              _manager.toggleWord(id);
              _popPlayer.play(AssetSource("audio/pop.wav"));
              if (_manager.canSubmit) {
                _status = SessionStatus.ready;
              } else {
                _status = SessionStatus.idle;
              }
            });
          }
          : null,
        ),
    ];
  }

  /// Entry point for the submit button.
  /// Marks the session as checking, evaluates the current attempt
  /// via the manager, then forwards the result to [_showFeedback].
  void _handleSubmit() {
    setState(() {
    _status = SessionStatus.checking;
    });
    bool isCorrect = _manager.checkSubmission();
    _showFeedback(isCorrect);
  }

  /// Plays correct/wrong audio, updates [_status] accordingly,
  /// shows a brief SnackBar message, waits a short delay and
  /// then triggers [_goToNextExercise].
  Future<void> _showFeedback(bool isCorrect) async {
    if (!mounted) return;
    String message;
    if (isCorrect) {
       message = "Correct!";
       _correctPlayer.play(AssetSource("audio/correct.mp3"));
    } else {
       message = "Incorrect!";
       _wrongPlayer.play(AssetSource("audio/wrong.mp3"));
    }
    setState(() {
      _status = isCorrect ? SessionStatus.correct : SessionStatus.incorrect;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _goToNextExercise();
  }

  /// Advances the session: either generates and shows the next
  /// exercise (and plays its sentence) or, if this was the last
  /// one, marks the session ended and plays the fanfare.
  void _goToNextExercise() {
    if (!mounted) return;
    if (!_manager.isLastExercise) {
      _manager.nextExercise();
      _manager.generateExercise();
      _status = SessionStatus.idle;
      _playSentence();
    } else {
      _status = SessionStatus.ended;
      _fanfarePlayer.play(AssetSource("audio/fanfare.mp3"));
    }
    setState(() {});
  }

  /// Stops any currently playing sentence and starts playback
  /// for the audio file associated with the current exercise ID,
  /// if one is available.
  Future<void> _playSentence() async {
    final int? id = _manager.exerciseId;
    if (id == null) return;
    await _sentencePlayer.stop();
    _sentencePlayer.play(AssetSource("audio/sentences/$id.mp3"));
  }

  /// Converts the manager's raw accuracy (0.0–1.0) into an
  /// [AccuracyLevel] bucket for use on the end screen.
  /// Returns null if no accuracy data is available.
  // accuracy levels:
  // - 0%  <= poor    < 40%
  // - 40% <= average < 80%
  // - 80% <= good   <= 100%
  // - null: no exercises (shouldn't happen)
  AccuracyLevel? _calculateAccuracyLevel() {
    double? rawAccuracy = _manager.accuracy;
    if (rawAccuracy == null) {return null;}

    return switch (rawAccuracy) {
      < 0.4 => AccuracyLevel.poor,
      < 0.8 => AccuracyLevel.average,
      _     => AccuracyLevel.good,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sb = _manager.sourceBank;
    final tb = _manager.targetBank;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (_status) {
          SessionStatus.loading => TitleView(onStart: null,),
          SessionStatus.title => TitleView(onStart: _startSession,),
          SessionStatus.ended => EndView(
            score: _manager.score,
            accuracyLevel: _calculateAccuracyLevel(),
          ),
          SessionStatus.idle ||
          SessionStatus.ready ||
          SessionStatus.checking ||
          SessionStatus.correct ||
          SessionStatus.incorrect
            => ExerciseView(
              onSubmit: _status == SessionStatus.ready ? _handleSubmit : null,
              sourceCards: sb != null ? _buildWordCards(sb) : const [],
              targetCards: tb != null ? _buildWordCards(tb) : const [],
              onPlaySentence: _playSentence,
              score: _manager.score,
            ),
        },
      ),
    );
  }
}

/// Utility for loading a JSON array of strings from [assetPath]
/// and returning it as a [List<String>]. Assumes the JSON has
/// the expected shape (simple string array).
Future<List<String>> loadExercises(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final List<dynamic> list = jsonDecode(text) as List<dynamic>;
  return List<String>.from(list);
}

void main() {
  runApp(const MyApp());
}
