define writes: Events<Int> := variable_update("main.c:write_ptr")
define processed: Events<Int> := function_call_parameter("main.c:process", 0)

define bufLevel: Signal<Int> := diff(eventCount(writes), eventCount(processed))

define error: Events<Unit> := onFalse(and(leq(0,bufLevel), leq(bufLevel,5)))

-- out error
