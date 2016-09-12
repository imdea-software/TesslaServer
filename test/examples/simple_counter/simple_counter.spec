define counter_calls: Events<Unit> := function_calls("counter.c:inc")
define counter_returns: Events<Unit> := function_returns("counter.c:inc")
define counter_value: Signal<Int> := variable_values("counter.c:count")

define called_in_last_millisecond: Signal<Boolean> := inPast(1000, counter_calls)

-- not perfect, in async systems new call may lead to wrong negatives when counter is called again before return
define function_took_over_one_millisecond: Events<Boolean> := ifThen(counter_returns, called_in_last_millisecond)
