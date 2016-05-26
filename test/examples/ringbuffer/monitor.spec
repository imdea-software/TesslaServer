--
-- Macros
--
define prop(e1,e2): Signal<Boolean> := eq(mrv(merge(ifThen(e1, literal(1)), ifThen(e2, literal(0))), 0), literal(1))

--
-- Input
--
define writePointerAddr := variable_values("buffer.c:write_ptr")
define processCall := function_calls("buffer.c:process")
--define startConsumer := function_calls("main.c:startConsumers")


--
-- Spec
--
define writePointerChanged := changeOf(writePointerAddr)
define clk := occurAny(processCall, writePointerChanged)
define process := prop(processCall, clk)
define write := prop(writePointerChanged, clk)

define monitor_output := monitor("
  always(p1 implies (not(p1) until p2))",
  p1 := write,
  p2 := process,
  clock := clk
)

-- out monitor_output

