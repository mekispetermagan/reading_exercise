// Reading exercise app: pure dart logic
// SelectionManager and ExerciseManager provide APIs for UI

class ReadingExercise {
  final String category;
  final String title;
  final List<String> sentences;

  const ReadingExercise({
    required this.category,
    required this.title,
    required this.sentences,
  });

  factory ReadingExercise.fromJson({
    required Map<String, dynamic> json,
  }) {
    if (json["category"] == null) {
      throw FormatException("Malformed json: missing category key.");
    }
    if (json["title"] == null) {
      throw FormatException("Malformed json: missing title key.");
    }
    if (json["sentences"] == null) {
      throw FormatException("Malformed json: missing sentences key.");
    }
    if (json["category"] is! String) {
      throw FormatException("Malformed json: category must be a string: ${json["category"]}");
    }
    if (json["title"] is! String) {
      throw FormatException("Malformed json: title must be a string: ${json["title"]}");
    }
    if (json["sentences"] is! List) {
      throw FormatException("Malformed json: sentences must be a list:"
        " ${json["sentences"]}");
    }
    for (final s in json["sentences"]) {
      if (s is! String) {
        throw FormatException("Items in sentences must be strings: $s");
      }
    }
    return ReadingExercise(
      category: json["category"].toString(),
      title: json["title"].toString(),
      sentences: [ for (final s in json["sentences"]) s.toString() ],
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
    final List<List<String>> candidates = [
      for (final item in data)
      if (item.title == title)
      item.sentences
    ];
    if (candidates.isEmpty) {
      throw ArgumentError("Selected item doesn't exist: $title");
    }
    if (1 < candidates.length) {
      throw ArgumentError("Ambiguous selection: $title");
    }
    return ExerciseManager(sentences: candidates.single);
  }
}


// Exercise logic
class ExerciseManager {
  // Original vs working: original keeps the input as-is;
  // working is shuffled and used to iterate through exercises.
  final List<String> _originalSentences;
  final List<String> _workingSentences;
  late List<String> _wordsInOrder;
  late List<int> _sourceBank;
  late List<int> _targetBank;
  int _currentIndex = 0;
  int _score = 0;

  ExerciseManager({
    required List<String> sentences
  }) : _originalSentences = [...sentences],
       _workingSentences = [...sentences]..shuffle()
  {
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

  List<int> get sourceBank => _sourceBank;
  List<int> get targetBank => _targetBank;
  int get score => _score;
  int get maxScore => _workingSentences.length;

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
  // English alphabet, apostrophies within a word
  // matches: its, it's, Rock'n'Roll
  // non-matches: boys', 'em, we''re
  List<String> _extractWords(String text) =>
    RegExp(r"[A-Za-z]+('[A-Za-z]+)*").allMatches(text).map((m) => m.group(0)!).toList();

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

  bool get isCorrect {
    final tb = _targetBank;
    final wo = _wordsInOrder;
    bool matchAt(int i) => wo[tb[i]] == wo[i];
    bool result = [ for (int i=0; i<tb.length; i++) matchAt(i) ]
      .every((t) => t);
    if (result) _score++;
    return result;
  }
}
