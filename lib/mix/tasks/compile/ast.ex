defmodule Mix.Tasks.Compile.Ast do
  use Rose.Parser

  def parse(file), do: Code.eval_file(file)
end
