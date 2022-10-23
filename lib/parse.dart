import 'dart:convert' as convert;
import 'package:grasp_01_knapsack/problem.dart';

/// Parse a stream and returns a Problem object.
/// SEE ALSO: `showHelp` to see which format accepts this function.
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
