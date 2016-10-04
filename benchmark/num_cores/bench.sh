#!/bin/bash

num_cores=(1 2 4 8 16);

for i in "${num_cores[@]}"
do
  dumbbench --table=${i}_cores.dat -p 0.0001 -m 5 -- ./tessla_server_$i parallel-16.tessla --trace traces.1 -o 4:finished
done
