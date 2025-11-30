import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'reading_logic.dart';
import "session_phases.dart";
import 'widgets.dart';
import 'screens.dart';

// Web debug asset paths:
// - images:  images/
// - audio:   audio/
// - json:    data/
// Apk build asset paths:
// - images:  assets/images/
// - audio:   audio/
// - json:    assets/data/

/// GUI for a reading exercise app.
/// App state lives in [HomePageState].
class ReadingApp extends StatelessWidget {
  const ReadingApp({super.key});

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

class _HomePageState extends State<HomePage> {
  SessionPhase _phase = LoadingPhase();
  late final List<Map<String, dynamic>> _jsonData;
  final AudioPlayer _speechPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _effectPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  @override
  void initState() {
    super.initState();
    _speechPlayer.play(AssetSource("audio/intro.mp3"));
    _loadData('assets/data/exercises.json');
  }

  void _loadData(String assetPath) async {
    final text = await rootBundle.loadString(assetPath);
    final list = jsonDecode(text);
    if (list is! List) {
      throw FormatException("Malformed json: it should be a list.");
    }
    final decoded = list.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Malformed list: every item should be an object.',
        );
      }
      return item;
    }).toList();
    _onDataLoaded(decoded);
  }

  void _onDataLoaded(List<Map<String, dynamic>> data) {
    _jsonData = data;
    setState(() => _phase = TitlePhase(
      data: data,
    ));
  }

  void _onStart(List<Map<String, dynamic>> data) => setState(() =>
    _phase = SelectionPhase(
      step: SelectionStep.categorySelection,
      manager: SelectionManager.fromJson(jsonData: data),
    )
  );

  void _onSelectCategory(String category, SelectionManager manager) {
    manager.selectedCategory = category;
    setState(() =>
      _phase = SelectionPhase(
        step: SelectionStep.exerciseSelection,
        manager: manager,
      )
    );
  }

  void _onSelectExercise(String title, SelectionManager manager) {
    setState(() =>
      _phase = ExercisePhase(
        step: ExerciseStep.preparingAnswer,
        manager: manager.exerciseManagerWith(title),
      )
    );
  }

  void _onMoveCard(ExerciseManager manager, int id) {
    _playEffect("pop.wav");
    manager.toggleWord(id);
    setState(() => _phase = manager.canSubmit
      ? ExercisePhase(
        step: ExerciseStep.readyToSubmit,
        manager: manager
      )
      : ExercisePhase(
        step: ExerciseStep.preparingAnswer,
        manager: manager
      )
    );
  }

  Future<void> _onSubmitAnswer(ExerciseManager manager) async {
    manager.submit();
    if (manager.correctSubmission) {
      _playEffect("correct.mp3");
      setState(() => _phase = ExercisePhase(
        step: ExerciseStep.correctFeedback,
        manager: manager,
      ));
    } else {
      _playEffect("wrong.mp3");
      setState(() => _phase = ExercisePhase(
        step: ExerciseStep.incorrectFeedback,
        manager: manager,
      ));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (manager.isLastExercise) {
      setState(() => _phase = ResultPhase(
        score: manager.score,
        maxScore: manager.maxScore,
      ));
    } else {
      manager.nextExercise();
      setState(() => _phase = ExercisePhase(
        step: ExerciseStep.preparingAnswer,
        manager: manager
      ));
    }
  }

  void _onRestart() => setState(() => _phase = SelectionPhase(
    step: SelectionStep.categorySelection,
    manager: SelectionManager.fromJson(
      jsonData: _jsonData, // I don't like this
    )
  )

  );

  void _onPlaySentence(int id) {
    _speechPlayer.stop();
    _speechPlayer.play(AssetSource("audio/$id.mp3"));
  }

  void _playEffect(String name) {
    _effectPlayer.stop();
    _effectPlayer.play(AssetSource("audio/$name"));
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    switch(phase) {
      case LoadingPhase(): {
        return TitleScreen(onStart: null);
      }
      case TitlePhase(data: final data):
        return TitleScreen(onStart: () => _onStart(data));
      case SelectionPhase(step: final step, manager: final manager):
        return switch (step) {
          SelectionStep.categorySelection => CategorySelectScreen(
            categories: manager.categories,
            onSubmit: (String category) =>_onSelectCategory(category, manager),
          ),
          SelectionStep.exerciseSelection => ExerciseSelectScreen(
            titles: manager.titles,
            onSubmit: (String title) => _onSelectExercise(title, manager),
          )
        };
      case ExercisePhase(step: final step, manager: final manager): {
        List<WordCard> cards(List<int> ids, bool canMove) => [
          for (final id in ids)
            WordCard(
              word: manager.labelFor(id),
              onTap: () => canMove ? _onMoveCard(manager, id) : null,
            )
        ];
        return switch (step) {
          ExerciseStep.preparingAnswer => ExerciseScreen(
            sourceCards: cards(manager.sourceBank, true),
            targetCards: cards(manager.targetBank, true),
            onPlaySentence: () => _onPlaySentence(manager.sentenceId!),
            onSubmit: null,
            progressLog: manager.progressLog,
            score: manager.score,
            current: manager.current,
          ),
          ExerciseStep.readyToSubmit => ExerciseScreen(
            sourceCards: cards(manager.sourceBank, true),
            targetCards: cards(manager.targetBank, true),
            onPlaySentence: () => _onPlaySentence(manager.sentenceId!),
            onSubmit: () => _onSubmitAnswer(manager),
            progressLog: manager.progressLog,
            score: manager.score,
            current: manager.current,
          ),
          ExerciseStep.correctFeedback => ExerciseScreen(
            sourceCards: cards(manager.sourceBank, false),
            targetCards: cards(manager.targetBank, false),
            onPlaySentence: null,
            onSubmit: null,
            progressLog: manager.progressLog,
            score: manager.score,
            current: manager.current,
          ),
          ExerciseStep.incorrectFeedback => ExerciseScreen(
            sourceCards: cards(manager.sourceBank, false),
            targetCards: cards(manager.targetBank, false),
            onPlaySentence: null,
            onSubmit: null,
            progressLog: manager.progressLog,
            score: manager.score,
            current: manager.current,
          ),
        };
      }
      case ResultPhase(score: final score, maxScore: final maxScore):
        return ResultScreen(
          score: score,
          maxScore: maxScore,
          onRestart: _onRestart,
        );
    }
  }
}

void main() {
  runApp(const ReadingApp());
}
