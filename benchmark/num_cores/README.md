# Execution Time Benchmark in regards to cores

Note that this benchmark directory only contains the recent revision of executable (V2 at the moment).
To benchmark older Versions use git to go back in time.

## Howto Benchmark

To run all benchmarks (1, 2, 4, 8, 16) cores in sequence just use `./bench.sh`.

For a more specific benchmark use:

    dumbbench --table=1_cores.dat -p 0.0001 -m 5 -- ./tessla_server_1 parallel-16.tessla --trace traces.1 -o 4:finished
