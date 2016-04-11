define test_calls: Events<Int> := function_call_parameter("minimal.c:test", 0)
define x_values: Events<Int> := variable_update("minimal.c:x")

define error: Events<Unit> := leq(x_values,test_calls)

-- out error
