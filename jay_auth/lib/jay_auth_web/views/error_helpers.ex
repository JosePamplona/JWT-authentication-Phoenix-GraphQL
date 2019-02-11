defmodule JayAuthWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn (error) ->
      content_tag :span, translate_error(error), class: "help-block"
    end)
  end

  def error_changeset(changeset) do
    Enum.map(changeset.errors, fn {k, v} ->
       "#{Phoenix.Naming.humanize(k)} #{translate_error(v)}"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file.
    # Ecto will pass the :count keyword if the error message is
    # meant to be pluralized.
    # On your own code and templates, depending on whether you
    # need the message to be pluralized or not, this could be
    # written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #     dgettext "errors", "is invalid"
    #
    if count = opts[:count] do
      Gettext.dngettext(JayAuthWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(JayAuthWeb.Gettext, "errors", msg, opts)
    end
  end
  
  @doc """
  Recibe el resultado de un Ecto query o una transacción Multi. 
  Si la transacción fue exitosa regresa una tupla {:ok, result}. En caso de no
  ser exitosa regresará una tupla {:error, reason_string}.
  Los errores son formateados para su uso en ambiente de desarrollo, en producción
  deberá ser sustituido por un manejo de errores específicos para el usuario final.
  """
  def format_resolver_result(response, options \\ []) do
    multi_return = Keyword.get(options, :multi_return, nil)
    resolver = Keyword.get(options, :resolver, nil)

    cond do
      # Cuando la respuesta es de un query
      multi_return == nil ->
        case response do
          {:ok, result} -> {:ok, result}

          {:error, %{valid?: false} = changeset} ->
            error_string = error_changeset(changeset)

            case resolver do
              nil -> {:error, error_string}

              {function_name, _arity} -> 
                {:error, "#{function_name}: #{error_string}"}
            end

          {:error, other} -> {:error, "Error desconocido: #{inspect(other)}"}
        end
      # Cuando la respuesta es de un Multi
      true ->
        case response do
          {:ok, result} -> {:ok, Map.fetch!(result, multi_return)}

          {:error, multi_id, %{valid?: false} = changeset, _} ->
            error_string = error_changeset(changeset)

            case resolver do
              nil -> {:error, "@#{multi_id}: #{error_string}"}

              {function_name, _arity} -> 
                {:error, "#{function_name}@#{multi_id}: #{error_string}"}
            end
          
          {:error, other} -> {:error, "Error desconocido: #{inspect(other)}"}
        end
    end
  end

  @doc false
  def error_auth(reason) do
    error_string =
      case Mix.env do
        :dev ->
          case reason do
            # Estos errores son para debuggin, en producción regresar un único error
            "typ" -> "El tipo de JWT es incorrecto"
            :invalid_issuer -> "JWT issuer inválido"
            :token_expired -> "El JWT ya expiró"
            :invalid_token -> "JWT inválido"
            :user_not_found -> "No existe el usuario"
            :token_not_found -> "No existe el token en BD"
            :wrong_type -> "El tipo de token es incorrecto"
            :token_not_valid -> "El token ha sido invalidado"
            :dont_belongs -> "El token no está asignado al usuario"
            %{valid?: false} = changeset -> error_changeset(changeset)
            other -> "Error desconocido: #{inspect(other)}"
            # Otros errores posibles
            # {:error, %ArgumentError{message: "argument error: [\"dude\"]"}}
            # {:error, %CaseClauseError{term: {:error, {:badmatch, false}}}}
            # {:error, %Poison.SyntaxError{ message: "Unexpected end of input at position 155", pos: nil, token: nil}}
          end
        _ -> {:error, "No autorizado"}
      end
    {:error, "⛔ #{error_string}"}
  end
end
