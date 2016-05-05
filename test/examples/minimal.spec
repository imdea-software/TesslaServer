define counter_values := variable_values("minimal.c:counter")
define inc_returns := function_calls("minimal.c:inc")

define return_count := eventCount(inc_returns)
define error := gt(return_count, counter_values)

-- out error
