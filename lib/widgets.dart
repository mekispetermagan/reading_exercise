import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const PrimaryActionButton({
    required this.text,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          cs.primaryContainer,
        ),
        foregroundColor: WidgetStatePropertyAll(
          cs.onPrimaryContainer,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          onPressed != null ? text : "Wait...",
          style: TextStyle(
            fontSize: 24,
          ),
          ),
      ),
    );
  }
}

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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 18,
              color: cs.onSecondaryContainer,
            ),
          ),
        )
      )

    );
  }
}
