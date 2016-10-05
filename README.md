# TesslaServer

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)[![Build Status](https://semaphoreci.com/api/v1/miradorn/tesslaserver/branches/master/badge.svg)](https://semaphoreci.com/miradorn/tesslaserver)[![Deps Status](https://beta.hexfaktor.org/badge/all/github/imdea-software/TesslaServer.svg)](https://beta.hexfaktor.org/github/imdea-software/TesslaServer)[![Coverage Status](https://coveralls.io/repos/github/imdea-software/TesslaServer/badge.svg?branch=master)](https://coveralls.io/github/imdea-software/TesslaServer?branch=master)

## Introduction

TesslaServer implements a Runtime for Tessla specifications written in Elixir.
Tessla is a project of the ISP at the University of Luebeck in Germany.
A short introduction can be found [here](https://www.coniras.org/wp-content/uploads/2016/01/CONIRAS_SMD_2.pdf).
One part of Tessla is the compiler, which takes a specification and translates it into json.
While the compiler isn't available you can probably get a copy by geting in contact with the ISP.

For test and benchmark purposes some specifications are provided before and after compilation.

To use this runtime you have to have at least the Erlang plattform installed (including BEAM), but it is recommended
to also install Elixir for development purposes.

TesslaServer was implemented as part of the Master Thesis of Alexander Schramm, which will be available at GitHub at some point after he has finished it.
The Chapter *Implementation Details* contains a lot of useful information about the general architecture of the runtime.

## Howto build

If you have Elixir installed you can built an escript with `mix escript.build` and run it afterwards.

For test and development purposes you can also load the project into an REPL by using `iex -S mix`.

## Howto run

After building the escript you can run TesslaServer by entering `./tessla_server $specification.tessla`.
Now you can enter events by hand in the format `stream_name value seconds microseconds`, e.g.:
`function_calls:increment 1 12341234 12234`.

Maybe more comfortable you can also feed a file containing traces to the runtime with the `--trace` option:

    ./tessla_server example.tessla --trace example.trace

Finally you might be interested in actual conclusions the runtime.
Since the Tessla Compiler at this point doesn't include informations about outputs in the compiled files you have to
specify the output nodes on the command line with the `-o` switch:

    ./tessla_server example.tessla --trace example.trace -o 4:error -o 15:counter

As you can see you can include multiple outputs.
The format is simply the id of the node in the specification followed by a colon followed by a name you are free to choose for the node.
Running this command will output information about the nodes 4 and 15 everytime they progress or emit an event/change.
Since this might get noisy you can obviously pipe it into `grep`, e.g.:

    ./tessla_server example.tessla --trace example.trace -o 4:error | grep "value: true"

if you only want to be notified about the fact, when node 4 emits a `true` event.

## Howto test

See Elixir testing, to run tests enter: `mix test`

## Howto examples

Under `test/examples` some example specifications are given.
Except the `minimal` example all should run as expected.

## Howto benchmark

Most of the benchmarks require the [dumbbench](https://github.com/tsee/dumbbench) perl program to be installed and in the path.

Note that most benchmarks rely on the executed program to terminate.
Based on TesslaServers distributed nature it won't terminate in it's normal configuration.
Therefore the executables inside the benchmark directorys are changed in a way, that they will terminate
as soon as an output emits `true`.

For everything else look at the `README.md` in the folder of the respective benchmark.
