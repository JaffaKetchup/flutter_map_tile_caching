// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: parameter_assignments

import 'dart:math';

/// Earcutting triangulation algorithm, ported (with minor API differences) from
/// [earcut4j/earcut4j](https://github.com/earcut4j/earcut4j) which itself is
/// ported from [mapbox/earcut](https://github.com/mapbox/earcut).
final class Earcut {
  /// Triangulates the given polygon
  ///
  /// [polygonVertices] should be a list of all the [Point]s defining
  /// the polygon.
  ///
  /// [holeIndices] should be a list of hole indicies, if any. For example,
  /// `[5, 8]` for a 12-vertice input would mean one hole with vertices 5-7 and
  /// another with 8-11.
  ///
  /// Returns a list of vertice indicies where a group of 3 forms a triangle.
  static List<int> triangulateFromPoints(
    List<Point<double>> polygonVertices, {
    List<int>? holeIndices,
  }) =>
      triangulateRaw(
        polygonVertices.map((e) => [e.x, e.y]).expand((e) => e).toList(),
        holeIndices: holeIndices,
      );

  /// Triangulates the given polygon
  ///
  /// [polygonVertices] should be a flat list of all the coordinates defining
  /// the polygon. If [dimensions] is 2, it is expected to be in the format
  /// `[x0, y0, x1, y1, x2, y2]`. If [dimensions] is 3, it is expected to be in
  /// the format `[x0, y0, z0, x1, y1, z1, x2, y2, z2]`.
  ///
  /// [holeIndices] should be a list of hole indicies, if any. For example,
  /// `[5, 8]` for a 12-vertice input would mean one hole with vertices 5-7 and
  /// another with 8-11.
  ///
  /// Returns a list of vertice indicies where a group of 3 forms a triangle.
  static List<int> triangulateRaw(
    List<double> polygonVertices, {
    List<int>? holeIndices,
    int dimensions = 2,
  }) {
    final bool hasHoles = holeIndices != null && holeIndices.isNotEmpty;
    final int outerLen =
        hasHoles ? holeIndices[0] * dimensions : polygonVertices.length;

    _Node? outerNode =
        _linkedList(polygonVertices, 0, outerLen, dimensions, clockwise: true);

    final triangles = <int>[];

    if (outerNode == null || outerNode.next == outerNode.prev) {
      return triangles;
    }

    double minX = 0;
    double minY = 0;
    double maxX = 0;
    double maxY = 0;
    double invSize = 4.9E-324;

    if (hasHoles) {
      outerNode =
          _eliminateHoles(polygonVertices, holeIndices, outerNode, dimensions);
    }

    // if the shape is not too simple, we'll use z-order curve hash later;
    // calculate polygon bbox
    if (polygonVertices.length > 80 * dimensions) {
      minX = maxX = polygonVertices[0];
      minY = maxY = polygonVertices[1];

      for (int i = dimensions; i < outerLen; i += dimensions) {
        final double x = polygonVertices[i];
        final double y = polygonVertices[i + 1];
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }

      // minX, minY and size are later used to transform coords into
      // ints for z-order calculation
      invSize = max(maxX - minX, maxY - minY);
      invSize = invSize != 0.0 ? 1.0 / invSize : 0.0;
    }

    _earcutLinked(
      outerNode,
      triangles,
      dimensions,
      minX,
      minY,
      invSize,
      -2147483648,
    );

    return triangles;
  }

