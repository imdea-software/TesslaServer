define test_calls: Events<Int> := function_calls("minimal.c:test")

define error: Events<Unit> := onFalse(geq(5,test_calls))

-- out error
