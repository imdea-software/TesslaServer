-- base streams to use for others
define string_signal:       Signal<String>      := variable_values("minimal.c:string")
define int_signal:          Signal<Int>         := variable_values("minimal.c:int")
define boolean_signal:      Signal<Boolean>     := variable_values("minimal.c:boolean")

define string_events:       Events<String>      := changeOf(string_signal)
define int_events:          Events<Int>         := changeOf(int_signal)
define boolean_events:      Events<Boolean>     := changeOf(boolean_signal)
define unit_events:         Events<Unit>        := function_calls("minimal.c:boolean")

-- Input/Constant
define literal_int_signal:            Signal<Int>         := literal(1)
-- define literal_string_signal:      Signal<String>      := literal("string")
-- define literal_boolean_signal:     Signal<Boolean>     := literal(true)
define instruction_executions_events: Events<Unit>        := instruction_executions("minimal.c:23")
define function_returns_events:       Events<Unit>        := function_returns("minimal.c:test")
define function_calls_events:         Events<Unit>        := function_calls("minimal.c:test")
define variable_values_string:        Signal<String>      := variable_values("minimal.c:string")
define variable_values_int:           Signal<Int>         := variable_values("minimal.c:int")
define variable_values_boolean:       Signal<Boolean>     := variable_values("minimal.c:boolean")

-- Lifted
define abs_signal:          Signal<Int>         := signalAbs(int_signal)
define abs_events:          Events<Int>         := eventAbs(int_events)
define add_signal:          Signal<Int>         := add(int_signal, int_signal)
define and_signal:          Signal<Boolean>     := and(boolean_signal, boolean_signal)
define div_signal:          Signal<Int>         := div(int_signal, int_signal)
define eq_int_signal:       Signal<Boolean>     := eq(int_signal, int_signal)
define eq_boolean_signal:   Signal<Boolean>     := eq(boolean_signal, boolean_signal)
define eq_string_signal:    Signal<Boolean>     := eq(string_signal, string_signal)
define geq_signal:          Signal<Boolean>     := geq(int_signal, int_signal)
define gt_signal:           Signal<Boolean>     := gt(int_signal, int_signal)
define implies_signal:      Signal<Boolean>     := implies(boolean_signal, boolean_signal)
define leq_signal:          Signal<Boolean>     := leq(int_signal, int_signal)
define lt_signal:           Signal<Boolean>     := lt(int_signal, int_signal)
define max_signal:          Signal<Int>         := max(int_signal, int_signal)
define min_signal:          Signal<Int>         := min(int_signal, int_signal)
define mul_signal:          Signal<Int>         := mul(int_signal, int_signal)
define neg_signal:          Signal<Int>         := neg(int_signal)
define not_signal:          Signal<Boolean>     := signalNot(boolean_signal)
define not_events:          Events<Boolean>     := eventNot(boolean_events)
define or_signal:           Signal<Boolean>     := or(boolean_signal, boolean_signal)
define sub_signal:          Signal<Int>         := sub(int_signal, int_signal)

-- Filter
define merge_int_events:      Events<Int>         := merge(int_events, int_events)
define merge_string_events:   Events<String>      := merge(string_events, string_events)
define merge_boolean_events:  Events<Boolean>     := merge(boolean_events, boolean_events)

define filter_int_events:     Events<Int>         := filter(int_events, boolean_signal)
define filter_string_events:  Events<String>      := filter(string_events, boolean_signal)
define filter_boolean_events: Events<Boolean>     := filter(boolean_events, boolean_signal)

define ifThen_int_events:     Events<Int>         := ifThen(unit_events, int_signal)
define ifThen_string_events:  Events<String>      := ifThen(unit_events, string_signal)
define ifThen_boolean_events: Events<Boolean>     := ifThen(unit_events, boolean_signal)

define ifThenElse_int_signal:     Signal<Int>         := ifThenElse(boolean_signal, int_signal, int_signal)
define ifThenElse_string_signal:  Signal<String>      := ifThenElse(boolean_signal, string_signal, string_signal)
define ifThenElse_boolean_signal: Signal<Boolean>     := ifThenElse(boolean_signal, boolean_signal, boolean_signal)

define changeOf_int_events:     Events<Int>         := changeOf(int_signal)
define changeOf_string_events:  Events<String>      := changeOf(string_signal)
define changeOf_boolean_events: Events<Boolean>     := changeOf(boolean_signal)

define sample_int_events:     Events<Int>         := sample(int_signal, unit_events)
define sample_string_events:  Events<String>      := sample(string_signal, unit_events)
define sample_boolean_events: Events<Boolean>     := sample(boolean_signal, unit_events)

define occurAll_events:       Events<Unit>        := occurAll(unit_events, int_events)
define occurAny_events:       Events<Unit>        := occurAll(unit_events, int_events)

-- Aggregation
define maximum_from_events:   Signal<Int>         := eventMaximum(int_events, 0)
define maximum_from_signal:   Signal<Int>         := signalMaximum(int_signal)
define minimum_from_events:   Signal<Int>         := eventMinimum(int_events, 0)
define minimum_from_signal:   Signal<Int>         := signalMinimum(int_signal)

define sum_signal:            Signal<Int>         := sum(int_events)
define eventCount_signal:     Signal<Int>         := eventCount(unit_events)
define mrv_int_signal:        Signal<Int>         := mrv(int_events, 0)
-- define mrv_string_signal:     Signal<String>      := mrv(string_events, "")
-- define mrv_boolean_signal:    Signal<Boolean>     := mrv(boolean_events, false)
define sma_events:            Events<Int>         := sma(int_events, 3)

-- Timing
define timestamps_events:         Events<Int>         := timestamps(unit_events)
define delay_int_events_by_time:  Events<Int>         := delayEventByTime(int_events, 2000)
define delay_int_events_by_count: Events<Int>         := delayEventByCount(int_events, 2)
define delay_int_signal_by_time:  Signal<Int>         := delaySignalByTime(int_signal, 2000, 0)
-- define within_signal:         Signal<Boolean>     := within(2, 3, int_events)
define inPast_signal:             Signal<Boolean>     := inPast(2, int_events)
-- define inFuture_signal:       Signal<Boolean>     := inFuture(2, int_events)


-- out error