  static void _earcutLinked(
    _Node? ear,
    List<int> triangles,
    int dim,
    double minX,
    double minY,
    double invSize,
    int pass,
  ) {
    if (ear == null) return;

    // interlink polygon nodes in z-order
    if (pass == -2147483648 && invSize != 4.9E-324) {
      _indexCurve(ear, minX, minY, invSize);
    }

    _Node? stop = ear;

    // iterate through ears, slicing them one by one
    while (ear!.prev != ear.next) {
      final prev = ear.prev;
      final next = ear.next;

      if (invSize != 4.9E-324
          ? _isEarHashed(ear, minX, minY, invSize)
          : _isEar(ear)) {
        // cut off the triangle
        triangles
          ..add(prev!.i ~/ dim)
          ..add(ear.i ~/ dim)
          ..add(next!.i ~/ dim);

        _removeNode(ear);

        // skipping the next vertice leads to less sliver triangles
        ear = next.next;
        stop = next.next;

        continue;
      }

      ear = next;

      // if we looped through the whole remaining polygon and can't find
      // any more ears
      if (ear == stop) {
        // try filtering points and slicing again
        if (pass == -2147483648) {
          _earcutLinked(
            _filterPoints(ear, null),
            triangles,
            dim,
            minX,
            minY,
            invSize,
            1,
          );

          // if this didn't work, try curing all small
          // self-intersections locally
        } else if (pass == 1) {
          ear = _cureLocalIntersections(
            _filterPoints(ear, null)!,
            triangles,
            dim,
          );
          _earcutLinked(ear, triangles, dim, minX, minY, invSize, 2);

          // as a last resort, try splitting the remaining polygon
          // into two
        } else if (pass == 2) {
          _splitEarcut(ear!, triangles, dim, minX, minY, invSize);
        }

        break;
      }
    }
  }

  static void _splitEarcut(
    _Node start,
    List<int> triangles,
    int dim,
    double minX,
    double minY,
    double size,
  ) {
    // look for a valid diagonal that divides the polygon into two
    _Node a = start;
    do {
      _Node? b = a.next!.next;
      while (b != a.prev) {
        if (a.i != b!.i && _isValidDiagonal(a, b)) {
          // split the polygon in two by the diagonal
          _Node c = _splitPolygon(a, b);

          // filter colinear points around the cuts
          a = _filterPoints(a, a.next)!;
          c = _filterPoints(c, c.next)!;

          // run earcut on each half
          _earcutLinked(a, triangles, dim, minX, minY, size, -2147483648);
          _earcutLinked(c, triangles, dim, minX, minY, size, -2147483648);
          return;
        }
        b = b.next;
      }
      a = a.next!;
    } while (a != start);
  }

  static bool _isValidDiagonal(_Node a, _Node b) =>
      a.next!.i != b.i &&
      a.prev!.i != b.i &&
      !_intersectsPolygon(a, b) && // dones't intersect other edges
      (_locallyInside(a, b) &&
              _locallyInside(b, a) &&
              _middleInside(a, b) && // locally visible
              (_area(a.prev!, a, b.prev!) != 0 ||
                  _area(a, b.prev!, b) !=
                      0) || // does not create opposite-facing sectors
          _equals(a, b) &&
              _area(a.prev!, a, a.next!) > 0 &&
              _area(b.prev!, b, b.next!) > 0); // special zero-length case

  static bool _middleInside(_Node a, _Node b) {
    _Node p = a;
    bool inside = false;
    final px = (a.x + b.x) / 2;
    final py = (a.y + b.y) / 2;
    do {
      if (((p.y > py) != (p.next!.y > py)) &&
          (px < (p.next!.x - p.x) * (py - p.y) / (p.next!.y - p.y) + p.x)) {
        inside = !inside;
      }
      p = p.next!;
    } while (p != a);

    return inside;
  }

  static bool _intersectsPolygon(_Node a, _Node b) {
    _Node p = a;
    do {
      if (p.i != a.i &&
          p.next!.i != a.i &&
          p.i != b.i &&
          p.next!.i != b.i &&
          _intersects(p, p.next, a, b)) {
        return true;
      }
      p = p.next!;
    } while (p != a);

    return false;
  }

