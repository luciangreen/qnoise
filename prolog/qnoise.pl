% qnoise: an error budget for each output qubit. A gate can only disturb the qubits it touches,
% and errors only travel forward along controls and targets, so an output qubit's error is
% bounded by the errors of the gates in its light cone (the gates that can reach it). Each
% gate kind has an error rate in parts per million; a budget says which outputs pass.
%?- cone([x(0), cnot(0, 1), x(2)], 3, 1, C).            % C = [1, 2]: gate positions (1-based) that can reach qubit 1
%?- budget([x(0), cnot(0, 1), x(2)], 3, B).             % B = [0-100, 1-1100, 2-100]
%?- check([x(0), cnot(0, 1), x(2)], 3, 500, R).         % R = [1-over(1100)]
:- module(qnoise, [gate/3, run/3, bits/2, rate/2, cone/4, budget/3, check/4]).
:- use_module(library(lists)).
:- use_module(library(apply)).

flip(T, B0, B) :- nth0(T, B0, X), Y is 1 - X, length(Pre, T), append(Pre, [_|Post], B0), append(Pre, [Y|Post], B).
gate(x(T), B0, B) :- flip(T, B0, B).
gate(cnot(C, T), B0, B) :- ( nth0(C, B0, 1) -> flip(T, B0, B) ; B = B0 ).
gate(ccnot(C1, C2, T), B0, B) :- ( nth0(C1, B0, 1), nth0(C2, B0, 1) -> flip(T, B0, B) ; B = B0 ).
run(G, B0, B) :- foldl(gate, G, B0, B1), B = B1.
bits(N, B) :- length(B, N), maplist([X]>>member(X, [0, 1]), B).

rate(x(_), 100).
rate(cnot(_, _), 1000).
rate(ccnot(_, _, _), 5000).

wires(G, W) :- G =.. [_|W].
targets(x(T), [T]).
targets(cnot(_, T), [T]).
targets(ccnot(_, _, T), [T]).

% cone(+Circuit, +N, +Qubit, -GatePositions): walk backwards from the qubit, adding a gate when it
% targets a qubit in the set, and then all its wires to the set.
cone(C, _, Q, Ps) :- length(C, L), reverse(C, R), cone_(R, L, [Q], [], Ps0), msort(Ps0, Ps).
cone_([], _, _, Ps, Ps).
cone_([G|Gs], I, Set, Ps0, Ps) :- I1 is I - 1, targets(G, Ts),
    ( member(T, Ts), memberchk(T, Set) -> wires(G, W), append(Set, W, S0), sort(S0, Set1), cone_(Gs, I1, Set1, [I|Ps0], Ps) ; cone_(Gs, I1, Set, Ps0, Ps) ).

budget(C, N, B) :- Top is N - 1, numlist(0, Top, Qs), maplist([Q, Q-E]>>( cone(C, N, Q, Ps), foldl([P, A0, A]>>( nth1(P, C, G), rate(G, R), A is A0 + R ), Ps, 0, E) ), Qs, B).
check(C, N, Limit, Over) :- budget(C, N, B), findall(Q-over(E), ( member(Q-E, B), E > Limit ), Over).
