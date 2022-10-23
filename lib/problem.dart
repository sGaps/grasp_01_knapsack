
// Represents a problem for a given instance.
class Problem {
  double capacity;
  List<double> weights;
  List<double> values;

  Problem(this.capacity, this.weights, this.values);

  int get length => weights.length;

  @override
  String toString() {
      return "Problem(capacity = $capacity, weights = $weights, values = $values)";
  }
}
