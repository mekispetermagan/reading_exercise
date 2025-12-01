// Reading exercise app: pure dart logic
// SelectionManager and ExerciseManager provide APIs for UI

class ReadingExercise {
  final String category;
  final String id;
  final String title;
  final List<String> sentences;

  const ReadingExercise({
    required this.category,
    required this.id,
    required this.title,
    required this.sentences,
  });

  factory ReadingExercise.fromJson({
    required Map<String, dynamic> json,
  }) {
    String readString(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException("Malformed json: missing $key key.");
      }
      if (value is! String) {
        throw FormatException(
          "Malformed json: $key must be a string: $value",
        );
      }
      return value;
    }

    List<String> readStringList(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException("Malformed json: missing $key key.");
      }
      if (value is! List) {
        throw FormatException(
          "Malformed json: $key must be a list: $value",
        );
      }
      final result = <String>[];
      for (final item in value) {
        if (item is! String) {
          throw FormatException(
            "Items in $key must be strings: $item",
          );
        }
        result.add(item);
      }
      return result;
    }

    return ReadingExercise(
      category: readString("category"),
      id: readString("id"),
      title: readString("title"),
      sentences: readStringList("sentences"),
    );
  }
}

typedef TitleItem = ({String artist, String title});
typedef Sentences = List<String>;

/// Holds the logic of the  exercise selection
class SelectionManager {
  final List<ReadingExercise> data;
  String? _selectedCategory;
  SelectionManager({
    required this.data,
  });

  factory SelectionManager.fromJson({
    required List<Map<String, dynamic>> jsonData
  }) {
    return SelectionManager(
      data: [for (final json in jsonData) ReadingExercise.fromJson(json: json)],
    );
  }

  List<String> get categories
    => {for (final item in data) item.category}.toList();

  set selectedCategory(String c) {
    if (!categories.contains(c)) {
      throw ArgumentError("Unknown category: $c");
    }
    _selectedCategory = c;
    }

  List<String> get titles => [
    for (final item in data)
    if (_selectedCategory != null ? item.category == _selectedCategory : true)
    item.title
  ];

  ExerciseManager exerciseManagerWith(String title) {
    final List<ReadingExercise> candidates = [
      for (final item in data)
      if (item.title == title)
      item
    ];
    if (candidates.isEmpty) {
      throw ArgumentError("Selected item doesn't exist: $title");
    }
    if (1 < candidates.length) {
      throw ArgumentError("Ambiguous selection: $title");
    }
    final ReadingExercise match = candidates.single;
    return ExerciseManager(
      sentences: match.sentences,
      exerciseId: match.id,
      );
  }
}

enum ProgressStatus {unSolved, correct, wrong}

// Exercise logic
class ExerciseManager {
  // Original vs working: original keeps the input as-is;
  // working is shuffled and used to iterate through exercises.
  final List<String> _originalSentences;
  final List<String> _workingSentences;
  final String exerciseId;
  late List<String> _wordsInOrder;
  late List<int> _sourceBank;
  late List<int> _targetBank;
  int _currentIndex = 0;
  int _score = 0;
  late List<ProgressStatus> _progressLog;

  ExerciseManager({
    required List<String> sentences,
    required this.exerciseId,
  }) : _originalSentences = [...sentences],
       _workingSentences = [...sentences]..shuffle()
  {
    _progressLog = List<ProgressStatus>.generate(
      _workingSentences.length,
      (_) => ProgressStatus.unSolved,
      growable: false,
    );
    generateExercise();

  }

  bool get canSubmit {
    final s = _sourceBank;
    final t = _targetBank;
    final w = _wordsInOrder;
    return s.isEmpty && t.length == w.length;
  }

  bool get isLastExercise => _currentIndex == _workingSentences.length - 1;

  int? get sentenceId {
    final os = _originalSentences;
    final s = _workingSentences;
    if (_currentIndex < 0 || s.length <= _currentIndex) return null;
    return os.indexOf(s[_currentIndex]);
  }

  String? get id => "${exerciseId}_$sentenceId";

  List<int> get sourceBank => _sourceBank;
  List<int> get targetBank => _targetBank;
  int get score => _score;
  int get maxScore => _workingSentences.length;
  bool get correctSubmission => _progressLog[_currentIndex] == ProgressStatus.correct;
  List<ProgressStatus> get progressLog => _progressLog;
  int get current => _currentIndex;

  // Reset the whole session for the current data: go back
  // to the first exercise, clear banks, and reset score.
  void reset() {
    _currentIndex = 0;
    _score = 0;
    generateExercise();
  }

  // Prepare the current exercise:
  // - split the sentence into words,
  // - create a shuffled source bank, and
  // - clear the target bank.
  // Clears state if currentIndex is out of range.
  void generateExercise() {
    final s = _workingSentences;
    if (0 <= _currentIndex && _currentIndex < s.length) {
    _wordsInOrder = _extractWords(s[_currentIndex]);
    _sourceBank = _generateSourceBank(_wordsInOrder);
    _targetBank = [];
    } else {
    _wordsInOrder = [];
    _sourceBank = [];
    _targetBank = [];
    }
  }

  void nextExercise() {
    _currentIndex++;
    generateExercise();
  }

  // Extract words from the sentence using a regex.
  // English alphabet plus Hungarian accented vowels,
  // apostrophies within a word
  // matches: its, it's, Rock'n'Roll
  // non-matches: boys', 'em, we''re
  List<String> _extractWords(String text) =>
    RegExp(r"[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+('[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+)*")
      .allMatches(text).map((m) => m.group(0)!).toList();

  List<int> _generateSourceBank(List<String> words) =>
    List.generate(words.length, (i) => i)..shuffle();

  // Word at the given index in the current sentence.
  String labelFor(int id) {
    final w = _wordsInOrder;
    if (id < 0 || w.length <= id) {
      throw RangeError.index(id, w, 'id', 'Invalid word id');
    }
    return w[id];
  }

  // Move a word id between source and target banks.
  // If the id is not found in either bank, throws an ArgumentError.
  void toggleWord(int id) {
    bool takeFrom(int id, List<int> bank) {
      int i = bank.indexOf(id);
      if (i == -1) return false;
      bank.removeAt(i);
      return true;
    }

    if (takeFrom(id, _sourceBank)) {
      _targetBank.add(id);
      return;
    }
    if (takeFrom(id, _targetBank)) {
      _sourceBank.add(id);
      return;
    }
    throw ArgumentError("Wrong id!");
  }

  void submit() {
    final tb = _targetBank;
    final wo = _wordsInOrder;
    bool matchAt(int i) => wo[tb[i]].toLowerCase() == wo[i].toLowerCase();
    bool result = [ for (int i=0; i<tb.length; i++) matchAt(i) ]
      .every((t) => t);
    if (result) {
      _score++;
      _progressLog[_currentIndex] = ProgressStatus.correct;
    } else {
      _progressLog[_currentIndex] = ProgressStatus.wrong;
    }
  }
}
