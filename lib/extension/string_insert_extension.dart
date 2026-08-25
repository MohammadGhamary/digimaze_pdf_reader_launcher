extension StringInsertExtension on String {
  String insertAt(int index, String text) {
    if (index < 0 || index > length) {
      throw RangeError('Index out of bounds');
    }
    return substring(0, index) + text + substring(index);
  }
}