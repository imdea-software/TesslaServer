define num_events: Signal<Int> := literal(1000)

define add_calls: Events<Unit> := function_calls("add")

define add_call_sum: Signal<Int> := eventCount(add_calls)

define overhead_0: Signal<Int> := signalAbs(add_call_sum)
define overhead_1: Signal<Int> := signalAbs(overhead_0)
define overhead_2: Signal<Int> := signalAbs(overhead_1)
define overhead_3: Signal<Int> := signalAbs(overhead_2)
define overhead_4: Signal<Int> := signalAbs(overhead_3)

define finished: Signal<Boolean> := eq(overhead_4, num_events)
