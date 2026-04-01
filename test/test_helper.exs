Application.put_env(:junit_formatter, :include_filename?, true)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
