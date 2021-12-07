defmodule GenReport do
  alias GenReport.Parser

  @initial_report %{
    "all_hours" => %{},
    "hours_per_month" => %{},
    "hours_per_year" => %{}
  }

  def build, do: {:error, "Insira o nome de um arquivo"}

  def build(filename) when is_binary(filename), do: build([filename])

  def build(filenames) do
    filenames
    |> Task.async_stream(fn filename ->
      filename
      |> Parser.parse_file()
      |> calculate_hours()
    end)
    |> Enum.reduce(@initial_report, fn {:ok, elem}, acc -> merge_report(acc, elem) end)
  end

  defp merge_report(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    %{
      "all_hours" => sum_values_from_map(all_hours1, all_hours2),
      "hours_per_month" => merge_map(hours_per_month1, hours_per_month2),
      "hours_per_year" => merge_map(hours_per_year1, hours_per_year2)
    }
  end

  defp merge_map(map1, map2) do
    case Map.values(map2) do
      [head | _tail] when is_map(head) ->
        keys = Map.keys(map1) ++ Map.keys(map2)
        keys = Enum.uniq(keys)

        for key <- keys, into: %{} do
          {key, merge_map(Map.get(map1, key, %{}), Map.get(map2, key, %{}))}
        end
      [_head | _tail] -> sum_values_from_map(map1, map2)
    end
  end

  defp sum_values_from_map(map1, map2) do
    keys = Map.keys(map1) ++ Map.keys(map2)
    keys = Enum.uniq(keys)

    for key <- keys, into: %{} do
      {key, Map.get(map1, key, 0) + Map.get(map2, key, 0)}
    end
  end

  defp calculate_hours(data) do
    data
    |> Enum.reduce(@initial_report, fn elem, acc -> update_report(acc, elem) end)
  end

  defp update_report(
         %{
           "all_hours" => all_hours,
           "hours_per_month" => hours_per_month,
           "hours_per_year" => hours_per_year
         },
         [nome, horas, _dia, mes, ano]
       ) do
    all_hours = calculate_all_hours(all_hours, nome, horas)
    hours_per_month = calculate_hours_per_month(hours_per_month, nome, horas, mes)
    hours_per_year = calculate_hours_per_year(hours_per_year, nome, horas, ano)

    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end

  defp calculate_all_hours(all_hours, nome, horas) do
    result = Map.get(all_hours, nome, 0) + horas

    Map.put(all_hours, nome, result)
  end

  defp calculate_hours_per_month(hours_per_month, nome, horas, mes) do
    hours_of_person = Map.get(hours_per_month, nome, %{})
    result = Map.get(hours_of_person, mes, 0) + horas

    hours_of_person = Map.put(hours_of_person, mes, result)

    Map.put(hours_per_month, nome, hours_of_person)
  end

  defp calculate_hours_per_year(hours_per_year, nome, horas, ano) do
    hours_of_person = Map.get(hours_per_year, nome, %{})
    result = Map.get(hours_of_person, ano, 0) + horas

    hours_of_person = Map.put(hours_of_person, ano, result)

    Map.put(hours_per_year, nome, hours_of_person)
  end
end
