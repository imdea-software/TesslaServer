define num_events: Signal<Int> := literal(10000)

define add_calls: Events<Unit> := function_calls("add")

define add_call_sum: Signal<Int> := eventCount(add_calls)

define overhead_0: Signal<Int> := signalAbs(add_call_sum)
define overhead_1: Signal<Int> := signalAbs(overhead_0)
define overhead_2: Signal<Int> := signalAbs(overhead_1)
define overhead_3: Signal<Int> := signalAbs(overhead_2)
define overhead_4: Signal<Int> := signalAbs(overhead_3)
define overhead_5: Signal<Int> := signalAbs(overhead_4)
define overhead_6: Signal<Int> := signalAbs(overhead_5)
define overhead_7: Signal<Int> := signalAbs(overhead_6)
define overhead_8: Signal<Int> := signalAbs(overhead_7)
define overhead_9: Signal<Int> := signalAbs(overhead_8)
define overhead_10: Signal<Int> := signalAbs(overhead_9)
define overhead_11: Signal<Int> := signalAbs(overhead_10)
define overhead_12: Signal<Int> := signalAbs(overhead_11)

define finished: Signal<Boolean> := eq(overhead_12, num_events)
