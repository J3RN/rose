defmodule Mix.Tasks.Compile.ElisperTest do
  use ExUnit.Case

  describe "parse/1" do
    test "does the thing" do
      assert {:ok,
              [
                {:defmodule, [context: Elixir, import: Kernel],
                 [
                   {:__aliases__, [alias: false], [:Plain, :Foobar]},
                   [
                     do:
                       {:__block__, [],
                        [
                          {:def, [context: Elixir, import: Kernel],
                           [
                             {:baz, [context: Elixir], [{:x, [if_undefined: :apply], Elixir}]},
                             [
                               do:
                                 {:+, [context: Elixir, import: Kernel],
                                  [{:x, [if_undefined: :apply], Elixir}, 1]}
                             ]
                           ]},
                          {:def, [context: Elixir, import: Kernel],
                           [
                             {:qux, [context: Elixir], [{:y, [if_undefined: :apply], Elixir}]},
                             [
                               do:
                                 {:-, [context: Elixir, import: Kernel],
                                  [{:y, [if_undefined: :apply], Elixir}, 1]}
                             ]
                           ]}
                        ]}
                   ]
                 ]}
              ], _, _, _,
              _} = Mix.Tasks.Compile.Elisper.source_file(File.read!("test/fixtures/foo.elisper"))
    end
  end
end
