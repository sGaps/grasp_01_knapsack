//import 'dart:cli';
import 'dart:io';
import 'dart:convert' as convert;
import 'dart:math' as math;

// local:
import 'package:grasp_01_knapsack/grasp_01_knapsack.dart' as grasp_01_knapsack;

class Problem {
  double capacity;
  List<double> weights;
  List<double> values;

  Problem(this.capacity, this.weights, this.values);

  @override
  String toString() {
      return "Problem(capacity = $capacity, weights = $weights, values = $values)";
  }
}

class Instance {
  int id;
  //int limit;
  Problem problem;

  Instance(this.id, this.problem );
  //Instance(this.id, this.limit, this.problem );
}

// Solution is only a list of Booleans

Future<Problem> problemFromStream(Stream<List<int>> source) async {
  final RegExp intoWords = RegExp(r"\s");
  Stream<List<String>> stream = source.transform(convert.utf8.decoder)
    .transform(convert.LineSplitter())
    .map( (line) => line.split(intoWords) );

  List<List<String>> words = await stream.toList();

  int n = int.parse( words.first[0] );
  double capacity = double.parse( words.first[1] );
  
  List<double> weights = List.filled(n, 0);
  List<double> values  = List.filled(n, 0);

  for(int i = 1; i < words.length; i += 1){
    values[i-1]  = double.parse(words[i][0]);
    weights[i-1] = double.parse(words[i][1]);
  }

  return Future( () => Problem(capacity, weights, values));
}

class Solution {
  List<bool> objects;
  int oneCount = 0;

  Solution(this.objects);

  factory Solution.withCapacity(int capacity){
    List<bool> raw = List.filled(capacity, false);
    return Solution(raw);
  }

  factory Solution.random(int length){
    math.Random generator = math.Random();
    Solution s = Solution.withCapacity(length);
    for(int i = 0; i < s.objects.length ; i += 1){
      s[i] = generator.nextBool();
    }
    return s;
  }

  factory Solution.copy(Solution other){
    List<bool> raw = other.objects.toList();
    Solution s = Solution(raw);
    s.oneCount = other.oneCount;
    return s;
  }

  int? randomIndexChoice(){
    if( oneCount < 0 ){
      return null;
    }
    
    math.Random generator = math.Random();
    int index;

    do {
      index = generator.nextInt(objects.length);
    } while (!objects[index]);

    return index;
  }


  double calculateWeight(Problem p){
    double weight = 0.0;
    for(int i = 0; i < objects.length; i += 1){
      if(objects[i]){
        weight += p.weights[i];
      }
    }

    return weight;
  }

  double calculateProfit(Problem p){
    double profit = 0.0;
    for(int i = 0; i < objects.length; i += 1){
      if(objects[i]){
        profit += p.values[i];
      }
    }

    return profit;
  }

  double minimumValue(Problem p){
    double minValue = double.infinity;

    for(int i = 0; i < objects.length; i += 1){
      if(objects[i] && minValue > p.values[i] ){
        minValue = p.values[i];
      }
    }

    return minValue;
  }

  double maximumValue(Problem p){
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
    //return objects.isNotEmpty && objects.any( (e) => e );
  }

  Set<Solution> neighborhood(Problem p){
    Set<Solution> others = <Solution>{};
    Solution trip = Solution.copy(this);

    // "Graph search"
    for(int i = 0; i < trip.objects.length ; i += 1){
      trip[i] = true;

      if( trip.calculateWeight(p) <= p.capacity ){
        others.add(Solution.copy(trip));
      }

      trip[i] = false;
    }

    return others;
  }


  // Dart specific.

  bool operator [](int index){
    return objects[index];
  }

  void operator []=(int index, bool value){
    if( objects[index] && !value ){
      oneCount -= 1;
    }

    if( !objects[index] && value ){
      oneCount += 1;
    }

    objects[index] = value;
  }

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
  
  // So it will use == operator
  @override
  int get hashCode => 0;

  @override
  String toString() {
      return "Solution(objects = $objects)";
  }

