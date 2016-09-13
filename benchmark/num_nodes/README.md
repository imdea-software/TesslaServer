# Howto benchmark

To run the benchmark with TesslaServer V1 and 8 nodes:

    dumbbench --table=V1/time_8.dat -p 0.0001 -m 20 -- ./tessla_server_v1 8_nodes.tessla --trace traces_1000 -o 4:finished

Note that for different nodecounts you have to search for the output node.
To do so open the appropriate `.tessla` file and search for the id of the `eq` node.
