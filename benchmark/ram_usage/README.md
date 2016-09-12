# Execute Ram Benchmark:

Note that the data in `unused.dat` is not interesting, the interesting data is the output of the command in the lines prefixed with `memusg`.
Also note that the data is in KibiByte, to get GB you have to multiply it by 1024.

    dumbbench --table=unused.dat -p 0.0001 -m 20 -- ./bench.sh ./tessla_server_v1 parallell-16.tessla --trace traces.1
