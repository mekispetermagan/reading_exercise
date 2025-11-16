import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'manager.dart';

// GUI for a reading exercise app.
// The core logic is pure dart, imported from manager.dart.

// These are the stages of
enum Status {
  loading,
  title,
  idle,
  ready,
  checking,
  correct,
  incorrect,
  ended,
  }

class WordCard extends StatelessWidget {
  final String word;
  final void Function() onTap;
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

// The title view is displayed during and after loading,
// until the user presses the start button.
class TitleView extends StatelessWidget {
  final VoidCallback onStart;
  const TitleView({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[

          // title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Reading Exercise",
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
                "Start",
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
        Row(
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
      ],
    );
  }
}

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

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

// HomePage is the only stateful widget;
// its state holds the UI side logic.
class _HomePageState extends State<HomePage> {
  final ExerciseManager _manager = ExerciseManager();
  Status status = Status.loading;
  final AudioPlayer _correct = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _wrong = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _fanfare = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _pop = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _sentence = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // loads data from json,
  // and passes it to the exercise manager
  Future<void> _load() async {
    if (!mounted) return;
    // relative path for web; should be
    //   assets/data/exercises.json
    // for android
    List<String> data = await loadData('data/exercises.json');
    _manager.setData(data);
    _manager.generateExercise();
    if (!mounted) return;
    setState(() {
      status = Status.title;
    });
  }

  _start() {
    setState(() => status = Status.idle);
    _playSentence();
  }

  List<WordCard> _createWordCards(List<int> ids) {
    return [
      for (int id in ids) WordCard(
        word: _manager.labelFor(id),
        onTap: () {
          setState(() {
            _manager.move(id);
            _pop.play(AssetSource("audio/pop.wav"));
            if (_manager.canSubmit) {
              status = Status.ready;
            }
          });
        }
        ),
    ];
  }

  Future<void> _submit() async {
    status = Status.checking;
    bool isCorrect = _manager.checkSubmission();
    _feedback(isCorrect);

  }

  Future<void> _feedback(isCorrect) async {
    if (!mounted) return;
    String message;
    if (isCorrect) {
       message = "Correct!";
       _correct.play(AssetSource("audio/correct.mp3"));
    } else {
       message = "Incorrect!";
       _wrong.play(AssetSource("audio/wrong.mp3"));
    }
    setState(() {
      status = isCorrect ? Status.correct : Status.incorrect;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _next();
  }

  Future<void> _next() async {
    if (!mounted) return;
    if (!_manager.isLastExercise) {
      _manager.next();
      _manager.generateExercise();
      status = Status.idle;
      _playSentence();
    } else {
      status = Status.ended;
    }
    setState(() {});
  }

  Future<void> _playSentence() async {
    final int? id = _manager.exerciseId;
    if (id == null) return;
    await _sentence.stop();
    _sentence.play(AssetSource("audio/sentences/${id}.mp3"));
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
        child: status == Status.loading || status == Status.title
          ? TitleView(onStart: _start)
          : ExerciseView(
              onSubmit: status == Status.ready ? _submit : null,
              sourceCards: sb != null ? _createWordCards(sb) : const [],
              targetCards: tb != null ? _createWordCards(tb) : const [],
              onPlaySentence: _playSentence,
              score: _manager.score,
            ),
      ),
    );
  }
}

Future<List<String>> loadData(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final List<dynamic> list = jsonDecode(text) as List<dynamic>;
  return List<String>.from(list);
}

void main() {
  runApp(const MyApp());
}
