import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'manager.dart';

// GUI for a reading exercise app.
// The core logic is pure dart, imported from manager.dart.

// Web debug asset paths:
// - images:  images/
// - audio:   audio/
// - json:    data/
// Apk build asset paths:
// - images:  assets/images/
// - audio:   audio/
// - json:    assets/data/

// High-level UI state of a reading session, deciding
// which screen and controls are shown.
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

// Bucketed accuracy of the player (poor/average/good),
// used for the final feedback message.
// accuracy level: see at the _calculateAccuracyLevel() in HomePageState
enum AccuracyLevel {poor, average, good}

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

// Full-screen title view shown while loading and
// before the session starts. Displays the app title, illustration,
// and a start button (or "Wait..." while loading).
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

// Main exercise view showing source and target word banks
// and the current score. Also provides sentence playback and
// a submit button that is enabled/disabled by the parent.
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

// Final result view shown after the last exercise.
// Displays the total score and a message based on [accuracyLevel],
// or an error message if no exercises could be loaded.
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

// Root widget configuring app title, dark theme, and routing
// to [HomePage].
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

// Top-level page widget for the reading exercise flow.
// Its state object controls loading, session progress,
// and the active view.
class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Stateful controller for a reading exercise session.
// Coordinates the [ExerciseManager], session status, UI updates,
// and audio feedback.
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

  /// Loads exercise sentences from bundled JSON,
  /// passes them to the [ExerciseManager],
  /// and switches to the title screen when ready.
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

  /// Starts the exercise session from the title screen
  /// and plays the first sentence audio.
  void _startSession() {
    setState(() => _status = SessionStatus.idle);
    _playSentence();
  }

  /// Taps toggle word selection, play a pop sound,
  /// and update whether submission is possible.  List<Widget> _buildWordCards(List<int> ids) {
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

  // Handles the submit button press: sets status to checking,
  /// evaluates the current attempt via the manager, and triggers feedback.
  void _handleSubmit() {
    setState(() {
    _status = SessionStatus.checking;
    });
    bool isCorrect = _manager.checkSubmission();
    _showFeedback(isCorrect);
  }

  /// Shows feedback for the last submission: plays the correct/wrong sound,
  /// updates status, displays a SnackBar, and then advances to the next exercise.
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

/// Moves to the next exercise if available (regenerating data
/// and playing the sentence), or ends the session
/// and plays the fanfare when there are no more exercises.
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

  // Plays the audio for the current exercise sentence,
  // if there is a valid exercise ID
  Future<void> _playSentence() async {
    final int? id = _manager.exerciseId;
    if (id == null) return;
    await _sentencePlayer.stop();
    _sentencePlayer.play(AssetSource("audio/sentences/$id.mp3"));
  }

  /// Converts the manager's raw accuracy (0.0–1.0)
  /// into an [AccuracyLevel] bucket used for the end-of-session
  /// feedback text.
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

/// Builds the scaffold and chooses which view to show based on [_status],
/// wiring current score, cards, and callbacks into the child widgets.
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

/// Loads a JSON array of strings from the given asset [assetPath]
/// and returns it as a [List<String>].
Future<List<String>> loadExercises(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final List<dynamic> list = jsonDecode(text) as List<dynamic>;
  return List<String>.from(list);
}

// Application entry point: starts the Flutter app
// with [MyApp] as the root widget.
void main() {
  runApp(const MyApp());
}
