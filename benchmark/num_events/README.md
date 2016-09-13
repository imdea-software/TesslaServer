# Benchmark Execution Time



# Execute Ram Benchmark:

Note that the data in `unused.dat` and `tmp` is not interesting, the interesting data is the output of the command in the lines prefixed with `memusg`.
Also note that the data is in KibiByte, to get GB you have to multiply it by 1024.
To execute the benchmark on V1 with 1000 events as the target use:

    dumbbench --table=unused.dat -p 0.0001 -m 20 -- ./ram_benchmark.sh ./tessla_server_v1 target_1000.tessla --trace traces_1000 > tmp
