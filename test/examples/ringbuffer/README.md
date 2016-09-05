# Howto Build

    clang -c -o buffer.o buffer.c
    clang -o buffer buffer.o  -L/usr/local/lib -lzlog -lpthread

# Howto Run

All output is logged to `traces.1`:

    ./buffer
    # Enter Whatever you want to buffer, Ctrl-C to quit

# Howto order Traces by timestamp

    sort -k 3 -k 4 -n traces.1 > traces.2

You have to change Events with same timestamp (e.g. add 1 to it) manually.



