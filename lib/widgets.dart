import 'package:flutter/material.dart';
import "reading_logic.dart" show ProgressStatus;

class ScreenShell extends StatelessWidget {
  final VoidCallback? onRestart;
  final Widget child;
  const ScreenShell({
    required this.child,
    required this.onRestart,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final or = onRestart;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (or != null) {or();}
        else {Navigator.of(context).pop();}
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox.expand(
              child: child,
            ),
          ),
        ),
      // floatingActionButton: or != null
      //   ? FloatingActionButton.small(
      //     onPressed: or,
      //     child: const Icon(Icons.restart_alt_outlined),
      //   )
      //   : null,
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  final String text;
  final String nullText;
  final VoidCallback? onPressed;
  final double fontSize;
  const PrimaryActionButton({
    required this.text,
    required this.onPressed,
    this.fontSize=24,
    nullText,
    super.key,
  }) : nullText = nullText ?? text;

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
          onPressed != null ? text : nullText,
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
        padding: EdgeInsets.all(2.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 24,
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

