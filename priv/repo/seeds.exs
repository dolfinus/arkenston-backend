import Path

seeds = wildcard(join([__DIR__, "seeds", "*.{ex,exs}"])) ++ wildcard(join([__DIR__, "seeds", "#{Mix.env()}", "*.{ex,exs}"]))

Enum.each(seeds, fn(seed) ->
  Code.eval_file seed
end)