// Adapted from https://github.com/kranfix/dart-circularbuffer under MIT license

import 'dart:collection';

class CircularBuffer<T> with ListMixin<T> {
  CircularBuffer(this.capacity)
      : assert(capacity > 1, 'CircularBuffer must have a positive capacity'),
        _buf = [];

  final List<T> _buf;
  int _start = 0;

  final int capacity;
  bool get isFilled => _buf.length == capacity;
  bool get isUnfilled => _buf.length < capacity;

  @override
  T operator [](int index) {
    if (index >= 0 && index < _buf.length) {
      return _buf[(_start + index) % _buf.length];
    }
    throw RangeError.index(index, this);
  }

  @override
  void operator []=(int index, T value) {
    if (index >= 0 && index < _buf.length) {
      _buf[(_start + index) % _buf.length] = value;
    } else {
      throw RangeError.index(index, this);
    }
  }

  @override
  void add(T element) {
    if (isUnfilled) {
      assert(_start == 0, 'Internal buffer grown from a bad state');
      _buf.add(element);
      return;
    }

    _buf[_start] = element;
    _start++;
    if (_start == capacity) {
      _start = 0;
    }
  }

  @override
  void clear() {
    _start = 0;
    _buf.clear();
  }

  @override
  int get length => _buf.length;

  @override
  set length(int newLength) =>
      throw UnsupportedError('Cannot resize a CircularBuffer.');
}
