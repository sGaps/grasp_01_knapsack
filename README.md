# Implementación de GRASP

> Gabriel P.

Asignación realizada para la Electiva "Metaheurísticas en Optimización Combinatoria".

## Organización del Proyecto

En general, el proyecto presenta la siguiente organización tipo árbol

```
( implementación de grasp ) 
    bin/
     `--grasp_01_knapsack.dart

( utilidades )
    lib/
     |--cli.dart
     |--parse.dart
     |--problem.dart
     `--solution.dart

( archivos con instancias de prueba ) 
    samples/
     |--large_scale/
     |   |  ...
     |   `- ...
     |
     `--low-dimensional
         |  ...
         `- ...

( soluciones óptimas de archivos prueba ) 
    samples/
     |--large_scale-optimum/
     |   |  ...
     |   `- ...
     |
     `--low-dimensional-optimum
         |  ...
         `- ...
```

El resto de los archivos del proyecto corresponden a la información
que utiliza las utilidades de dart para reconocer la carpeta como
proyecto.

Las instancias de pruebas corresponden a las de la siguiente fuente
[(Instancias)](http://artemisa.unicauca.edu.co/~johnyortega/instances_01_KP/)

## Requisitos

- dart SDK 2.13.0+

## Instrucciones de compilacion

1. en la terminal, dirígase a la carpeta que contiene este proyecto,
aquella que tiene por nombre "grasp_01_knapsack".

2. Luego, estando en la raíz de dicha carpeta, use el comando:

```bash
dart pub upgrade
dart compile exe bin/grasp_01_knapsack.dart -o grasp
```

> NOTA: es importante ejecutar `dart pub upgrade` para referescar la caché
> del proyecto. Adicionalmente, es importante que la carpeta raíz tenga por
> nombre "grasp_01_knapsack".

## Instrucciones de ejecucion

1. Luego de [compilar el proyecto](#instrucciones-de-compilacion), ejecute la
siguiente instrucción para visualizar las instrucciones del programa:

```bash
./grasp
```

Alternativamente, puede utilizar los comandos `--help` y `-h` para realizar la misma
acción.

2. Ahora, para ejecutar una instancia de pruebas, intente el comando `--file` (o su
versión corta, `-f`) para leer un arhivo de entrada:

```bash
./grasp --file samples/low-dimensional/f1_l-d_kp_10_269
```

3. De igual modo, puede leer los datos de una instancia desde la entrada estándar:

```bash
./grasp --stdin < samples/low-dimensional/f1_l-d_kp_10_269
```

## Prueba por lotes

Para automatizar el procedimiento de pruebas, pruebe los siguientes comandos de bash.

#### Low-dimensional

```bash
mkdir -p output
for i in $(ls samples/low-dimensional/* | sort --reverse);
do ./grasp -f $i > output/run-low-dimensional.txt;
done;
```

#### Large Scale

> *ATENCIÓN*: No se recomienda probar este tipo de instancias por lotes debido a
> que cada prueba posee una larga duración.

```bash
mkdir -p output
for i in $(ls samples/large_scale/* | sort --reverse);
do ./grasp --no-problem -f $i > output/run-large-scale.txt;
done;
```


> *NOTA*: Debido al gran tamaño de la instancia original, se ha añadido el parámetro `--no-problem`
> para omitir la descripción del problema al iniciar la ejecución del programa.

## Generar documentación html del proyecto:

Ejecute la instrucción

```
dart doc
```