defmodule Mix.Tasks.Compile.Elisper do
  use Rose.Parser
  import NimbleParsec

  def parse(file) do
    File.read!(file)
    |> source_file()
    |> IO.inspect()
  end

  @term(~r{(defmodule\s*((?<mod>).)+}, [
    :defmodule,
    [context: Elixir, import: [{Kernel, 2}]],
    [{:__aliases__, [], mod}]
  ])

  newline = optional(utf8_char([?\r])) |> utf8_char([?\n])
  whitespace = ignore(choice([utf8_char([?\s, ?\t]), newline]))

  identifier =
    utf8_string([?a..?z], min: 1)
    |> repeat(utf8_string([?a..?z, ?A..?Z, ?0..?9], min: 1))
    |> map({String, :to_atom, []})

  variable =
    wrap(identifier)
    |> map({List, :to_tuple, []})
    |> map({Tuple, :insert_at, [1, [if_undefined: :apply]]})
    |> map({Tuple, :insert_at, [2, Elixir]})

  namespace_part =
    wrap(
      utf8_string([?A..?Z], min: 1)
      |> repeat(utf8_string([?a..?z, ?A..?Z, ?0..?9], min: 1))
    )
    |> map({Enum, :join, []})
    |> map({String, :to_atom, []})

  module =
    wrap(wrap(sep1(namespace_part, ignore(string(".")))))
    |> map({List, :to_tuple, []})
    |> map({Tuple, :insert_at, [0, :__aliases__]})
    |> map({Tuple, :insert_at, [1, [alias: false]]})

  ddefmodule =
    wrap(
      ignore(string("("))
      |> string("defmodule")
      |> map({String, :to_atom, []})
      |> ignore(repeat1(whitespace))
      |> wrap(
        module
        |> repeat1(whitespace)
        |> concat(
          wrap(
            wrap(
              wrap(wrap(repeat(parsec(:expression) |> repeat(whitespace))))
              |> map({List, :to_tuple, []})
              |> map({Tuple, :insert_at, [0, :__block__]})
              |> map({Tuple, :insert_at, [1, []]})
            )
            |> map({List, :to_tuple, []})
            |> map({Tuple, :insert_at, [0, :do]})
          )
        )
      )
      |> ignore(string(")"))
    )
    |> map({List, :to_tuple, []})
    |> map({Tuple, :insert_at, [1, [context: Elixir, import: Kernel]]})

  function_name =
    choice([
      optional(module |> utf8_char([?.])) |> concat(identifier),
      utf8_string([?+, ?-, ?*, ?/], min: 1) |> map({String, :to_atom, []})
    ])

  parameters =
    wrap(
      ignore(string("("))
      |> optional(variable |> repeat(repeat1(whitespace) |> concat(variable)))
      |> ignore(string(")"))
    )

  ddef =
    wrap(
      ignore(string("("))
      |> string("def")
      |> map({String, :to_atom, []})
      |> repeat1(whitespace)
      |> concat(
        wrap(
          wrap(
            identifier
            |> repeat1(whitespace)
            |> concat(parameters)
          )
          |> map({List, :to_tuple, []})
          |> map({Tuple, :insert_at, [1, [context: Elixir]]})
          |> repeat1(whitespace)
          |> concat(wrap(repeat(parsec(:expression) |> repeat(whitespace))))
        )
      )
      |> ignore(string(")"))
    )
    |> map({List, :to_tuple, []})
    |> map({Tuple, :insert_at, [1, [context: Elixir, import: Kernel]]})

  arguments =
    wrap(optional(repeat1(whitespace) |> sep1(parsec(:expression), repeat1(whitespace))))

  function =
    wrap(
      ignore(string("("))
      |> concat(function_name)
      |> concat(arguments)
      |> ignore(string(")"))
    )
    |> map({List, :insert_at, [1, [context: Elixir]]})
    |> map({List, :to_tuple, []})

  integer = utf8_string([?0..?9, ?_], min: 1) |> map({String, :to_integer, []})
  string = utf8_char([?"]) |> utf8_string([], min: 0) |> utf8_char([?"])

  defparsec(
    :expression,
    choice([
      ddefmodule,
      ddef,
      function,
      module,
      variable,
      integer,
      string
    ])
  )

  defparsec(
    :source_file,
    empty()
    |> optional(whitespace)
    |> repeat(parsec(:expression), optional(whitespace))
  )
end
