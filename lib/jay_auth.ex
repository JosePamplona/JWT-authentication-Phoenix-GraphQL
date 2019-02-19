defmodule JayAuth do
  @moduledoc """
  JayAuth keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def ok() do
    string = "Mujer dxdad Jeranio"
    string = 
      string
      |> rule1
      |> rule2
    {:ok, string}
  end

  # Si termina en "dad" cambia a "dat" JEFF
  defp rule1(string) do
    string
    |> String.split(" ")
    |> Enum.map(fn(element) -> 
      element_length = String.length(element)

      element
      |> String.slice(element_length-3..element_length)
      |> case do
        "dad" -> 
          head_element = String.slice(element, 0..element_length-4)
          "#{head_element}dat"
        
        _ -> element
      end
    end)
    |> Enum.join(" ")
  end
  # La "x" y "j" cambian por "ʃ" (latin esh) siglo XV
  defp rule2(string) do
    string
    |> String.replace(["j"], "ʃ")
    #|> String.replace(["X", "J"], "Ʃ")
  end

end
