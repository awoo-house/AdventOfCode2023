defmodule Advent8Test do
  use ExUnit.Case
  doctest Advent8


  test "parse_graph_line" do
    out = Advent8.parse_graph_line(%{}, "AAA = (BBB, CCC)")
    assert out == %{ "AAA" => { "BBB", "CCC" }}
  end

  test "parse_direction_line" do
    out = Advent8.parse_direction_line("LLR")
    assert out == [ :l, :l, :r ]
  end

  test "parse_input" do
    out = Advent8.parse_input("""
      LLR

      AAA = (BBB, BBB)
      BBB = (AAA, ZZZ)
      ZZZ = (ZZZ, ZZZ)
    """)

    assert out.steps == [ :l, :l, :r ]
    assert out.nodes == %{
      "AAA" => { "BBB", "BBB" },
      "BBB" => { "AAA", "ZZZ" },
      "ZZZ" => { "ZZZ", "ZZZ" }
    }
  end

  test "Part 1 Example" do
    inp = Advent8.parse_input("""
      LLR

      AAA = (BBB, BBB)
      BBB = (AAA, ZZZ)
      ZZZ = (ZZZ, ZZZ)
    """)

    assert Advent8.count_steps(inp) == 6
  end

end