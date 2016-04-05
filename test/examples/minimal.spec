define test_calls: Events<Int> := function_call_parameter("minimal.c:test", 0)

define error: Events<Unit> := onFalse(geq(5,test_calls))

-- out error
