define values: Signal<Int> := variable_values("main.c:write_ptr")
define writes: Events<Int> := changeOf(values)
define processed: Events<Unit> := function_calls("main.c:process")

define bufLevel: Signal<Int> := sub(eventCount(writes), eventCount(processed))

define error: Signal<Boolean> := signalNot(and(leq(literal(0),bufLevel), leq(bufLevel,literal(5))))

-- out error
