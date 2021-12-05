defmodule GenReport.Parser do
  @moduledoc """
    Parse the given file
  """

  @separator ","

  @month {
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  }

  def parse_file(filename) do
    filename
    |> File.stream!()
    |> Stream.map(&sanitize/1)
    |> Stream.map(&tokenize/1)
    |> Enum.map(&convert_line/1)
  end

  defp sanitize(line), do: String.trim(line)

  defp convert_line([nome, qtd_horas, dia, mes, ano]) do
    nome = String.downcase(nome)
    qtd_horas = String.to_integer(qtd_horas)
    dia = String.to_integer(dia)
    mes = elem(@month, String.to_integer(mes) - 1)
    ano = String.to_integer(ano)

    [nome, qtd_horas, dia, mes, ano]
  end

  defp tokenize(line), do: String.split(line, @separator)
end
