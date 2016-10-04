# Introduction

# Howto build

# Howto run
# Howto test
# Howto examples
# Howto benchmark

Most of the benchmarks require the [dumbbench](https://github.com/tsee/dumbbench) perl program to be installed and in the path.

Note that most benchmarks rely on the executed program to terminate.
Based on TesslaServers distributed nature it won't terminate in it's normal configuration.
Therefore the executables inside the benchmark directorys are changed in a way, that they will terminate
as soon as an output emits `true`.

For everything else look at the `README.md` in the folder of the respective benchmark.
