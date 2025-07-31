!(bind! random (py-atom random))
!(bind! operators (AND OR NOT XOR))
!(bind! max_depth 3)
!(bind! pop_size 20)
!(bind! max_gen 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Type Checkers ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(= (is_exp $var) (== (get-metatype $var) Expression))
(= (is_sym $var) (== (get-metatype $var) Symbol))
(= (is_op $var) (not (== () (intersection-atom ($var) (AND OR NOT XOR)))))
(= (is_node $var) (and (is_sym $var) (not (is_op $var))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Helper Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Selects a random atom from expression
;;; Parameters: a list or expression
;;; Returns randomly selected atom
;;; E.g, (random_select (A B C)) -> B 
(= (random_select $list) (index-atom $list ((py-dot random randint) 0 (- (size-atom $list) 1 ))))

;;; Selects a random atom from a list of atoms
;;; Parameters: a minimum and maximum value
;;; Returns a random number between the minimum and maximum value
;;; E.g, (random_num 1 10) -> 5
(= (random_num $min $max) ((py-dot random randint) $min $max))

;;; Calculates the number of Nodes and Operators on a boolean expression
;;; Parameters: a boolean expression
;;; Returns: the number of operators + symbols (nodes)
;;; E.g, (exp_size ((A AND B) OR (C OR A))) -> 7
(= (exp_size $expr) (exp_size $expr 0))
(= (exp_size $expr $count)(
   if (== $expr ()) 0
      ( let* (
            (($h $t) (decons-atom $expr))
            ($hsize ( if (is_exp $h) (exp_size $h) 1))
            ($rest (exp_size $t))
         ) ( + $hsize $rest ))))

;;;  Finds all the nodes in the boolean expression
;;; Parameters: a boolean expression
;;; Returns: a unique set of variables used in the expression
;;; E.g, (nodes (((A AND B) OR (C OR A))) ) -> (A B C)
(= (nodes $expr) (let $nodes (nodes $expr ()) (unique-atom $nodes)))
(= (nodes $expr $acc) (
   if (== $expr ()) ()
      ( let* (
            (($h $t) (decons-atom $expr))
            ($node ( if (is_exp $h) (nodes $h) (if (is_node $h)  ($h) ())))
            ($rest (nodes $t))
         ) (union-atom $node $rest))))

;;; Gets the number of nodes available in a boolean expression
;;; Parameters: a boolean expression
;;; Returns: the number of variables
;;; E.g, (nodes_size ((A AND B) OR (C OR A)) ) -> 3
(= (nodes_size $expr) (let $nodes (nodes $expr) (size-atom $nodes)))


;;; Gets the index of a key in an expression
;;; Parameters: expression, key
;;; Returns: the index of the key in the expression, or Nil if not found
;;; E.g, (get_index (A B C D E) C ) -> 2
(= (get_index $expr $key) (get_index $expr $key 0))
(= (get_index $expr $key $index)(
   if (== $expr ()) Nil (
      let ($h $t)
          (decons-atom $expr)
          (if (== $h $key) $index (get_index $t $key (+ $index 1))))))


;;; Gets the truth value of a variable in a list of values
;;; Parameters: a list of variables - Truth Value key pairs, the variable key to look for
;;; Returns: Boolean or Nil if not found
;;; E.g, (get_truth_value ((A True) (B False) (C True)) B) -> False
(= (get_truth_value $truth_values $key)(
   let* (
      ($result (intersection-atom (($key True) ($key False)) $truth_values))
      (($_ $tv) (
         if (== $result ())
            (Nil Nil)
            (car-atom $result)
      ))
   ) $tv
))

;; Generate non-deterministic truch value
(= (truth_value) True)
(= (truth_value) False)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Boolean Expression Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Generate a non-determinstic list of all possible truth value combinations of a fixed length
;;; Parameters: size of the truth table combinations
;;; Returns: a list of boolean values
;; E.g, (gen_tt_comb 2) -> [(True True), (True False), (False True), (False False)]
(= (gen_tt_comb $n) (
   if (> $n 0) (
      let ($tv $rest)
          ((truth_value)(gen_tt_comb (- $n 1)))
          (cons-atom $tv $rest)
   ) ()
))

;;; Generate a boolean expression tree with random operators, random combinations and depth withing a given limit (max_depth)
;;; Parameters: a list of variables
;;; Returns: boolean expression
;;; E.g, (gen_expression (A B C) 3) -> (AND (XOR A C) (OR C C))
(= (gen_expression $vars)(_gen_expression $vars (random_num 1 max_depth)))
(= (_gen_expression $vars $depth)(
   if (== $depth 0)
      (random_select $vars)
      (let* (
         ($op (random_select operators))
         ($left (_gen_expression $vars (random_num 0 (- $depth 1))))
         ($right (_gen_expression $vars (random_num 0 (- $depth 1))))
      ) (
         if (== $op NOT)
            ($op $right)
            ($op $left  $right)
      ))
))


;;; Create a nodelist - to - truth table combination list
;;; Parameters: a list of nodes, a list of truth values
;;; Returns: a list of node - truth value pairs
;;; E.g, (join_expr_with_tt 
;;;           (A B C D E)
;;;           (True False False True True)
;;;       ) -> ((A True) (B False) (C False) (D True) (E True))
(= (join_expr_with_tt $node_list $tt_comb)(join_expr_with_tt $node_list $tt_comb ()))
(= (join_expr_with_tt $node_list $tt_comb $tt_res_acc)(
   if (== $node_list ())
      $tt_res_acc
      (let* (
         (($f_node $r_node) (decons-atom $node_list))
         (($f_tv $r_tv) (decons-atom $tt_comb))
         ($updated_tt_res (union-atom  $tt_res_acc (($f_node $f_tv))))
      )( join_expr_with_tt $r_node $r_tv $updated_tt_res ))
))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Genetic Algorithm Functions ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Evaluate a boolean expression with a given set of truth values
;;; Parameters: a boolean expression, a list of node - truth value pairs
;;; Returns: Boolean
;;; E.g, (evaluate (AND A B) ((A True) (B False))) -> False
(= (evaluate $exp $truth_value)(
   let* (
      (($op $nodes) (decons-atom $exp))
      (($l $r) ( if (== $op NOT) ((car-atom $nodes) Nil) $nodes ))
      ($lv (
         if (is_exp $l)
            (evaluate $l $truth_value)
            (get_truth_value $truth_value $l)
      ))
      ($rv (
         if (is_exp $r)
            (evaluate $r $truth_value)
            (get_truth_value $truth_value $r)
      ))
   ) (
      case $op (
         (AND (and $lv $rv))
         (OR (or $lv $rv))
         (NOT (not $lv))
         (XOR (xor $lv $rv))
      )
   )
))

;;; Generate expression population of a given size
;;; Parameters: a list of variables, size of the population
;;; Returns: a list of boolean expressions
;;; E.g, (gen_population (A B C) 3) -> [(A OR B), (C AND A), (NOT B)]
(= (gen_population $vars) (gen_population $vars pop_size))
(= (gen_population $vars $size)(
   if (> $size 0) (
      let ($exp $rest)
          ((gen_expression $vars)(gen_population $vars (- $size 1)))
          (cons-atom $exp $rest)
   ) ()
))

;;; Evaluates a target expression against a single truth value pair
;;; Parameters: a target expression, a truth value - result pair
;;; Returns: True if the evaluation matches the result, False otherwise
;;; E.g, (test_eval (AND A B) ((A True) (B True))) -> True
(= (test_eval $target_expr $tv_res_pair)(
   let* (
      (($tv $res) (decons-atom $tv_res_pair))
      ($result (evaluate $target_expr $tv))  
   ) (== $res ($result))
))

;;; Fitness function for a boolean expression, the number of truth value pairs that match the target expression
;;; and the size of the expression calculated as a penalty (rewarding smaller expressions)
;;; Parameters: a target expression, a list of truth value - result pairs
;;; Returns: a number
;;; E.g, 
;;; (fitness
;;;    (OR A B)
;;;    (
;;;       (((A True) (B True) ) True)
;;;       (((A True) (B False) ) False)
;;;       (((A False) (B True) ) False)
;;;       (((A False) (B False) ) False)
;;;    )
;;; ) -> 41.0 (2/4 simmilraity - 3 * size of expression (3))
(= (fitness $target_expr $tv_res_pair_list)(
   let* (
      ($simmilarity (/ (_fitness $target_expr $tv_res_pair_list) (size-atom $tv_res_pair_list)))
      ($size (exp_size $target_expr))
   ) (
      - (* $simmilarity 100)
        (* $size 3)
   )
))
(= (_fitness $target_expr $tv_res_pair_list )(
   foldl-atom $tv_res_pair_list 0.0 $acc $pair
         ( + $acc (if (test_eval $target_expr $pair) 1.0 0)))
)


;;; Crossover function for two boolean expressions. creates a new expression by randomly selecting
;;; operators and nodes from the two expressions.
;;; Parameters: two boolean expressions
;;; Returns: a new boolean expression
;;; E.g, 
;;; (crossover 
;;;    (AND (OR A B) (XOR C D))
;;;    (XOR (NOT A) (AND B C))
;;; ) -> (AND (OR A B) (AND B C))
(= (crossover $exp1 $exp2)(
  let* (
      (($op1 $nodes1)(decons-atom $exp1))
      (($l1 $r1)( if (== $op1 NOT) ((car-atom $nodes1) Nil) $nodes1 ))
      (($op2 $nodes2)(decons-atom $exp2))
      (($l2 $r2)( if (== $op2 NOT) ((car-atom $nodes2) Nil) $nodes2 ))
      ($new_op (random_select ($op1 $op2)))
      ($new_left (random_select ($l1 $l2)))
      ($new_right (random_select ($r1 $r2)))
  ) (
      if (== $new_op NOT)
         ($new_op $new_right)
         ($new_op $new_left $new_right)
  )
))


;;; Mutate a boolean expression by randomly selecting an operator or node and replacing it with a new expression
;;; Parameters: a boolean expression
;;; Returns: a new boolean expression with a mutation applied
;;; E.g, (mutate (OR (AND A B) (XOR A B))) -> (OR (AND A B) A)
(= (mutate $exp)(
   let* (
      ($node_list (nodes $exp))
      (($op $nodes)(decons-atom $exp))
      (($l $r) ( if (== $op NOT) ((car-atom $nodes) Nil) $nodes ))
      ($new_exp (gen_expression $node_list))
      (($op2 $nodes2)(decons-atom $new_exp))
      (($l2 $) ( if (== $op2 NOT) ((car-atom $nodes2) Nil) $nodes2 ))
      ($new_op (random_select ($op $op2)))
   ) (
      if (== $new_op NOT)
         ($new_op $l2)
         ($new_op $l $l2)
   )
))


;;; Selects the best expressions from a population based on their fitness scores
;;; Parameters: a default exising best if there's, a population of boolean expressions, truth value - result pair list, number of best expressions to select
;;; Returns: List of Score - Expression pairs of the best expressions
;;; E.g,
;;;  !(select_best
;;;     ()
;;;     (
;;;        (OR A B)
;;;        (AND A B)
;;;        (XOR A B)
;;;        (NOT A)
;;;     )
;;;     (  
;;;        (((A True) (B True)) True)
;;;        (((A True) (B False)) False)
;;;        (((A False) (B True)) False)
;;;        (((A False) (B False)) False)
;;;     )
;;;     2
;;;  ) -> ( (100.0 (AND A B)) (50.0 (OR A B)) )
(= (select_best $exising_best $popn  $tv $n) (_select_best $popn $tv $n $exising_best))
(= (_select_best $popn $tv $n $top_popn)(
   if (== $popn ())
      $top_popn
      ( let* (
         (($expr $rest) (decons-atom $popn))
         ($score (fitness $expr $tv))
         ($updated_top (
            if (< (size-atom $top_popn) $n)
               (cons-atom ($score $expr) $top_popn)
               (let  $min 
                     (min-atom (map-atom $top_popn $x (car-atom $x)))
                     (if (> $score $min)
                         (foldl-atom $top_popn () $acc $p 
                                 (if (== $min (car-atom $p))
                                     (cons-atom ($score $expr) $acc)
                                     (cons-atom $p $acc)))
                         $top_popn
                     )
               )
         ))
      ) (_select_best $rest $tv $n $updated_top)
)))

;;; Create offspring from a population by selecting two parents, performing crossover and mutation
;;; Parameters: a population of boolean expressions, maximum population size
;;; Returns: a new population of boolean expressions
;;; E.g,
;;;   ( create_offspring 
;;;    (
;;;       (AND (OR A B) (XOR C D))
;;;       (XOR (NOT A) (AND B C))
;;;    ) 5 
;;;   ) -> ((XOR (NOT A) (XOR C B)) (XOR (NOT A) C) (XOR (NOT A) C) (AND (OR A B) (XOR C D)) (XOR (NOT A) (AND B C)))

(= (create_offspring $population $max_pop_size)(
      let* (
         ($parent1 (random_select $population))
         ($parent2 (random_select $population))
         ($crossed (crossover $parent1 $parent2))
         ($mutated (mutate  $parent1))
         ($new_pop (random_select ($crossed $mutated)))
         ($updated_pop_list (cons-atom $new_pop $population))
      ) (
         if (>= (size-atom $updated_pop_list) $max_pop_size)
            $updated_pop_list
            (create_offspring $updated_pop_list $max_pop_size)
   )
))


;;; Create a truth table for a given expression 
;;; Parameters: a boolean expression 
;;; Returns: a list of node -truth value pair with the result of the expression evaluation
;;; E.g,
;;;  (create_truth_table (OR A B) )
;;;   --->   ((((A True) (B True)) False) 
;;;          (((A True) (B False)) True) 
;;;          (((A False) (B True)) True) 
;;;          (((A False) (B False)) False))

(= (create_truth_table $expr) (collapse (_create_truth_table $expr)))
(= (_create_truth_table $expr)(
   let* (
      ($node_list (nodes $expr))
      ($tt_comb (gen_tt_comb (size-atom $node_list)))
   ) (_create_truth_table $expr $node_list $tt_comb)
))
(= (_create_truth_table $expr $node_list $tt_comb)(
   if (== $expr ())
      $tt_res_acc
      (let* (
         ($tt_node_pair (join_expr_with_tt $node_list $tt_comb))
         ($res (evaluate $expr $tt_node_pair))
      ) ($tt_node_pair $res) )
))

;;; Main Genetic Algorithm Runner
;;; Parameters: a target expression
;;; Returns: the best expression found after evolution
;;; E.g, (evolve (OR (AND A B) (AND A B))) -> (AND A B)
(= (evolve $target_expr)(
   let* (
      ($node_list (nodes $target_expr))
      ($truth_table (create_truth_table $target_expr))
      ($first_gen (gen_population $node_list pop_size))
      ($best_expr (select_best () $first_gen $truth_table 3))
   ) ( evolve 1 $truth_table $best_expr )
))
(= (get_exp $exps_w_score)(let ($sc $exp) (superpose $exps_w_score) $exp))
(= (evolve $gen $tt $best_scored)(
   if (>= $gen max_gen)
      $best_scored
      (let* (
         ($best_exprs (collapse (get_exp $best_scored)))
         ($next_gen (create_offspring $best_exprs pop_size))
         ($new_best (select_best $best_scored $next_gen $tt (size-atom $best_scored)))
      ) ( evolve (+ $gen 1) $tt $new_best )
)))

; !(evolve (OR (AND A B) (AND A B)))
