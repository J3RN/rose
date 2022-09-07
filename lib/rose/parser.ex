defmodule Rose.Parser do
  @doc """
  Accepts a file path and must return an Elixir AST representing the code within
  that file.
  """
  @callback parse(String.t()) :: tuple()
  import NimbleParsec

  defmacro __using__(_) do
    quote do
      @behaviour Rose.Parser
      import Rose.Parser

      def run(_args) do
        project = Mix.Project.config()
        srcs = project[:elixirc_paths]

        unless is_list(srcs), do: raise("elixirc_paths must be a list")

        files = Mix.Utils.extract_files(srcs, [:ast])

        Enum.each(files, fn file ->
          file
          |> Code.eval_file()
          |> :elixir_compiler.quoted(file, fn _, _ -> nil end)
        end)
      end
    end
  end

  # From tree-sitter
  def repeat1(combinator \\ empty(), rule) do
    combinator
    |> times(rule, min: 1)
  end

  # From tree-sitter-elixir
  def sep1(combinator \\ empty(), rule, separator) do
    combinator
    |> concat(rule)
    |> repeat(separator |> concat(rule))
  end
end
