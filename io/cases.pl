:- module(cases, [title/1, case/3]).
:- use_module('../prolog/qnoise').
:- use_module(engine).
title('qnoise').
gate_g(N, G) :- Top is N - 1, rnd_int(0, Top, T), rnd_int(1, Top, D), C is (T + D) mod N, rnd_int(1, Top, E), C2 is (T + E) mod N,
    ( C2 =:= C -> rnd_pick([x(T), cnot(C, T)], G) ; rnd_pick([x(T), cnot(C, T), ccnot(C, C2, T)], G) ).
circ_g(N, Gs) :- rnd_int(0, 6, L), length(Gs, L), maplist(gate_g(N), Gs).
case(budget, [C, N], budget) :- rnd_int(3, 5, N), circ_g(N, C).
case(cone, [C, N, Q], cone) :- rnd_int(3, 5, N), circ_g(N, C), Top is N - 1, rnd_int(0, Top, Q).
case(check, [C, N, L], check) :- rnd_int(3, 5, N), circ_g(N, C), rnd_pick([500, 2000, 8000], L).
