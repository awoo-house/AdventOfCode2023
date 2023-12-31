defmodule Almanac do
  def starts_with_letter?(string) when is_binary(string) do
    case String.first(string) do
      <<char::utf8>> when (char >= ?a and char <= ?z) or (char >= ?A and char <= ?Z) ->
        true

      _ ->
        false
    end
  end

  def get_dst_from_src(almanac, key, seed) do
    # for each {dst, src, range} triple, see if our seed is between src and src+range
    # "Any source numbers that aren't mapped correspond to the same destination number."
    Map.get(almanac, key)
    |> Enum.reduce(seed, fn el, acc ->
      {src, _} = Integer.parse(Enum.at(el, 1))
      {range, _} = Integer.parse(Enum.at(el, 2))
      {dst, _} = Integer.parse(Enum.at(el, 0))

      if seed > src and seed < src + range do
        dst + seed - src
      else
        acc
      end
    end)
  end

  def convert_to_seed_ranges(seeds) do
    Enum.chunk_every(seeds, 2)
    |> Enum.flat_map(fn [a, b] ->
      {ai, _} = Integer.parse(a)
      {bi, _} = Integer.parse(b)
      Enum.to_list(ai..(ai + bi))
    end)
  end

  def build(input) do
    String.split(input, "\n", trim: true)
    |> Enum.reduce({%{}, ""}, fn str, {map, last_ft} ->
      cond do
        String.starts_with?(str, "seeds") ->
          # build the seed list
          l = String.replace(str, ~r/.*\: /, "") |> String.split(" ", trim: true)
          {Map.put_new(map, "seeds", l), last_ft}

        starts_with_letter?(str) ->
          s = String.split(str, " ") |> List.first() |> String.split("-", trim: true)
          from_to = List.first(s) <> "-" <> List.last(s)
          last_ft = from_to
          {Map.put_new(map, from_to, []), last_ft}

        str != "" ->
          # not a new map, not seeds, not a blank line

          {map
           |> Map.update(last_ft, [], fn existing ->
             new = String.split(str, " ")
             existing ++ [new]
           end), last_ft}

        true ->
          {map, last_ft}
      end
    end)
  end
end

defmodule AmmyFive do
  def run do
    case File.read("input/day5.in") do
      {:ok, input} ->
        almanac = elem(Almanac.build(input), 0)
        Almanac.convert_to_seed_ranges(Map.get(almanac, "seeds"))

        # holy fuck this is *gravely* inefficient but uh, I got an answer...after seventeen minutes...
        ans =
          Almanac.convert_to_seed_ranges(Map.get(almanac, "seeds"))
          |> Enum.reduce([], fn seed, acc ->
            ans = Almanac.get_dst_from_src(almanac, "seed-soil", seed)
            ans = Almanac.get_dst_from_src(almanac, "soil-fertilizer", ans)
            ans = Almanac.get_dst_from_src(almanac, "fertilizer-water", ans)
            ans = Almanac.get_dst_from_src(almanac, "water-light", ans)
            ans = Almanac.get_dst_from_src(almanac, "light-temperature", ans)
            ans = Almanac.get_dst_from_src(almanac, "temperature-humidity", ans)
            ans = Almanac.get_dst_from_src(almanac, "humidity-location", ans)
            acc ++ [ans]
          end)
          |> Enum.min()

        IO.inspect(ans)

      {:error, reason} ->
        IO.write(reason)
    end
  end
end
