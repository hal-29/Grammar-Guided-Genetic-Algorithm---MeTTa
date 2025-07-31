# Grammar-Guided Genetic Programming

This project is a MeTTa implementation of a Grammar-Guided Genetic Programming (GGGP) algorithm as a functional programming style. It is designed to evolve boolean logic expressions to a simpler one. The entire logic, from generating populations to evaluating fitness and performing genetic operations, is written in MeTTa.

## Overview

The core of this project is a genetic algorithm that operates on a population of boolean expressions. It uses a set of genetic operators like crossover and mutation to evolve the expressions over generations. The goal is to find a minimal representation of an input boolean expression, effectively solving a boolean logic problem. The "Grammar-Guided" aspect ensures that all generated expressions are syntactically correct according to the rules of boolean algebra.

## How It Works: The Genetic Algorithm

The process follows the standard evolutionary algorithm flow:

1.  **Initialization**: An initial population of random boolean expressions is generated.
2.  **Fitness Evaluation**: Each expression in the population is evaluated against a target truth table to determine its "fitness". A higher fitness score indicates that the expression's output is closer to the desired output.
3.  **Selection**: The fittest expressions are selected to be "parents" for the next generation.
4.  **Reproduction**: The selected parents are used to create offspring through:
      * **Crossover**: Combining parts of two parent expressions to create a new one.
      * **Mutation**: Randomly changing a part of an expression.
5.  **New Generation**: The offspring form the next generation, and the process repeats from the fitness evaluation step. This cycle continues for a predefined number of generations (`max_gen`).

## Core Components and Functions

### Global Constant Definitions
Global variables are defined to control the core operations of the genetic algorith.
```bash
!(bind! operators (AND OR NOT XOR))
!(bind! max_depth 3)
!(bind! pop_size 20)
!(bind! max_gen 2)
```
- `operators` defines the set of allowed operators to use in the GP
- `max_depth` controls the maximum depth of a randomly generated expression / populations
- `pop_size` defines the number of population for offspring
- `max_gen` defines how many generations to evolve

`[NOTE]` a higher number on these configs means a more likely to find a better solution, but with computational overhead.


### Type Checking

A set of functions is used to check the types of atoms, which is crucial for the grammar-guided generation of expressions.

  * `is_exp`: Checks if a variable is an Expression.  * `is_sym`: Checks if a variable is a Symbol.  * `is_op`: Checks if a variable is a valid boolean operator (AND, OR, NOT, XOR).  * `is_node`: Checks if a variable is a symbolic node (a variable name like A, B, etc.).
### Helper Functions

Several utility functions assist in manipulating expressions and data.

  * `random_select`: Selects a random atom from an expression.
  * `random_num`: Generates a random number within a specified range.
  * `exp_size`: Calculates the number of nodes and operators in an expression.
  * `nodes`: Extracts all the unique variable nodes from an expression.
  * `get_truth_value`: Retrieves the boolean value of a variable from a truth value mapping.

### Boolean Expression Functions

These functions are responsible for creating and evaluating boolean expressions.

  * `gen_tt_comb`: Generates all possible truth table combinations for a given number of variables.
  * `gen_expression`: Generates a random boolean expression tree up to a maximum depth.
  * `evaluate`: Evaluates a boolean expression given a set of truth values for its variables.
  * `create_truth_table`: Creates a complete truth table for a given boolean expression, showing the output for all possible input combinations.

### Genetic Algorithm Functions

These are the core functions that implement the evolutionary process.

  * **`gen_population`**: Creates an initial population of random boolean expressions.
  * **`fitness`**: The fitness function. It calculates a score for an expression based on how closely its output matches the target truth table. It also penalizes larger expressions to favor simpler solutions.
  * **`select_best`**: Selects the top-performing expressions from a population based on their fitness scores.
  * **`crossover`**: Takes two parent expressions and creates a new offspring by randomly combining parts of both.
  * **`mutate`**: Randomly alters a part of an expression to introduce new genetic material and prevent premature convergence.
  * **`create_offspring`**: Generates a new population of offspring from the current population using crossover and mutation.
  * **`evolve`**: The main driver of the algorithm. It initializes the population, and then runs the evolutionary cycle of evaluation, selection, and reproduction for a specified number of generations.

## How to Use

The system is designed to be run within a MeTTa environment. The main entry point is the `evolve` function.

To start the genetic programming process, you provide a target boolean expression to the `evolve` function.

**Example:**

```metta
!(evolve (OR (AND A B) (AND A B)))
```

The system will then perform the following steps:

1.  It will analyze the target expression `(OR (AND A B) (AND A B))` to identify the variables (nodes) involved, which are `A` and `B`.
2.  It will generate the complete truth table for this target expression.
3.  An initial population of random boolean expressions using the variables `A` and `B` will be created.
4.  The evolutionary process will begin, running for the number of generations specified by `max_gen`.
5.  After the final generation, the `evolve` function will return the best expression found, which is the one with the highest fitness score. In this specific example, since `(OR (AND A B) (AND A B))` is logically equivalent to `(AND A B)`, the algorithm is expected to evolve towards the simpler `(AND A B)` expression.

## Testing

The project includes a `test.metta` file with a suite of tests to verify the correctness of the individual functions.

The tests cover:

  * Truth table generation (`gen_tt_comb`).  * Boolean expression evaluation (`evaluate`).  * Population generation (`gen_population`).  * Fitness calculation (`fitness`).  * Best expression selection (`select_best`).


  ---
 © Jul 2025 - build by Haileiyesus Mesafint as part of iCog-Labs AGI Internship program