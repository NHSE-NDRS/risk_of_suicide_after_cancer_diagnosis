program define rsadd
	version 7
	args todo eta mu return
	if `todo' == -1 {
	         global SGLM_lt "RS (additive)"
	         global SGLM_lf "(u/y)"
		 global SGLM_mu "glim_mu 0 ."
                 exit
        }
        if `todo' == 0 {
                 gen double `eta' = `mu'/$SGLM_p
                 exit
        }
        if `todo' == 1 {
                 gen double `mu' = `eta'*$SGLM_p
                 exit
        }
        if `todo' == 2 {
                 gen double `return' = $SGLM_p
                 exit
        }
        if `todo' == 3 {
                 gen double `return' = 0
                 exit
        }
        di as error "Unknown call to glm link function"
        exit 198
end
