// Reading exercise app: pure dart logic
// ExerciseManager provides an API for UI (CLI or GUI)

class ExerciseManager {
  List<String>? _originalSentences;
  List<String>? _sentences;
  List<String>? _wordsInOrder;
  List<int>? _sourceBank;
  List<int>? _targetBank;
  int _i = 0;
  int _score = 0;

  bool get canSubmit {
    final s = _sourceBank;
    final t = _targetBank;
    final w = _wordsInOrder;
    if (s == null || t == null || w == null) return false;
    return s.isEmpty && t.length == w.length;
  }

  bool get isLastExercise {
    final s = _sentences;
    if (s == null) return false;
    return _i == s.length - 1;
  }

  // using _i is temporary; id will be in json
  int? get exerciseId {
    final os = _originalSentences;
    final s = _sentences;
    if (os == null || s == null) return null;
    return os.indexOf(s[_i]);
  }

  List<int>? get sourceBank {
    final s = _sourceBank;
    return s != null ? List.unmodifiable(s) : null;
  }

  List<int>? get targetBank {
    final t = _targetBank;
    return t != null ? List.unmodifiable(t) : null;
}

  void setData(List<String> data) {
    _originalSentences = [...data];
    _sentences = [...data]..shuffle();
    reset();
  }

  void reset() {
    _i = 0;
    _wordsInOrder = null;
    _sourceBank = null;
    _targetBank = null;
  }

  void generateExercise() {
    final s = _sentences;
    if (s == null) return;
    if (0 <= _i && _i < s.length) {
    _wordsInOrder = _extractWords(s[_i]);
    _sourceBank = _getSourceBank(_wordsInOrder!);
    _targetBank = [];
    }
  }

  // the UI decides when to move forward
  // (eg. after a failed submission it can regenerate the exercise and
  // let the user try once more)
  void next() {
    _i++;
    _wordsInOrder = null;
    _sourceBank = null;
    _targetBank = null;
  }

  // English alphabet, apostrophies within a word
  // matches: its, it's, Rock'n'Roll
  // non-matches: boys', 'em, we''re
  List<String> _extractWords(String text) =>
    RegExp(r"[A-Za-z]+('[A-Za-z]+)*").allMatches(text).map((m) => m.group(0)!).toList();

  List<int> _getSourceBank(List<String> words) =>
    List.generate(words.length, (i) => i)..shuffle();

  String labelFor(int id) {
    final w = _wordsInOrder;
    if (w == null) throw "No data.";
    if (id < 0 || w.length <= id) {
      throw RangeError.index(id, w, 'id', 'Invalid word id');
    }
    return w[id];
  }

  void move(int id) {
    // helper for single scan
    bool takeFrom(int id, List<int> bank) {
      int i = bank.indexOf(id);
      if (i == -1) return false;
      bank.removeAt(i);
      return true;
    }
    final s = _sourceBank;
    final t = _targetBank;
    if (s == null || t == null) throw "no data!";

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
    return result;
  }

}