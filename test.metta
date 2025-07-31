! (import! &self main)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;  Tests ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Test for truth table generation
! (assertEqual
      (gen_tt_comb 2) 
      (superpose ((True True) (True False) (False True) (False False)))
   )

;; Test for boolean expression evaluation
! (assertEqual
      (evaluate (AND (OR A B) (XOR A B)) ((A True) (B False))) 
      True
   )

;; Test for population generation
! (assertEqual
      (let $gens (gen_population (A B C) 5) (size-atom $gens))
      5
   )

;; Test for expression fitness calculation
! (assertEqual
   (fitness
      (OR A B)
      (
         (((A True) (B True)) True)
         (((A True) (B False)) False)
         (((A False) (B True)) False)
         (((A False) (B False)) False)
      )  
   )
   (- 50 9)
)

; Test for best score selection
! (assertEqual
    (select_best 
      ()
      (
         (OR A B)
         (AND A B)
         (XOR A B)
         (NOT A)
      )
      (  
         (((A True) (B True)) True)
         (((A True) (B False)) False)
         (((A False) (B True)) False)
         (((A False) (B False)) False)
      )
      2
   )
   ((91.0 (AND A B)) (41.0 (OR A B)))
)
