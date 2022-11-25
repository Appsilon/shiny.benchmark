utils::globalVariables(
  c(
    "commit",
    "date",
    "duration_ms",
    "max",
    "mean",
    "min",
    "n",
    "sd",
    "test_name",
    "total_time"
  )
)

# Setting threshold to debug (temporary and should be removed)
logger::log_threshold(logger::DEBUG)
