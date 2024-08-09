import 'dart:collection';

/// A list with a fixed length ([capacity]) that continuously overwrites the
/// oldest element as necessary
final class CircularBuffer<T> with ListMixin<T> {
  CircularBuffer({required this.capacity});

  /// Maximum number of elements
  final int capacity;

  final _buffer = <T>[];
  int _ptr = 0;

  /// Whether the queue capacity has been entirely consumed
  bool get isFilled => _buffer.length == capacity;

  @override
  void add(T element) {
    if (!isFilled) return _buffer.add(element);
    _buffer[_ptr] = element;
    _ptr++;
    if (_ptr == capacity) _ptr = 0;
  }

  int _calcActualIndex(int i) => (_ptr + i) % _buffer.length;

  @override
  T operator [](int index) {
    if (index < 0 || index >= _buffer.length) {
      throw RangeError.index(index, this);
    }
    return _buffer[_calcActualIndex(index)];
  }

  @override
  void operator []=(int index, T value) {
    if (index < 0 || index >= _buffer.length) {
      throw RangeError.index(index, this);
    }
    _buffer[_calcActualIndex(index)] = value;
  }

  /// Number of consumed elements of queue
  @override
  int get length => _buffer.length;

  /// It is forbidden to modify the length of a `CircularQueue`
  @override
  set length(int newLength) {
    throw UnsupportedError('Unable to resize a `CircularQueue`');
  }

  /// Empties the queue
  @override
  void clear() {
    _ptr = 0;
    _buffer.clear();
  }
}
