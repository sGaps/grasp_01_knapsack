//import 'dart:cli';
import 'dart:io';
import 'dart:convert' as convert;

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
  int limit;
  Problem problem;

  Instance(this.id, this.limit, this.problem );
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
    weights[i-1]  = double.parse(words[i][0]);
    values[i-1] = double.parse(words[i][1]);
  }

  return Future( () => Problem(capacity, weights, values));
}

void main(List<String> arguments) async {
  print('Hello world: ${grasp_01_knapsack.calculate()}!');
  print('Args: ${arguments}!');

  Stream<List<int>> source = stdin;
  if (arguments.length >= 2 && arguments[0] == '-f' && arguments[1].isNotEmpty ) {
    File file = File(arguments[1]);
    source = file.openRead();
  }

  Problem p = await problemFromStream(source);
  print("$p");

}
