% Theorems, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).
:- use_module('../prolog/qnoise').

% Domain: every circuit of up to 3 gates on 3 qubits.
gate3(G) :- between(0, 2, T), ( G = x(T) ; between(0, 2, C), C \== T, G = cnot(C, T) ; G = ccnot(A, B, T), between(0, 2, A), between(0, 2, B), A < B, A \== T, B \== T ).
circuit(Gs) :- between(0, 3, L), length(Gs, L), maplist(gate3, Gs).
drop(I, L, L2) :- nth1(I, L, _, L2).

% 1. Gates outside a qubit's light cone never affect it: removing any one of them leaves the qubit's value the same on every input.
theorem(outside_cone_never_matters) :- forall(( circuit(C), length(C, L), L > 0, between(0, 2, Q), cone(C, 3, Q, Ps), between(1, L, I), \+ memberchk(I, Ps), drop(I, C, C2), bits(3, B) ),
    ( run(C, B, O1), run(C2, B, O2), nth0(Q, O1, V), nth0(Q, O2, V) )).

% 2. A qubit's budget is at most the whole circuit's error, and at least that of the gates that target it.
theorem(budget_bounds) :- forall(circuit(C), ( budget(C, 3, B), foldl([G, A0, A]>>( rate(G, R), A is A0 + R ), C, 0, T),
    forall(member(Q-E, B), ( E =< T, foldl([G, A0, A]>>( qnoise:targets(G, Ts), ( memberchk(Q, Ts) -> rate(G, R), A is A0 + R ; A = A0 ) ), C, 0, Own), E >= Own )) )).

% 3. Adding a gate at the end never lowers any budget.
theorem(budget_monotone) :- forall(( circuit(C), length(C, L), L < 3, gate3(G) ), ( budget(C, 3, B1), append(C, [G], C2), budget(C2, 3, B2), forall(member(Q-E1, B1), ( memberchk(Q-E2, B2), E2 >= E1 )) )).

% 4. check reports exactly the qubits over the limit.
theorem(check_is_exact) :- forall(( circuit(C), member(Lim, [0, 1000, 6000]) ), ( check(C, 3, Lim, O), budget(C, 3, B), forall(member(Q-E, B), iff(memberchk(Q-_, O), E > Lim)) )).
