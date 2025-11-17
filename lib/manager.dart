// Reading exercise app: pure dart logic
// ExerciseManager provides an API for UI (CLI or GUI)

// Holds all exercise state and logic:
//sentences, current index, banks, score, etc.
//Does not depend on Flutter.
class ExerciseManager {
  // Original vs working: original keeps the input as-is;
  // working is shuffled and used to iterate through exercises.
  List<String>? _originalSentences;
  List<String>? _workingSentences;
  List<String>? _wordsInOrder;
  List<int>? _sourceBank;
  List<int>? _targetBank;
  int _currentIndex = 0;
  int _score = 0;

  // True when the user has moved all words into the
  // target bank and the submission is ready to check.
  bool get canSubmit {
    final s = _sourceBank;
    final t = _targetBank;
    final w = _wordsInOrder;
    if (s == null || t == null || w == null) return false;
    return s.isEmpty && t.length == w.length;
  }

  // True when the currentIndex points to
  // the last sentence in workingSentences.
  bool get isLastExercise {
    final s = _workingSentences;
    if (s == null) return false;
    return _currentIndex == s.length - 1;
  }

  // Returns the index of the current sentence in the original list
  // (used e.g. for matching audio). Null if state is invalid.
  // using _currentIndex is temporary; id will be in json
  int? get exerciseId {
    final os = _originalSentences;
    final s = _workingSentences;
    if (os == null || s == null) return null;
    if (_currentIndex < 0 || s.length <= _currentIndex) return null;
    return os.indexOf(s[_currentIndex]);
  }

  // Read-only view of the source word index lists for the UI.
  // Null if no exercise is prepared.
  List<int>? get sourceBank {
    final s = _sourceBank;
    return s != null ? List.unmodifiable(s) : null;
  }

  // Read-only view of the target word index lists for the UI.
  // Null if no exercise is prepared.
  List<int>? get targetBank {
    final t = _targetBank;
    return t != null ? List.unmodifiable(t) : null;
  }

  // Total number of correctly solved exercises in this session.
  int get score => _score;

  // Score as a 0–1 fraction of correctly solved exercises
  // over all exercises. Null if no sentences.
  double? get accuracy {
    final s = _workingSentences;
    return s != null && s.isNotEmpty ? _score / s.length : null;}

  // Load a new set of sentences, create a shuffled working copy,
  // and reset all progress.
  void setData(List<String> data) {
    _originalSentences = [...data];
    _workingSentences = [...data]..shuffle();
    reset();
  }

  // Reset the whole session for the current data: go back
  // to the first exercise, clear banks, and reset score.
  void reset() {
    _currentIndex = 0;
    _wordsInOrder = null;
    _sourceBank = null;
    _targetBank = null;
    _score = 0;
  }

  // Prepare the current exercise:
  // - split the sentence into words,
  // - create a shuffled source bank, and
  // - clear the target bank.
  // Clears state if currentIndex is out of range.
  void generateExercise() {
    final s = _workingSentences;
    if (s == null) return;
    if (0 <= _currentIndex && _currentIndex < s.length) {
    _wordsInOrder = _extractWords(s[_currentIndex]);
    _sourceBank = _generateSourceBank(_wordsInOrder!);
    _targetBank = [];
    } else {
    _wordsInOrder = null;
    _sourceBank = null;
    _targetBank = null;
    }
  }

  // Advance to the next sentence and clear all exercise-specific state
  // so generateExercise can prepare the next one.
  // Why not part of checkSubmission:
  // The UI decides when to move forward
  // (eg. after a failed submission it can regenerate the exercise and
  // let the user try once more)
  void nextExercise() {
    _currentIndex++;
    _wordsInOrder = null;
    _sourceBank = null;
    _targetBank = null;
  }

  // Extract words from the sentence using a regex.
  // English alphabet, apostrophies within a word
  // matches: its, it's, Rock'n'Roll
  // non-matches: boys', 'em, we''re
  List<String> _extractWords(String text) =>
    RegExp(r"[A-Za-z]+('[A-Za-z]+)*").allMatches(text).map((m) => m.group(0)!).toList();

  // Create a shuffled list of word indices [0..length-1]
  // for the source bank.
  List<int> _generateSourceBank(List<String> words) =>
    List.generate(words.length, (i) => i)..shuffle();

  // Return the word at the given index in the current sentence.
  // Throws if no exercise is loaded or id is out of range.
  String labelFor(int id) {
    final w = _wordsInOrder;
    if (w == null) throw StateError("No data!");
    if (id < 0 || w.length <= id) {
      throw RangeError.index(id, w, 'id', 'Invalid word id');
    }
    return w[id];
  }

  // Move a word id between source and target banks.
  // If the id is not found in either bank, throws an ArgumentError.
  void toggleWord(int id) {
    // helper for single scan
    bool takeFrom(int id, List<int> bank) {
      int i = bank.indexOf(id);
      if (i == -1) return false;
      bank.removeAt(i);
      return true;
    }
    final s = _sourceBank;
    final t = _targetBank;
    if (s == null || t == null) throw StateError("No data!");

    if (takeFrom(id, s)) {
      t.add(id);
      return;
    }
    if (takeFrom(id, t)) {
      s.add(id);
      return;
    }
    throw ArgumentError("Wrong id!");
  }

  // Check whether the submitted word order matches the original sentence (by comparing words, not ids).
  // If correct, increment score. Returns true on success, false otherwise.
  // Compares the submitted word list (_targetBank) to the original word list (_wordsInOrder).
  // id comparison would not be sufficient because of potential duplicate words.
  bool checkSubmission() {
    if (!canSubmit) return false;
    final t = _targetBank;
    final w = _wordsInOrder;
    // canSubmit guarantees that _targetBank and _wordsInOrder cannot be null;
    // this test is just extra safety:
    if (t == null || w == null) return false;
    bool result = [for (int i=0; i<t.length; i++) w[t[i]] == w[i]].every((t) => t);
    if (result) _score++;
    return result;
  }

}