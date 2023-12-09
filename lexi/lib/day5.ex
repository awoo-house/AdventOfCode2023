defmodule Almanac do
  defstruct seeds: [], maps: %{}

  @keys [
    {:seed, :soil },
    {:soil, :fertilizer },
    {:fertilizer, :water},
    {:water, :light},
    {:light, :temperature},
    {:temperature, :humidity},
    {:humidity, :location }
  ]

  def keys do
    @keys
  end



  def hydrated_mapping(map)  do
    state = %{
      :new_mapping => [],
      :last_number_mapped => -1
    }

    Enum.sort_by(map, fn {_dest_start, {source_start, _count}} ->
      source_start
    end)
    |> Enum.reduce(state, fn {dest_start, {source_start, count}}, acc ->
      nm = acc[:new_mapping]
      lm = acc[:last_number_mapped]

      always_add = {dest_start, {source_start, count}}

      to_add = if lm + 1 != source_start do
        [{lm + 1, {lm + 1, source_start - lm - 1}}, always_add]
      else
        [always_add]
      end
      %{
        :new_mapping => nm ++ to_add,
        :last_number_mapped => source_start + count - 1
      }
    end)
    |> Map.get(:new_mapping)
  end


  defp nums(input) do
    String.split(input)
    |> Enum.map(fn x -> Integer.parse(x) end)
    |> Enum.map(fn {num, _rest} -> num end)
  end
  def parse_map_internal([dest_start | [source_start | [range_length]]]) do
    [
      {dest_start, {source_start, range_length}}
    ]
  end
  def add_mapping(input, acc, key) do
    to_add = parse_map_internal(input)
    all_mappings = Map.get(acc, :maps, %{})
    this_mapping = Map.get(all_mappings, key, [])
    new_mappings = this_mapping ++ [to_add]
    new_map = Map.put(all_mappings, key, new_mappings)
    Map.put(acc, :maps, new_map)
  end

  def parse(acc, ["seed-to-soil map:" | rest]) do
    key = {:seed, :soil }
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["soil-to-fertilizer map:"| rest]) do
    key = {:soil, :fertilizer }
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["fertilizer-to-water map:" |rest]) do
    key = {:fertilizer, :water}
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["water-to-light map:" | rest]) do
    key = {:water, :light}
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["light-to-temperature map:" | rest]) do
    key = {:light, :temperature}
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["temperature-to-humidity map:" | rest]) do
    key = {:temperature, :humidity}
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["humidity-to-location map:" | rest]) do
    key = {:humidity, :location }
    parse(Map.put(acc, :current_key, key), rest)
  end
  def parse(acc, ["seeds: " <> seed_str | rest]) do
    seeds = nums(seed_str)
    parse(Map.put(acc, :seeds, seeds), rest)
  end
  def parse(acc, [""|rest]), do: parse(acc, rest)
  def parse(acc, [a|rest]), do: parse(parse(acc, a), rest)
  def parse(acc, ""), do: acc
  def parse(acc, []), do: acc

  def parse(acc, input) do
    case Integer.parse(String.slice(input, (0..1))) do
      :error ->
        # Full string to be parsed
        i = String.split(input, "\n")
        |> Enum.map(fn x -> String.trim(x) end)
        res = parse(acc, i)
        %Almanac {
          seeds: res[:seeds],
          maps: @keys
          |> Enum.map(fn x ->
            mm = if x == {:humidity, :location} do
              List.flatten(res[:maps][x])
            else
              hydrated_mapping(List.flatten(res[:maps][x]))
            end
            {x, mm }
          end)
          |> Map.new
        }
      {_, _} ->
        # Mapping line
        nums(input)
        |> add_mapping(acc, acc[:current_key])
    end
  end
end

