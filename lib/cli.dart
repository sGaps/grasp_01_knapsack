import 'dart:io';

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

class CLIConfig {
  Stream<List<int>>? source;
  FormatConfig? format;
  String errorMsg;

  bool get error => errorMsg.isNotEmpty;

  CLIConfig(this.source, this.format, {this.errorMsg = '' });

  factory CLIConfig.errorMessage(String errorMsg) {
    return CLIConfig(null, null, errorMsg: errorMsg);
  }

  factory CLIConfig.noAction() {
    return CLIConfig(null, null);
  }
}

Future<CLIConfig> processArguments(List<String> arguments) async {

  if(arguments.isEmpty){
    showHelp();
    return CLIConfig.noAction();
  }

  Set<String> args = arguments.toSet();
  if( args.contains('-d') || args.contains('--debug-args') ){
    print('[DEBUG] CLI arguments: $arguments');
  }

  if( args.contains('-v') || args.contains('--version')){
    showVersion();
    return CLIConfig.noAction();
  }

  if( args.contains('-h') || args.contains('--help')){
    showHelp();
    return CLIConfig.noAction();
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
        return CLIConfig.errorMessage('File path not specified');
      }

      File file = File(arguments[specifierIndex + 1]);
      if( !(await file.exists()) ){
        return CLIConfig.errorMessage('Invalid file path "${arguments[specifierIndex + 1]}"');
      }

      source = file.openRead();
      print('[INFO] Reading from "${arguments[specifierIndex + 1]}"');
      print('');
    }
  }

  if( source == null ){
    return CLIConfig.errorMessage('No input detected');
  }

  FormatConfig format = FormatConfig(
    arguments.contains('--complete'),
    arguments.contains('--raw-solution'),
    !arguments.contains('--no-problem'));

  return CLIConfig(source, format);
}
