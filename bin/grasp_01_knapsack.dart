import 'dart:math' as math;

import 'package:grasp_01_knapsack/cli.dart';
import 'package:grasp_01_knapsack/parse.dart';
import 'package:grasp_01_knapsack/problem.dart';
import 'package:grasp_01_knapsack/solution.dart';

// Tuning parameters.
const double ALPHA        = 0.98;
const int BENCHMARK_LIMIT = 10;
const int GRASP_LIMIT     = 50;

/// Says when we should or not add an element into the RCL.
/// (it's the maximum utility slope).
double greed(double cmin, double cmax){
  return cmax - ALPHA * (cmax - cmin);
}

/// Constructs the Restricted Candidates List.
Solution buildRCL(Solution candidates, Problem p){
  double cmin = candidates.minimumValue();
  double cmax = candidates.maximumValue();
  double greedyFactor = greed(cmin, cmax);
  Solution rcl = Solution.zeroesFromProblem(p);

  // Includes the element iff is over the greedyFactor's threshold.
  for(int i = 0; i < rcl.objects.length; i += 1 ){
    rcl[i] = candidates[i] && (p.values[i] >= greedyFactor);
  }

  return rcl;
}

/// Constructs the initial solution.
Solution generateSolution(Problem p){
  // Initialize candidates just as specified in the regular GRASP.
  Solution candidates = Solution.random(p);
  Solution solution = Solution.zeroesFromProblem(p);
  Solution rcl;
  int? index = 0;

  while(candidates.hasElements()){
    rcl = buildRCL(candidates, p);

    index = rcl.randomIndexChoice();
    if( index == null ){
      break;
    }

    // Save or discard a solution depending on its capacity.
    solution[index] = true;

    if( solution.calculateWeight() > p.capacity ){
      solution[index] = false;
    }

    // Marks the element as visited.
    candidates[index] = false;
  }

  return solution;
}

/// Performs a local search starting from `startSolution`.
Solution localSearch(Solution startSolution){
  Solution localOptimum = startSolution;
  Set<Solution> others;
  double bestProfit;

  while(true) {
    // Neighbor criteria:
    //  Solutions with bits permutations and those that includes an extra element.
    others = localOptimum.neighborhood().union( localOptimum.neighborhoodLegacy() );

    // As we are maximizing, we are not interested on seeing what happens
    // with those elements that give us a lower profit.
    others.removeWhere((alternative) =>
       alternative.calculateProfit() < localOptimum.calculateProfit());

    if(others.isEmpty){
      break;
    }

    // Select the current best solution among local optimum's neighbors.
    bestProfit   = others.map( (s) => s.calculateProfit() ).reduce(math.max);
    localOptimum = others.firstWhere((s) => s.calculateProfit() == bestProfit);
  }

  return localOptimum;
}

/// Standard implementation of grasp.
/// SEE ALSO: `localSearch`, `generateSolution`, `Problem`, `Solution`.
Solution grasp(Problem p){
  Solution bestSolution = Solution.zeroesFromProblem(p);
  Solution solution;
  Solution localSolution;

  for(int i = 0; i < GRASP_LIMIT; i += 1){
    solution = generateSolution(p);
    localSolution = localSearch(solution);

    if( localSolution.calculateProfit() > bestSolution.calculateProfit() ){
      bestSolution = localSolution;
    }
  }

  return bestSolution;
}

/// Tries to solve the problem several times by using the grasp method.
void benchmark(Problem p, FormatConfig format){
  Solution s;

  if( format.showProblem ){
    print('[SYS] Benchmark of Problem: $p');
    print('');
  }

  // Prelude.
  print('[SYS] Tuning parameters');
  print('  ALPHA: $ALPHA');
  print('  Max. GRASP iterations: $GRASP_LIMIT');
  print('  Max. Benchmark iterations: $BENCHMARK_LIMIT');
  print('');

  for(int i = 0; i < BENCHMARK_LIMIT; i += 1){
    // The actual run.
    final Stopwatch clock = Stopwatch();
    clock.start();
    s = grasp(p);
    clock.stop();

    // The values we are interested on are the boolean elements inside the solution
    // so it doesn't affect us if we refresh the weights and profits again outside the test.
    s.refreshCache();

    // Data report.
    print('[BENCH] Resume of run $i');
    print('  Weight: ${s.calculateWeight()}');
    print('  Profit: ${s.calculateProfit()}');
    print('  Elapsed Time: ${clock.elapsed}');
    print('  Selected Indexes: ${s.enabledIndexes()}');

    if( format.rawSolution ){
      print('  Solution found (raw format): $s');
    }

    if( format.complete ){
      print('  Weights(double): ${s.readableWeights()}');
      print('  Values(double):  ${s.readableProfits()}');
    }

    print('');

  }
}


// Process CLI arguments and run benchmarks
void main(List<String> arguments) async {

  CLIConfig config = await processArguments(arguments);

  Stream<List<int>>? source = config.source;
  FormatConfig? format = config.format;

  if( source == null || format == null ){
    return Future.error(config.errorMsg);
  }

  benchmark(await problemFromStream(source), format);
}
