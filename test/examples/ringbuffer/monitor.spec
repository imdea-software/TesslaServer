--
-- Macros
--
define prop(e1,e2): Signal<Boolean> := eq(mrv(merge(ifThen(e1, literal(1)), ifThen(e2, literal(0))), 0), literal(1))

--
-- Input
--
define readPointerAddr := variable_values("main.c:read_idx")
define stopConsumer := function_calls("main.c:stopConsumers")
define startConsumer := function_calls("main.c:startConsumers")


--
-- Spec
--
define readPointerChanged := changeOf(readPointerAddr)
define clk := occurAny(occurAny(stopConsumer, readPointerChanged), startConsumer)
define stop := prop(stopConsumer, clk)
define start := prop(startConsumer, clk)
define change := prop(readPointerChanged, clk)

define monitor_output := monitor("
  always(p1 implies (not(p2) until p3))",
  p1 := stop,
  p2 := change,
  p3 := start,
  clock := clk
)

-- out monitor_output

