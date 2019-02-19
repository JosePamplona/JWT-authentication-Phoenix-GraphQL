defmodule JayAuth.FunctionsLibrary do
  @moduledoc false

  alias Ecto.Changeset
  alias Comeonin.Pbkdf2

  #--- Changesets Functions ----------------------------------------------------

  def lowercase(changeset, field) do
    case changeset.valid? do
      true ->
        lowercase = 
          changeset
          |> Changeset.get_field(field)
          |> String.downcase
          |> String.trim
          
        Changeset.put_change(changeset, field, lowercase)

      false ->
        changeset
    end
  end

  def uppercase(changeset, field) do
    case changeset.valid? do
      true ->
        uppercase = 
          changeset
          |> Changeset.get_field(field)
          |> String.upcase
          |> String.trim

        Changeset.put_change(changeset, field, uppercase)

      false ->
        changeset
    end
  end

  def titlecase(changeset, field) do
    case changeset.valid? do
      true ->
        titlecased_name = 
          changeset
          |> Changeset.get_field(field)
          |> titlecase
          |> String.trim

        Changeset.put_change(changeset, field, titlecased_name)

      false ->
        changeset
    end
  end

  def hash(changeset, field) do
    field_hash = String.to_atom("#{Atom.to_string(field)}_hash")
    case changeset.valid? do
      true ->
        hashed = 
          changeset
          |> Changeset.get_field(field)
          |> Pbkdf2.hashpwsalt

        Changeset.put_change(changeset, field_hash, hashed)

      false ->
        changeset
    end
  end

  #--- General Functions -------------------------------------------------------

  #Coloca cada palabra en el string en minúsculas y su primer letra en mayúsculas
  def titlecase(string) do
    cond do
      !string -> nil
      true ->
        string
        |> String.downcase
        |> String.split
        |> Enum.map(fn(word) -> String.capitalize(word) end)
        |> Enum.join(" ")
    end
  end

  #--- Debugging Functions -----------------------------------------------------
  
  def o, do: IO.puts "\e[34m\e[1m-=== \e[0m\e[34mJayDebuging:\e[1m ================================================-\e[0m"
  def c, do: IO.puts "\e[34m\e[1m-=================================================================-\e[0m"

end
