# Howto benchmark

To run the benchmark with TesslaServer V1 and 8 nodes:

    dumbbench --table=data_v1/time_8.dat -p 0.0001 -m 20 -- ./tessla_server_v1 8_nodes.tessla --trace traces_1000 -o 4:finished

Note that for different specifications you have to change the output node id.
The respictive ids are:

Nodecount -> ID
8   ->  4
16  ->  4
32  ->  12
64  ->  59
128 ->  107
