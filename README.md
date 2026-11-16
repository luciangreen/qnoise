# qnoise

an error budget for each output qubit. A gate can only disturb the qubits it touches, and errors only travel forward along controls and targets, so an output qubit's error is bounded by the errors of the gates in its light cone (the gates that can reach it). Each gate kind has an error rate in parts per million; a budget says which outputs pass.

## Use

```prolog
?- use_module(prolog/qnoise).
?- cone([x(0), cnot(0, 1), x(2)], 3, 1, C).            % C = [1, 2]: gate positions (1-based) that can reach qubit 1
?- budget([x(0), cnot(0, 1), x(2)], 3, B).             % B = [0-100, 1-1100, 2-100]
?- check([x(0), cnot(0, 1), x(2)], 3, 500, R).         % R = [1-over(1100)]
```

## Proofs

`proofs/theorems.pl` proves 4 theorems by exhaustion: each one is checked for every case in a finite domain that covers every branch of the definitions. every circuit of up to 3 gates on 3 qubits.

1. Gates outside a qubit's light cone never affect it: removing any one of them leaves the qubit's value the same on every input.
2. A qubit's budget is at most the whole circuit's error, and at least that of the gates that target it.
3. Adding a gate at the end never lowers any budget.
4. check reports exactly the qubits over the limit.

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` lists 200 inputs and outputs from real runs, and `io/ios.pl` has the same as Prolog facts. The inputs come from a fixed seed (`io/cases.pl`). `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output, which checks steadfastness. GitHub Actions runs the proofs and the examples on every push, and records the examples on the first push.

Licence: BSD-3-Clause.
