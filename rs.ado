program define rs
	version 7
	args todo eta mu return
	if `todo' == -1 {
	         global SGLM_lt "Relative survival"
	         global SGLM_lf "log(u-d*)"
                 exit
        }
        if `todo' == 0 {
                 gen double `eta' = ln(`mu'-$SGLM_p)
                 exit
        }
        if `todo' == 1 {
                 gen double `mu' = exp(`eta')+$SGLM_p
                 exit
        }
        if `todo' == 2 {
                 gen double `return' = exp(`eta')
                 exit
        }
        if `todo' == 3 {
                 gen double `return' = exp(`eta')
                 exit
        }
        di as error "Unknown call to glm link function"
        exit 198
end
