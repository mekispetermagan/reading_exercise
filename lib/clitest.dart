import 'dart:io';
import "manager.dart";
import 'dart:convert';

// CLI interface: only for testing

// Reads data from file
Future<List<String>> loadData(String path) async {
  final text = await File(path).readAsString();
  final List<dynamic> list = jsonDecode(text) as List<dynamic>;
  return List<String>.from(list);
}

// CLI interface
Future<void> main() async {
  final manager = ExerciseManager();
  final data = await loadData('./assets/data/exercises.json');
  if (data.isEmpty) {
    print("No exercises found.");
    return; // early exit
  }
  manager.setData(data);

  while (true) {
    manager.generateExercise();

    String? userInput;
    while (!manager.canSubmit) {
      final sb = manager.sourceBank;
      final tb = manager.targetBank;
      if (sb == null || tb == null) break;
      List<String> sbToDisplay = [
        for (int i=0; i<sb.length; i++) "$i ${manager.labelFor(sb[i])}"
      ];
      print("Source: $sbToDisplay");
      List<String> tbToDisplay = [
        for (int i=0; i<tb.length; i++) "${sb.length+i} ${manager.labelFor(tb[i])}"
      ];
      print("Target: $tbToDisplay");
      userInput = stdin.readLineSync();
      try {
        int? i = userInput != null ? int.parse(userInput) : null;
        if (i != null) manager.toggleWord((sb+tb)[i]);
      } catch(e) {
        continue;
      };
    }
    print(manager.checkSubmission() ? "Correct!\n" : "Incorrect!\n");
    if (!manager.isLastExercise) {manager.nextExercise();}
    else {break;}
  }
}