import 'package:flutter/material.dart';
import "widgets.dart";

/// Shown while loading and after data is ready, until the
/// user starts the game via [onStart].
class TitleScreen extends StatelessWidget {
  final VoidCallback? onStart;
  const TitleScreen({required this.onStart, super.key});

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
            // for Chrome debugging:
            // 'images/reading_girl.png',
            // for apk build:
            'assets/images/reading_girl.png',
            width: 180,
          ),

          // startbutton
          PrimaryActionButton(
            text: "Start",
            onPressed: onStart
          ),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorScreen({
    required this.errorMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            errorMessage,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class CategorySelectScreen extends StatelessWidget {
  final List<String> categories;
  final void Function(String) onSubmit;

  const CategorySelectScreen({
    required this.categories,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(24),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final item in categories)
                TextButton(
                  child: Text(item),
                  onPressed: () => onSubmit(item),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseSelectScreen extends StatelessWidget {
  final List<String> titles;
  final void Function(String) onSubmit;

  const ExerciseSelectScreen({
    required this.titles,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(24),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final title in titles)
                TextButton(
                  child: Text(title),
                  onPressed: () => onSubmit(title),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main exercise layout
/// Submit is disabled when [onSubmit] is null
class ExerciseScreen extends StatelessWidget {
  final List<Widget> sourceCards;
  final List<Widget> targetCards;
  final VoidCallback? onPlaySentence;
  final VoidCallback? onSubmit;
  final int score;

  const ExerciseScreen({
    required this.sourceCards,
    required this.targetCards,
    required this.onPlaySentence,
    required this.onSubmit,
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
              PrimaryActionButton(
                text: "Submit",
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Summary screen after the last exercise with a restart button.
class ResultScreen extends StatelessWidget {
  final int score;
  final int maxScore;
  final VoidCallback onRestart;

  const ResultScreen({
    required this.score,
    required this.maxScore, // will be used for progress bar
    required this.onRestart,
    super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  text: "Thank you for playing! You reached\n",
                ),
                TextSpan(
                  text: '$score\n',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: 'points. One more game?'),
              ],
            ),
          ),
          Image.asset(
            // for Chrome debugging:
            // 'images/reading_girl.png',
            // for apk build:
            'assets/images/reading_girl.png',
            width: 180,
          ),
          PrimaryActionButton(
            text: "Restart",
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}