  List<double> readableWeights(Problem p) {
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

  List<double> readableProfits(Problem p) {
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
}

const double ALPHA = 0.8;

double greed(double cmin, double cmax){
  return cmin + ALPHA * (cmax - cmin);
}

const int BENCHMARK_LIMIT = 10;
const int GRASP_LIMIT     = 15;

Solution buildRCL(Solution candidates, Problem p){
  double cmin = candidates.minimumValue(p);
  double cmax = candidates.maximumValue(p);
  Solution rcl = Solution.withCapacity(p.weights.length);

  for(int i = 0; i < rcl.objects.length; i += 1 ){
    rcl[i] = candidates[i] && (p.values[i] >= greed(cmin, cmax));
  }

  return rcl;
}

// TODO: Do I actually need instance? I could pass a single problem...
Solution generateSolution(Instance instance){
  Problem p = instance.problem;
  Solution candidates = Solution.random(p.weights.length); // Initialize candidates.
  Solution solution = Solution.withCapacity(p.weights.length);
  Solution rcl;
  int? index = 0;

  // Initialize candidates
  // candidates = initializeCandidates(p);

  while(candidates.hasElements()){
    rcl = buildRCL(candidates, p);

    // TODO: Choice random number which is already set in candidates.
    index = rcl.randomIndexChoice();
    if( index == null ){
      break;
    }

    solution[index] = true;

    if( solution.calculateWeight(p) > p.capacity ){
      solution[index] = false;
    }

    candidates[index] = false;
  }

  return solution;
}

Solution localSearch(Instance instance, Solution startSolution){
  Solution localOptimum = startSolution;
  Problem p = instance.problem;
  Set<Solution> others;
  math.Random generator = math.Random();

  while(true) {
    others = localOptimum.neighborhood(p);

    // As we are maximizing, we are not interested on see what happens
    // with those elements that give us a lower profit.
    others.removeWhere((alternative) =>
        alternative.calculateProfit(p) <= localOptimum.calculateProfit(p));

    if(others.isEmpty){
      break;
    }

    // Select any better Optimum
    localOptimum = others.elementAt(generator.nextInt(others.length));
  }

  return localOptimum;
}

Solution grasp(Instance instance){
  Problem  p        = instance.problem;
  Solution solution = Solution.withCapacity(p.weights.length);
  Solution bestSolution = Solution.withCapacity(p.weights.length);
  Solution localSolution = Solution.withCapacity(p.weights.length);

  for(int i = 0; i < GRASP_LIMIT; i += 1){
    solution = generateSolution(instance);
    localSolution = localSearch(instance, solution);

    if( localSolution.calculateProfit(p) > bestSolution.calculateProfit(p) ){
      bestSolution = localSolution;
    }
  }

  return bestSolution;
}

void benchmark(Instance instance){
  Problem p = instance.problem;
  Solution s;

  // TODO: Finish
  print('Instance');
  print('Problem: ${instance.problem}');
  for(int i = 0; i < BENCHMARK_LIMIT; i += 1){
    final Stopwatch clock = Stopwatch();
    clock.start();
    s = grasp(instance);
    clock.stop();
    print('Solution: $s');
    print('Weight:   ${s.calculateWeight(p)}');
    print('ws.human: ${s.readableWeights(p)}');

    print('Profit:   ${s.calculateProfit(p)}');
    print('ps.human: ${s.readableProfits(p)}');
    print('Elapsed Time: ${clock.elapsed}');
    print('');

  }
}

void main(List<String> arguments) async {
  print('Hello world: ${grasp_01_knapsack.calculate()}!');
  print('Args: $arguments!');

  Stream<List<int>> source = stdin;
  if (arguments.length >= 2 && arguments[0] == '-f' && arguments[1].isNotEmpty ) {
    File file = File(arguments[1]);
    source = file.openRead();
  }

  Instance instance = Instance(1, await problemFromStream(source));
  benchmark(instance);

  // var x = {[[1,2,3], [1,2], [], [1,2,3]]};
  // print(x);

  // var y = {Solution([true,false,true]), Solution([true,false]), Solution([true]), Solution([true,false,true])};
  // print(y);

  //////////
  // Stream<List<int>> source = stdin;
  // if (arguments.length >= 2 && arguments[0] == '-f' && arguments[1].isNotEmpty ) {
  //   File file = File(arguments[1]);
  //   source = file.openRead();
  // }

  // Problem p = await problemFromStream(source);
  // print("$p");

  // Solution solution = List.filled(p.weights.length, false);
}

// Solution grasp(Instance instance){
//   Problem p = instance.problem;

//   Solution solution = List.filled(p.weights.length, false);
//   double   profit   = 0.0;

//   Solution bestSolution = List.filled(p.weights.length, false);
//   double   bestProfit   = 0.0;

//   return bestSolution;
// }