import 'dart:math' as math;
import 'package:grasp_01_knapsack/problem.dart';

const int ATTEMPTS_BY_ALTERNATIVE = 4;

/// The core of all solution of this GRASP implementation.
/// It encapsulates a list of boolean values which represents
/// all the objects included in the knapsack.
/// 
/// It holds data about the problem and cache to speed up the
/// calculations involved with grasp.
class Solution {
  int oneCount = 0;
  double _weight = 0.0;
  double _profit = 0.0;
  List<bool> objects;
  Problem p;

  // Raw constructor for Solutions.
  Solution(this.objects, this.p, {bool updateCache = true} ){
    if( updateCache ){
      refreshCache();
    }
  }

  // Given a problem, returns a solution with no elements adapted to it.
  factory Solution.zeroesFromProblem(Problem p){
    // A raw solution is only a bunch of bool values.
    List<bool> raw = List.filled(p.length, false);
    return Solution(raw, p, updateCache: false);
  }

  /// Constructs a random solution depending on the problem.
  /// Randomly fills some values with true.
  factory Solution.random(Problem p){
    const minimumPercent = 10.0;
    const maximumPercent = 90.0;

    math.Random generator = math.Random();
    int length      = p.length;
    int minimumOnes = length.toDouble() * minimumPercent ~/ 100;
    int maximumOnes = length.toDouble() * maximumPercent ~/ 100;
    int newOnes     = generator.nextInt(maximumOnes - minimumOnes) + (minimumOnes + 1);
    Solution s = Solution.zeroesFromProblem(p);

    for(int i = 0; i < newOnes ; i += 1){
      s[i] = true;
    }

    s.objects.shuffle();
    return s;
  }

  /// Constructs a random solution depending on the problem.
  /// It fills the solution with near 50% true values.
  factory Solution.randomLegacy(Problem p){
    math.Random generator = math.Random();
    Solution s = Solution.zeroesFromProblem(p);
    for(int i = 0; i < s.objects.length ; i += 1){
      s[i] = generator.nextBool();
    }
    return s;
  }

  /// Copy/clone a solution and avoids cache recalculation.
  factory Solution.copy(Solution other){
    List<bool> raw = other.objects.toList();
    Solution s = Solution(raw, other.p, updateCache: false);
    s.oneCount = other.oneCount;
    s._weight = other._weight;
    s._profit = other._profit;
    return s;
  }

  /// Gets a random index where objects[index] == true.
  int? randomIndexChoice(){
    if( oneCount < 0 ){
      return null;
    }
    
    math.Random generator = math.Random();
    int index;

    // Repeat until choose a set element
    do {
      index = generator.nextInt(objects.length);
    } while (!objects[index]);

    return index;
  }

  /// Gets a random index where objects[index] == false.
  int? randomZeroIndexChoice(){
    if( oneCount == objects.length ){
      return null;
    }
    
    math.Random generator = math.Random();
    int index;

    // Repeat until choose a set element
    do {
      index = generator.nextInt(objects.length);
    } while (objects[index]);

    return index;
  }

  /// recalculates the weight and profit of the current solution.
  void refreshCache(){
      _weight = _calculateWeight();
      _profit = _calculateProfit();
  }

   double calculateWeight() => _weight;

   double _calculateWeight(){
    double weight = 0.0;
    for(int i = 0; i < objects.length; i += 1){
      if(objects[i]){
        weight += p.weights[i];
      }
    }

    return weight;
  }

  double calculateProfit() => _profit;

  // double calculateProfit(Problem p){
  double _calculateProfit(){
    double profit = 0.0;
    for(int i = 0; i < objects.length; i += 1){
      if(objects[i]){
        profit += p.values[i];
      }
    }

    return profit;
  }

  /// returns the minimum price.
  double minimumValue(){
    double minValue = double.infinity;

    for(int i = 0; i < objects.length; i += 1){
      if(objects[i] && minValue > p.values[i] ){
        minValue = p.values[i];
      }
    }

    return minValue;
  }

  /// returns the maximum price.
  double maximumValue(){
    double maxValue = double.negativeInfinity;

    for(int i = 0; i < objects.length; i += 1){
      if(objects[i] && maxValue < p.values[i] ){
        maxValue = p.values[i];
      }
    }

    return maxValue;
  }

  bool hasElements(){
    return oneCount > 0;
  }

  /// Return permutations where two elements are swaped.
  Set<Solution> neighborhood(){
    final int limit = objects.length * ATTEMPTS_BY_ALTERNATIVE;
    Set<Solution> others = <Solution>{};
    Solution trip = Solution.copy(this);
    int? source, target;

    if( !hasElements() ){
      return others;
    }

    // "Graph search"
    for(int i = 0; i < limit ; i += 1){
      source = trip.randomIndexChoice();
      target = trip.randomZeroIndexChoice();

      // Totally full or totally empty, so no shift is required.
      if( source == null || target == null ){
        break;
      }

      // BEGIN. Flip values:
      trip[source] = false;
      trip[target] = true;

      if( trip.calculateWeight() <= p.capacity ){
        others.add(Solution.copy(trip));
      }

      // END. Flip values:
      trip[source] = true;
      trip[target] = false;
    }

    return others;
  }

  /// Selects those elements where we can add more elements.
  Set<Solution> neighborhoodLegacy(){
    Set<Solution> others = <Solution>{};
    Solution trip = Solution.copy(this);

    // "Graph search"
    for(int i = 0; i < trip.objects.length ; i += 1){
      // Ignore when the element has been marked as explored already.
      if(trip[i]){
        continue;
      }

      // Try this as a new solution
      trip[i] = true;

      if( trip.calculateWeight() <= p.capacity ){
        others.add(Solution.copy(trip));
      }

      trip[i] = false;
    }

    return others;
  }

  List<double> readableWeights() {
      List<double> weights  = [];
      for(int i = 0; i < objects.length; i += 1){
        if(objects[i]){
          weights.add(p.weights[i]);
        } else {
          weights.add(0);
        }
      }
      return weights;
  }

  List<double> readableProfits() {
      List<double> values  = [];
      for(int i = 0; i < objects.length; i += 1){
        if(objects[i]){
          values.add(p.values[i]);
        } else {
          values.add(0);
        }
      }
      return values;
  }

  List<int> enabledIndexes() {
      List<int> indexes  = [];
      for(int i = 0; i < objects.length; i += 1){
        if(objects[i]){
          indexes.add(i);
        }
      }
      return indexes;
  }


  // ----------------------
  // Dart specific features
  // ----------------------

  bool operator [](int index){
    return objects[index];
  }

  /// Sets a value in the internal data representation and updates cache
  void operator []=(int index, bool value){
    if( objects[index] && !value ){
      oneCount -= 1;
      _weight  -= p.weights[index];
      _profit  -= p.values[index];
    }

    if( !objects[index] && value ){
      oneCount += 1;
      _weight  += p.weights[index];
      _profit  += p.values[index];
    }

    objects[index] = value;
  }

  /// Overrides the standard equals operator so this structure
  /// can be compared inside Sets.
  @override
  bool operator ==(Object other){
    if (runtimeType != other.runtimeType){
      return false;
    }

    Solution another = other as Solution;

    if(objects.length != another.objects.length){
      return false;
    }
    
    for(int i = 0; i < objects.length; i += 1){
      if(objects[i] != another.objects[i]){
        return false;
      }
    }

    return true;
  }
  
  // We override this function so Sets will use == operator
  @override
  int get hashCode => 0;

  @override
  String toString() {
      return "Solution(objects = $objects)";
  }
}