  static bool _intersects(_Node p1, _Node? q1, _Node p2, _Node? q2) {
    if ((_equals(p1, p2) && _equals(q1!, q2!)) ||
        (_equals(p1, q2!) && _equals(p2, q1!))) {
      return true;
    }
    final o1 = _sign(_area(p1, q1!, p2));
    final o2 = _sign(_area(p1, q1, q2));
    final o3 = _sign(_area(p2, q2, p1));
    final o4 = _sign(_area(p2, q2, q1));

    if (o1 != o2 && o3 != o4) {
      return true; // general case
    }

    if (o1 == 0 && _onSegment(p1, p2, q1)) {
      return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
    }
    if (o2 == 0 && _onSegment(p1, q2, q1)) {
      return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
    }
    if (o3 == 0 && _onSegment(p2, p1, q2)) {
      return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
    }
    if (o4 == 0 && _onSegment(p2, q1, q2)) {
      return true; // p2, q2 and q1 are collinear and q1 lies on p2q2
    }

    return false;
  }

  // for collinear points p, q, r, check if point q lies on segment pr
  static bool _onSegment(_Node p, _Node q, _Node r) =>
      q.x <= max(p.x, r.x) &&
      q.x >= min(p.x, r.x) &&
      q.y <= max(p.y, r.y) &&
      q.y >= min(p.y, r.y);

  static double _sign(double num) => num > 0
      ? 1
      : num < 0
          ? -1
          : 0;

  static _Node? _cureLocalIntersections(
    _Node start,
    List<int> triangles,
    int dim,
  ) {
    _Node p = start;
    do {
      final _Node? a = p.prev;
      final b = p.next!.next;

      if (!_equals(a!, b!) &&
          _intersects(a, p, p.next!, b) &&
          _locallyInside(a, b) &&
          _locallyInside(b, a)) {
        triangles
          ..add(a.i ~/ dim)
          ..add(p.i ~/ dim)
          ..add(b.i ~/ dim);

        // remove two nodes involved
        _removeNode(p);
        _removeNode(p.next!);

        p = start = b;
      }
      p = p.next!;
    } while (p != start);

    return _filterPoints(p, null);
  }

  static bool _isEar(_Node ear) {
    final a = ear.prev;
    final b = ear;
    final c = ear.next;

    if (_area(a!, b, c!) >= 0) {
      return false; // reflex, can't be an ear
    }

    // now make sure we don't have other points inside the potential ear
    _Node? p = ear.next!.next;

    while (p != ear.prev) {
      if (_pointInTriangle(a.x, a.y, b.x, b.y, c.x, c.y, p!.x, p.y) &&
          _area(p.prev!, p, p.next!) >= 0) {
        return false;
      }
      p = p.next;
    }

    return true;
  }

