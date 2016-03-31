define writes: Events<Int> := variable_updates("main.c:write_ptr")
define processed: Events<Int> := function_calls("main.c:process")

define bufLevel: Signal<Int> := diff(count(writes), count(processed))

define error: Events<Unit> := onFalse(and(leq(0,bufLevel), leq(bufLevel,5)))

-- out error
