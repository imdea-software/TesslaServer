define prop(e1,e2): Signal<Boolean> := eq(mrv(merge(ifThen(e1, literal(1)), ifThen(e2, literal(0))), 0), literal(1))

define writePointerAddr: Signal<Int> := variable_values("buffer.c:write_ptr")
define processCall: Events<Unit> := function_calls("buffer.c:process")

define writePointerChanged := changeOf(writePointerAddr)
define clk := occurAny(processCall, writePointerChanged)
define process := prop(processCall, clk)
define write := prop(writePointerChanged, clk)

define monitor := monitor("
    always (if p1 then next timed[<= 100] p2)",
    p1 := write,
    p2 := process,
    clock := clk
)
