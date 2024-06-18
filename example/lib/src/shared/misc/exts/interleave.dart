extension IterableExt<E> on Iterable<E> {
  Iterable<E> interleave(E separator) sync* {
    for (int i = 0; i < length; i++) {
      yield elementAt(i);
      if (i < length - 1) yield separator;
    }
  }
}
