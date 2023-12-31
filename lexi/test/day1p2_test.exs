defmodule Day1p2Test do
  use ExUnit.Case
  doctest Day1

  test "Day 1 Part 2" do
    input_output = %{
      "two1nine" => 29,
      "eightwothree" => 83,
      "abcone2threexyz" => 13,
      "xtwone3four" => 24,
      "4nineeightseven2" => 42,
      "zoneight234" => 14,
      "7pqrstsixteen" => 76,
      "eighthree" => 83
    }

    Enum.each(input_output, fn {input, output} ->
      assert Day1.processLine(input) == output
    end)

  end

  test "replaceNumberStrings" do
    assert Day1.replaceNumberStrings("two1nine") == "2wo19ine"
  end
  test "replaceNumberStrings for internal strings" do
    assert Day1.replaceNumberStrings("xtwone3four") == "x2w1ne34our"
  end
  test "replaceNumberStrings for internal strings 2" do
    assert Day1.replaceNumberStrings("eighthree") == "8igh3hree"
  end
end
