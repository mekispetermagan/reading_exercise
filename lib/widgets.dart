import 'package:flutter/material.dart';
import "reading_logic.dart" show ProgressStatus;

class PageFrame extends StatelessWidget {
  final Widget child;
  const PageFrame({
    required this.child,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox.expand(
            child: child,
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double fontSize;
  const PrimaryActionButton({
    required this.text,
    required this.onPressed,
    this.fontSize=24,
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
            fontSize: fontSize,
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

enum BarEdge {left, none, right}

class ProgressBarSegment extends StatelessWidget {
  final ProgressStatus status;
  final bool isCurrent;
  final BarEdge whichEdge;
  const ProgressBarSegment({
    required this.status,
    required this.isCurrent,
    required this.whichEdge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(1.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 15,
          decoration: BoxDecoration(
            color: switch(status) {
              ProgressStatus.unSolved => cs.surface,
              ProgressStatus.correct => cs.primaryContainer,
              ProgressStatus.wrong => cs.errorContainer
            },
            border: Border.all(
              color: isCurrent ? cs.onSurface : cs.outlineVariant,
              width: 1,
            ),
            borderRadius: switch (whichEdge) {
              BarEdge.left  => BorderRadius.horizontal(left: Radius.circular(9999)),
              BarEdge.right => BorderRadius.horizontal(right: Radius.circular(9999)),
              BarEdge.none  => BorderRadius.zero,
            },
          ),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final List<ProgressStatus> progressLog;
  final int current;
  const ProgressBar({
    required this.progressLog,
    required this.current,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final maxIndex = progressLog.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Row(
        children: <Widget>[
          for (int i=0; i<=maxIndex; i++)
          ProgressBarSegment(
            status: progressLog[i],
            isCurrent: i == current,
            whichEdge: i== 0
              ? BarEdge.left
              : i == maxIndex
                ? BarEdge.right
                : BarEdge.none,
          )
        ],
      ),
    );

  }
}

