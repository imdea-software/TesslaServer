define test_calls: Events<Int> := function_call_parameter("minimal.c:test", 0)

define error: Events<Unit> := leq(5,test_calls)

-- out error
