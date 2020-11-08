import Path

env = Application.get_env(:arkenston, :environment)
seeds = wildcard(join([__DIR__, "seeds", "*.{ex,exs}"])) ++ wildcard(join([__DIR__, "seeds", "#{env}", "*.{ex,exs}"]))

Enum.each(seeds, fn(seed) ->
  Code.eval_file seed
end)
