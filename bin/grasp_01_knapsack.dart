import 'dart:io';
import 'dart:convert' as convert;
import 'dart:math' as math;

// TODO: Split this file into libraries
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

class Solution {
  List<bool> objects;
  int oneCount = 0;

  Solution(this.objects);

  factory Solution.withCapacity(int capacity){
    // A raw solution is only a bunch of bool values.
    List<bool> raw = List.filled(capacity, false);
    return Solution(raw);
  }

  factory Solution.random(int length){
    const minimumPercent = 10.0;
    const maximumPercent = 90.0;

    math.Random generator = math.Random();
    int minimumOnes = (length.toDouble() * minimumPercent ~/ 100).toInt();
    int maximumOnes = (length.toDouble() * maximumPercent ~/ 100).toInt();
    int newOnes     = generator.nextInt(maximumOnes - minimumOnes) + (minimumOnes + 1);
    Solution s = Solution.withCapacity(length);

    for(int i = 0; i < newOnes ; i += 1){
      s[i] = true;
    }

    s.objects.shuffle();
    return s;
  }

  factory Solution.randomLegacy(int length){
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

    // Repeat until choose a set element
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
  }

  Set<Solution> neighborhood(Problem p){
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

      if( trip.calculateWeight(p) <= p.capacity ){
        others.add(Solution.copy(trip));
      }

      trip[i] = false;
    }

    return others;
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