  static bool _isEarHashed(
    _Node ear,
    double minX,
    double minY,
    double invSize,
  ) {
    final a = ear.prev!;
    final b = ear;
    final c = ear.next!;

    if (_area(a, b, c) >= 0) {
      return false; // reflex, can't be an ear
    }

    // triangle bbox; min & max are calculated like this for speed

    final minTX = a.x < b.x ? (a.x < c.x ? a.x : c.x) : (b.x < c.x ? b.x : c.x);
    final minTY = a.y < b.y ? (a.y < c.y ? a.y : c.y) : (b.y < c.y ? b.y : c.y);
    final maxTX = a.x > b.x ? (a.x > c.x ? a.x : c.x) : (b.x > c.x ? b.x : c.x);
    final maxTY = a.y > b.y ? (a.y > c.y ? a.y : c.y) : (b.y > c.y ? b.y : c.y);

    // z-order range for the current triangle bbox;
    final minZ = _zOrder(minTX, minTY, minX, minY, invSize);
    final maxZ = _zOrder(maxTX, maxTY, minX, minY, invSize);

    // first look for points inside the triangle in increasing z-order
    _Node? p = ear.prevZ;
    _Node? n = ear.nextZ;

    while (p != null && p.z >= minZ && n != null && n.z <= maxZ) {
      if (p != ear.prev &&
          p != ear.next &&
          _pointInTriangle(a.x, a.y, b.x, b.y, c.x, c.y, p.x, p.y) &&
          _area(p.prev!, p, p.next!) >= 0) return false;
      p = p.prevZ;

      if (n != ear.prev &&
          n != ear.next &&
          _pointInTriangle(a.x, a.y, b.x, b.y, c.x, c.y, n.x, n.y) &&
          _area(n.prev!, n, n.next!) >= 0) return false;
      n = n.nextZ;
    }

    // look for remaining points in decreasing z-order
    while (p != null && p.z >= minZ) {
      if (p != ear.prev &&
          p != ear.next &&
          _pointInTriangle(a.x, a.y, b.x, b.y, c.x, c.y, p.x, p.y) &&
          _area(p.prev!, p, p.next!) >= 0) return false;
      p = p.prevZ;
    }

    // look for remaining points in increasing z-order
    while (n != null && n.z <= maxZ) {
      if (n != ear.prev &&
          n != ear.next &&
          _pointInTriangle(a.x, a.y, b.x, b.y, c.x, c.y, n.x, n.y) &&
          _area(n.prev!, n, n.next!) >= 0) return false;
      n = n.nextZ;
    }

    return true;
  }

  // z-order of a point given coords and inverse of the longer side of data bbox
  static int _zOrder(
    double x,
    double y,
    double minX,
    double minY,
    double invSize,
  ) {
    // coords are transformed into non-negative 15-bit int range
    int lx = (32767 * (x - minX) * invSize).toInt();
    int ly = (32767 * (y - minY) * invSize).toInt();

    lx = (lx | (lx << 8)) & 0x00FF00FF;
    lx = (lx | (lx << 4)) & 0x0F0F0F0F;
    lx = (lx | (lx << 2)) & 0x33333333;
    lx = (lx | (lx << 1)) & 0x55555555;

    ly = (ly | (ly << 8)) & 0x00FF00FF;
    ly = (ly | (ly << 4)) & 0x0F0F0F0F;
    ly = (ly | (ly << 2)) & 0x33333333;
    ly = (ly | (ly << 1)) & 0x55555555;

    return lx | (ly << 1);
  }

  static void _indexCurve(
    _Node start,
    double minX,
    double minY,
    double invSize,
  ) {
    _Node p = start;
    do {
      if (p.z == 4.9E-324) {
        p.z = _zOrder(p.x, p.y, minX, minY, invSize).toDouble();
      }
      p
        ..prevZ = p.prev
        ..nextZ = p.next;
      p = p.next!;
    } while (p != start);

    p.prevZ!.nextZ = null;
    p.prevZ = null;

    _sortLinked(p);
  }

  static _Node? _sortLinked(_Node? list) {
    int inSize = 1;

    int numMerges;
    do {
      _Node? p = list;
      list = null;
      _Node? tail;
      numMerges = 0;

      while (p != null) {
        numMerges++;
        _Node? q = p;
        int pSize = 0;
        for (int i = 0; i < inSize; i++) {
          pSize++;
          q = q?.nextZ;
          if (q == null) {
            break;
          }
        }

        int qSize = inSize;

        while (pSize > 0 || (qSize > 0 && q != null)) {
          _Node? e;
          if (pSize == 0) {
            e = q;
            q = q!.nextZ;
            qSize--;
          } else if (qSize == 0 || q == null) {
            e = p;
            p = p!.nextZ;
            pSize--;
          } else if (p!.z <= q.z) {
            e = p;
            p = p.nextZ;
            pSize--;
          } else {
            e = q;
            q = q.nextZ;
            qSize--;
          }

          if (tail != null) {
            tail.nextZ = e;
          } else {
            list = e;
          }

          e!.prevZ = tail;
          tail = e;
        }

        p = q;
      }

      tail!.nextZ = null;
      inSize *= 2;
    } while (numMerges > 1);

    return list;
  }