defmodule Day5 do
  def get_mapped_value(almanac, key, val) do
    IO.puts("Getting mapped value #{inspect(key)} for #{val}")
    in_range = almanac.maps[key]
    |> Enum.map(fn {dest, {src, range}} ->
      if val >= src and val < src + range do
        # how much above src is val?
        above = val-src
        ret = dest + above
        ret
      else
        false
      end
    end)
    |> Enum.filter(fn x -> x end)

    ret = List.first(in_range, val)
    IO.puts("... it's #{ret}")
    ret

  end
  def get_lowest_location(almanac) do
    almanac.seeds
    |> Enum.map(fn seed ->
      IO.puts("seed: #{seed}")
      Almanac.keys
      |> Enum.reduce(seed, fn key, current_value -> get_mapped_value(almanac, key, current_value) end)
    end)
    |> Enum.sort
    |> List.first
  end

  # Source Range Destination starts higher than the destination can ever get to
  def get_dest_mappings_for_source_range(dest_start, count, {t_dest_start, {_t_source_start, _t_len}})
    when dest_start + count <= t_dest_start do
    nil
  end

  # Destination starts higher than Source Range Destination ever gets to.
  def get_dest_mappings_for_source_range(dest_start, _count, {t_dest_start, {_t_source_start, t_len}})
    when t_dest_start + t_len <= dest_start do
    nil
  end

  # The destination range is fully encompassed by the Source Range Destination
  def get_dest_mappings_for_source_range(dest_start, count, {t_dest_start, {t_source_start, t_len}})
    when dest_start >= t_dest_start
      and (dest_start + count) < (t_dest_start + t_len) do
    diff = t_source_start + (dest_start - t_dest_start)
    {dest_start, {diff, count}}
  end

  # The destination range fully encompasses the Source Range Destination
  def get_dest_mappings_for_source_range(dest_start, count, {t_dest_start, {t_source_start, t_len}})
    when t_dest_start >= dest_start
      and (dest_start + count) >= (t_dest_start + t_len) do
    {t_dest_start, {t_source_start, t_len}}
  end

  # The destination range ONLY intersects with the lower bound of the Source Range Destination
  def get_dest_mappings_for_source_range(dest_start, count, {t_dest_start, {t_source_start, t_len}})
    when dest_start < t_dest_start
      and (dest_start + count) < (t_dest_start + t_len) do
    diff = count - (t_dest_start - dest_start)
    {t_dest_start, {t_source_start, diff}}
  end

  # The destination range ONLY intersects with the upper bound of the Source Range Destination
  def get_dest_mappings_for_source_range(dest_start, count, {t_dest_start, {t_source_start, t_len}})
    when dest_start > t_dest_start
      and (dest_start + count) >= (t_dest_start + t_len) do
    count_diff = t_len - (dest_start - t_dest_start)
    source_start_diff = t_source_start + (dest_start - t_dest_start)
    {dest_start, {source_start_diff, count_diff}}
  end

  # We're going to build the location -> seed ranges
  def get_source_ranges_for_dest_range(dest_start, count, all_source_ranges)  do
    IO.inspect(all_source_ranges)
    Enum.map(all_source_ranges, fn x ->
      get_dest_mappings_for_source_range(dest_start, count, x)
    end)
    |> Enum.filter(fn x -> x end)
  end


  def get_source_ranges_for_dest_ranges(source_and_dest_ranges)  do
    Enum.flat_map(source_and_dest_ranges, fn {dest_start, count, all_source_ranges} ->
      get_source_ranges_for_dest_range(dest_start, count, all_source_ranges)
    end)
    |> IO.inspect
  end

  def lowest_locations_by_seed_value_ranges(almanac) do
    location_key = {:humidity, :location }
    sorted_locations = Enum.sort(almanac.maps[location_key])
    IO.inspect(sorted_locations)
    rr = Enum.flat_map(sorted_locations, fn {location_start, {humidity_start, range1}} ->

      IO.inspect("-----------")
      IO.inspect({location_start, humidity_start, range1})


      temperature_ranges_for_this_location =
        get_source_ranges_for_dest_range(humidity_start, range1, almanac.maps[{:temperature, :humidity}])

      IO.inspect("-----3-----")
      IO.inspect(temperature_ranges_for_this_location)
      Enum.flat_map(temperature_ranges_for_this_location, fn {humidity_start, {temperature_start, range2}} ->
        IO.puts("humidity_start: " <> Integer.to_string(humidity_start))
        light_ranges_for_this_location =
          get_source_ranges_for_dest_range(temperature_start, range2, almanac.maps[{:light, :temperature}])

          IO.inspect("-----4----")
          IO.inspect(light_ranges_for_this_location)
          Enum.flat_map(light_ranges_for_this_location, fn {temperature_start, {light_start, range3}} ->
            IO.puts("temperature_start: " <> Integer.to_string(temperature_start))
            water_ranges_for_this_location =
              get_source_ranges_for_dest_range(light_start, range3, almanac.maps[{:water, :light}])


            IO.inspect("---5-------")
            IO.inspect(water_ranges_for_this_location)
            Enum.flat_map(water_ranges_for_this_location, fn {light_start, {water_start, range4}} ->
              IO.puts("light_start: " <> Integer.to_string(light_start))
              fertilizer_ranges_for_this_location =
                get_source_ranges_for_dest_range(water_start, range4, almanac.maps[{:fertilizer, :water}])

                IO.inspect("-----6-----")
                IO.inspect(fertilizer_ranges_for_this_location)
                Enum.flat_map(fertilizer_ranges_for_this_location, fn {water_start, {fertilizer_start, range5}} ->
                  IO.puts("water_start: " <> Integer.to_string(water_start))
                  soil_ranges_for_this_location =
                    get_source_ranges_for_dest_range(fertilizer_start, range5, almanac.maps[{:soil, :fertilizer}])

                  IO.inspect("-----7-----")
                  IO.inspect(soil_ranges_for_this_location)
                  Enum.flat_map(soil_ranges_for_this_location, fn {fertilizer_start, {soil_start, range6}} ->
                    IO.puts("fertilizer_start: " <> Integer.to_string(fertilizer_start))
                    seed_ranges_for_this_location =
                      get_source_ranges_for_dest_range(soil_start, range6, almanac.maps[{:seed, :soil}])
                    IO.inspect("-----8-----")
                    IO.inspect(seed_ranges_for_this_location)
                    %{:location_start => location_start, :range => range1, :seed_ranges_for_this_location => seed_ranges_for_this_location}
                  end)
                end)
            end)
          end)
      end)
    end)
    IO.inspect("==p..=.=")
    IO.inspect(rr)
    #   acc_init = %{
    #     :this_dest_start => location_start,
    #     :this_dest_count => range,

    #   }

    #   all_other_keys = Enum.filter(Almanac.keys, fn x -> x != location_key end)
    #   List.foldr(all_other_keys, acc_init, fn key, acc ->
    #     dest_start = acc[:this_dest_start]
    #     dest_count = acc[:this_dest_count]
    #     IO.inspect("============")
    #     IO.inspect(key)
    #     source_ranges = Enum.sort(almanac.maps[key])

    #     IO.inspect(source_ranges)
    #     uu = get_source_ranges_for_dest_range(dest_start, dest_count, source_ranges)
    #     IO.inspect(uu)
    #   end)
    #   []
    #     # acc ++ sorted_locations
    # end)
    # IO.inspect(rr)


  end

  def runP1 do
    case File.read("./lib/inputs/day5.txt") do
      {:ok, input} -> Almanac.parse(%{}, input)
      |> get_lowest_location
      |> IO.inspect

      {:error, reason} -> IO.write(reason)
    end
  end

  def runP2 do
    case File.read("./lib/inputs/day5.txt") do
      {:ok, input} -> Almanac.parse(%{}, input)
      |> lowest_locations_by_seed_value_ranges
      |> Enum.each(fn ar ->
        IO.inspect(ar)
      end)

      {:error, reason} -> IO.write(reason)
    end
  end
end