  List<int> enabledIndexes(Problem p) {
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
  
  // We override this function so Sets will use == operator
  @override
  int get hashCode => 0;

  @override
  String toString() {
      return "Solution(objects = $objects)";
  }
}

// Sometimes 0.7 is better than 0.8
const double ALPHA        = 0.85;
const int BENCHMARK_LIMIT = 10;
const int GRASP_LIMIT     = 10000;

double greed(double cmin, double cmax){
  return cmin + ALPHA * (cmax - cmin);
}

Solution buildRCL(Solution candidates, Problem p){
  double cmin = candidates.minimumValue(p);
  double cmax = candidates.maximumValue(p);
  double greedyFactor = greed(cmin, cmax);
  Solution rcl = Solution.withCapacity(p.weights.length);

  for(int i = 0; i < rcl.objects.length; i += 1 ){
    rcl[i] = candidates[i] && (p.values[i] >= greedyFactor);
  }

  return rcl;
}

Solution generateSolution(Problem p){
  // Initialize candidates just as specified in the regular GRASP.
  Solution candidates = Solution.random(p.weights.length);
  Solution solution = Solution.withCapacity(p.weights.length);
  Solution rcl;
  int? index = 0;

  while(candidates.hasElements()){
    rcl = buildRCL(candidates, p);

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

Solution localSearch(Problem p, Solution startSolution){
  Solution localOptimum = startSolution;
  Set<Solution> others;
  double bestProfit;

  while(true) {
    others = localOptimum.neighborhood(p);

    // As we are maximizing, we are not interested on see what happens
    // with those elements that give us a lower profit.
    others.removeWhere((alternative) =>
        alternative.calculateProfit(p) <= localOptimum.calculateProfit(p));

    if(others.isEmpty){
      break;
    }

    // Select the current best solution among neighbors
    bestProfit   = others.map( (s) => s.calculateProfit(p) ).reduce(math.max);
    localOptimum = others.firstWhere((s) => s.calculateProfit(p) == bestProfit);
  }

  return localOptimum;
}

Solution grasp(Problem p){
  Solution solution = Solution.withCapacity(p.weights.length);
  Solution bestSolution = Solution.withCapacity(p.weights.length);
  Solution localSolution = Solution.withCapacity(p.weights.length);

  for(int i = 0; i < GRASP_LIMIT; i += 1){
    solution = generateSolution(p);
    localSolution = localSearch(p, solution);

    if( localSolution.calculateProfit(p) > bestSolution.calculateProfit(p) ){
      bestSolution = localSolution;
    }
  }

  return bestSolution;
}


// --------------
// I/O Operations
// --------------

/// Parse an stream and returns a Problem object.
/// SEE ALSO: showHelp to see which format accepts this function.
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

  for(int i = 1; i <= values.length ; i += 1){
    values[i-1]  = double.parse(words[i][0]);
    weights[i-1] = double.parse(words[i][1]);
  }

  return Future( () => Problem(capacity, weights, values));
}

/// Tries to solve the problem several times by using the grasp method.
void benchmark(Problem p, FormatConfig format){
  Solution s;

  if( format.showProblem ){
    print('[SYS] Benchmark of Problem: $p');
    print('');
  }

  print('[SYS] Tuning parameters');
  print('  ALPHA: $ALPHA');
  print('  Max. GRASP iterations: $GRASP_LIMIT');
  print('  Max. Benchmark iterations: $BENCHMARK_LIMIT');
  print('');

  for(int i = 0; i < BENCHMARK_LIMIT; i += 1){
    final Stopwatch clock = Stopwatch();
    clock.start();
    s = grasp(p);
    clock.stop();


    print('[BENCH] Resume of run $i');
    print('  Weight: ${s.calculateWeight(p)}');
    print('  Profit: ${s.calculateProfit(p)}');
    print('  Elapsed Time: ${clock.elapsed}');
    print('  Selected Indexes: ${s.enabledIndexes(p)}');

    if( format.rawSolution ){
      print('  Solution found (raw format): $s');
    }

    if( format.complete ){
      print('  Weights(double): ${s.readableWeights(p)}');
      print('  Values(double):  ${s.readableProfits(p)}');
    }

    print('');

  }
}

void showVersion(){
  print('GRASP for 0/1 Knapsack Problem. version 0.1');
}

void showHelp(){
  showVersion();
  print(
"""
  Usage:
    grasp [output-formats] [arguments] [values]

    Arguments
      (-f|--file) <file>  opens a file and read.
      (-I|--stdin)        read input from stdin.
      (-h|--help)         shows program version and this help.
      (-d|--debug-args)   prints the arguments read by the CLI.
      (-v|--version)      shows program version.

    Output format arguments
      --complete          shows complete results for weights and values.
      --raw-solution      prints the raw solution along the short version.
      --no-problem        doesn't print the probleme at the begining.

    Input format:
    ```txt
      N capacity
      value1 weight1
      value2 weight2
      ...
      valueN weightN
    ```

      where N is the number of elements registered into
      the problem, capacity is the knapsack weight capacity,
      value<i> and weight<i> are the relevant values of the
      element at the index <i>.
""");
}

class FormatConfig{
  bool complete    = false;
  bool rawSolution = false;
  bool showProblem = true;

  FormatConfig(this.complete, this.rawSolution, this.showProblem);
}

// Process CLI arguments and run benchmarks
void main(List<String> arguments) async {
  if(arguments.isEmpty){
    showHelp();
    return;
  }

  Set<String> args = arguments.toSet();
  if( args.contains('-d') || args.contains('--debug-args') ){
    print('[DEBUG] CLI arguments: $arguments');
  }

  if( args.contains('-v') || args.contains('--version')){
    showVersion();
    return;
  }

  if( args.contains('-h') || args.contains('--help')){
    showHelp();
    return;
  }

  // Selects the correct stream depending on CLI parameters/flags.
  Stream<List<int>>? source;
  if( args.contains('-I') || args.contains('--stdin') ){
    source = stdin;
    print('[INFO] Reading from Stdin');
    print('');
  } else {
    int specifierIndex = arguments.indexOf('-f');
    if( specifierIndex == -1 ){
      specifierIndex = arguments.indexOf('--file');
    }

    if( specifierIndex != -1 ){
      if( !(specifierIndex + 1 < arguments.length) ){
        return Future.error('File path not specified');
      }

      File file = File(arguments[specifierIndex + 1]);
      if( !(await file.exists()) ){
        return Future.error('Invalid file path "${arguments[specifierIndex + 1]}"');
      }

      source = file.openRead();
      print('[INFO] Reading from "${arguments[specifierIndex + 1]}"');
      print('');
    }
  }

  FormatConfig format = FormatConfig(
    arguments.contains('--complete'),
    arguments.contains('--raw-solution'),
    !arguments.contains('--no-problem'));

  // The true works begins here
  if( source != null ){
    benchmark(await problemFromStream(source), format);
  }
}