  static _Node? _eliminateHoles(
    List<double> data,
    List<int> holeIndices,
    _Node outerNode,
    int dim,
  ) {
    final queue = <_Node>[];

    final int len = holeIndices.length;
    for (int i = 0; i < len; i++) {
      final int start = holeIndices[i] * dim;
      final int end = i < len - 1 ? holeIndices[i + 1] * dim : data.length;
      final _Node? list = _linkedList(data, start, end, dim, clockwise: false);
      if (list == list?.next) list?.steiner = true;
      queue.add(_getLeftmost(list!));
    }

    queue.sort((a, b) {
      if (a.x - b.x > 0) {
        return 1;
      } else if (a.x - b.x < 0) {
        return -1;
      }
      return 0;
    });

    for (final _Node node in queue) {
      _eliminateHole(node, outerNode);
      outerNode = _filterPoints(outerNode, outerNode.next)!;
    }

    return outerNode;
  }

  static _Node? _filterPoints(_Node? start, _Node? end) {
    if (start == null) return start;
    end ??= start;

    _Node p = start;
    bool again;

    do {
      again = false;

      if (!p.steiner && _equals(p, p.next!) ||
          _area(p.prev!, p, p.next!) == 0) {
        _removeNode(p);
        p = (end = p.prev)!;
        if (p == p.next) {
          break;
        }
        again = true;
      } else {
        p = p.next!;
      }
    } while (again || p != end);

    return end;
  }

  static bool _equals(_Node p1, _Node p2) => p1.x == p2.x && p1.y == p2.y;

  static double _area(_Node p, _Node q, _Node r) =>
      (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);

  static void _eliminateHole(_Node hole, _Node? outerNode) {
    outerNode = _findHoleBridge(hole, outerNode!);
    if (outerNode != null) {
      final _Node b = _splitPolygon(outerNode, hole);

      // filter collinear points around the cuts
      _filterPoints(outerNode, outerNode.next);
      _filterPoints(b, b.next);
    }
  }

  static _Node _splitPolygon(_Node a, _Node b) {
    final a2 = _Node(a.i, a.x, a.y);
    final b2 = _Node(b.i, b.x, b.y);
    final an = a.next!;
    final bp = b.prev!;

    a.next = b;
    b.prev = a;

    a2.next = an;
    an.prev = a2;

    b2.next = a2;
    a2.prev = b2;

    bp.next = b2;
    b2.prev = bp;

    return b2;
  }

  // David Eberly's algorithm for finding a bridge between hole and outer
  // polygon
  static _Node? _findHoleBridge(_Node hole, _Node outerNode) {
    _Node p = outerNode;
    final double hx = hole.x;
    final double hy = hole.y;
    double qx = -1.7976931348623157E308;
    _Node? m;

    // find a segment intersected by a ray from the hole's leftmost point to
    // the left;
    // segment's endpoint with lesser x will be potential connection point
    do {
      if (hy <= p.y && hy >= p.next!.y) {
        final double x =
            p.x + (hy - p.y) * (p.next!.x - p.x) / (p.next!.y - p.y);
        if (x <= hx && x > qx) {
          qx = x;
          if (x == hx) {
            if (hy == p.y) {
              return p;
            }
            if (hy == p.next!.y) {
              return p.next;
            }
          }
          m = p.x < p.next!.x ? p : p.next;
        }
      }
      p = p.next!;
    } while (p != outerNode);

    if (m == null) {
      return null;
    }

    if (hx == qx) {
      return m; // hole touches outer segment; pick leftmost endpoint
    }

    // look for points inside the triangle of hole point, segment
    // intersection and endpoint;
    // if there are no points found, we have a valid connection;
    // otherwise choose the point of the minimum angle with the ray as
    // connection point

    final _Node stop = m;
    final double mx = m.x;
    final double my = m.y;
    double tanMin = 1.7976931348623157E308;
    double tan;

    p = m;

    do {
      if (hx >= p.x &&
          p.x >= mx &&
          _pointInTriangle(
            hy < my ? hx : qx,
            hy,
            mx,
            my,
            hy < my ? qx : hx,
            hy,
            p.x,
            p.y,
          )) {
        tan = (hy - p.y).abs() / (hx - p.x); // tangential

        if (_locallyInside(p, hole) &&
            (tan < tanMin ||
                (tan == tanMin &&
                    (p.x > m!.x ||
                        (p.x == m.x && _sectorContainsSector(m, p)))))) {
          m = p;
          tanMin = tan;
        }
      }

      p = p.next!;
    } while (p != stop);

    return m;
  }

