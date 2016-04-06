define source_event := function_calls("main.c:open_door")
define target_event := function_returns("main.c:open_door")

define monitor_output := monitor(
  "always (if p1 then next timed[<= 1200] p2)",
  source_event,
  target_event
)

-- out monitor_output<Paste>
