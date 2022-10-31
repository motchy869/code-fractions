function sys_out = approxDeriv(sys_in, c)
    % approxDeriv Replace `s` in tf object with `s/(c*s+1)` where `0 < c < 1`.
    % Applying this operation, a non-proper transfer function can be
    % approximated by a proper one.
    % 
    % sys_out = approxDeriv(sys_in, c)
    %
    % ## Inputs
    % 
    % sys_in: original tf object
    % c: approximation factor
    %
    % ## Outputs
    % 
    % sys_out: converted tf object
    
    arguments
        sys_in (1,1) tf
        c (1,1) {mustBeInRange(c,0,1,"exclude-lower","exclude-upper")}
    end
    
    syms s
    [coeffs_num,coeffs_den] = tfdata(sys_in);
    num = poly2sym(coeffs_num, s);
    den = poly2sym(coeffs_den, s);
    T = symfun(num/den,s);
    T_approx = simplifyFraction(subs(T,s,s/(c*s+1)));
    [num2,den2] = numden(T_approx);
    coeffs_num2 = sym2poly(num2);
    coeffs_den2 = sym2poly(den2);
    sys_out = tf(coeffs_num2,coeffs_den2);
end