  static bool _locallyInside(_Node a, _Node? b) =>
      _area(a.prev!, a, a.next!) < 0
          ? _area(a, b!, a.next!) >= 0 && _area(a, a.prev!, b) >= 0
          : _area(a, b!, a.prev!) < 0 || _area(a, a.next!, b) < 0;

  // whether sector in vertex m contains sector in vertex p in the same
  // coordinates
  static bool _sectorContainsSector(_Node m, _Node p) =>
      _area(m.prev!, m, p.prev!) < 0 && _area(p.next!, m, m.next!) < 0;

  static bool _pointInTriangle(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double px,
    double py,
  ) =>
      (cx - px) * (ay - py) - (ax - px) * (cy - py) >= 0 &&
      (ax - px) * (by - py) - (bx - px) * (ay - py) >= 0 &&
      (bx - px) * (cy - py) - (cx - px) * (by - py) >= 0;

  static _Node _getLeftmost(_Node start) {
    _Node p = start;
    _Node leftmost = start;
    do {
      if (p.x < leftmost.x || (p.x == leftmost.x && p.y < leftmost.y)) {
        leftmost = p;
      }
      p = p.next!;
    } while (p != start);
    return leftmost;
  }

  static _Node? _linkedList(
    List<double> data,
    int start,
    int end,
    int dim, {
    required bool clockwise,
  }) {
    _Node? last;
    if (clockwise == (_signedArea(data, start, end, dim) > 0)) {
      for (int i = start; i < end; i += dim) {
        last = _insertNode(i, data[i], data[i + 1], last);
      }
    } else {
      for (int i = end - dim; i >= start; i -= dim) {
        last = _insertNode(i, data[i], data[i + 1], last);
      }
    }

    if (last != null && _equals(last, last.next!)) {
      _removeNode(last);
      last = last.next;
    }

    return last;
  }

  static void _removeNode(_Node p) {
    p.next!.prev = p.prev;
    p.prev!.next = p.next;

    p.prevZ?.nextZ = p.nextZ;

    p.nextZ?.prevZ = p.prevZ;
  }

  static _Node _insertNode(int i, double x, double y, _Node? last) {
    final _Node p = _Node(i, x, y);

    if (last == null) {
      p
        ..prev = p
        ..next = p;
    } else {
      p
        ..next = last.next
        ..prev = last;
      last.next!.prev = p;
      last.next = p;
    }
    return p;
  }

  static double _signedArea(List<double> data, int start, int end, int dim) {
    double sum = 0;
    int j = end - dim;
    for (int i = start; i < end; i += dim) {
      sum += (data[j] - data[i]) * (data[i + 1] + data[j + 1]);
      j = i;
    }
    return sum;
  }
}

class _Node {
  int i;
  double x;
  double y;
  double z;
  bool steiner;
  _Node? prev;
  _Node? next;
  _Node? prevZ;
  _Node? nextZ;

  _Node(this.i, this.x, this.y)
      : z = 4.9E-324,
        steiner = false;

  @override
  String toString() => 'i: $i, x: $x, y: $y, prev: $prev, next: $next';
}
