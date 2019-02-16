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
    |> Enum.join(". ")
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
  Si la transacción fue exitosa regresa una tupla {:ok, result}. 
  En caso de no ser exitosa regresará una tupla {:error, reason}.
  Los errores son formateados para su uso en ambiente de 
  desarrollo, en producción deberá ser sustituido por un manejo 
  de errores específicos para el usuario final.
  """
  def format_resolver_result(response, options \\ []) do
    multi = Keyword.get(options, :multi, false)
    errors = Keyword.get(options, :errors, [])
    function = Keyword.get(options, :fn, nil)
    multi_return = Keyword.get(options, :multi_return, nil)
    return_replacement = Keyword.get(options, :return_replacement, nil)
    
    multi = if multi_return, do: true, else: multi
    errors =
      Enum.map(errors, fn(e) -> 
        case e do
          {error, string, type} -> {error, string, type}
          {error, string} -> {error, string, :error}
        end
      end)
    unknown_error_prefix = "Error desconocido: "

    case multi do
      true -> # Cuando la respuesta es de una estrucura Multi
        case response do
          {:ok, result} -> 
            multi_return = 
              if !multi_return, 
                do: Enum.at(Map.keys(result), -1),
                else: multi_return
            case return_replacement do
              nil -> {:ok, Map.fetch!(result, multi_return)}
              _ -> {:ok, return_replacement}
            end

          {:error, multi_id, %{valid?: false} = changeset, _} ->
            format_error(
              error_changeset(changeset),
              fn: function, 
              multi_id: multi_id,
              type: :error
            )
          
          {:error, multi_id, other, _} -> 
            default = {other, "#{unknown_error_prefix}#{inspect(other)}", :unknown}
            {_error, string, type} =
              Enum.find(errors, default, fn({error, _string, _type}) -> 
                case other do
                  ^error -> true
                  _ -> false
                end
              end)

            format_error(string, fn: function, multi_id: multi_id, type: type)
        end
      
      false -> # Cuando la respuesta es de un simple query
        case response do
          {:ok, result} ->
            case return_replacement do
              nil -> {:ok, result}
              _ -> {:ok, return_replacement}
            end

          {:error, %{valid?: false} = changeset} ->
            format_error(error_changeset(changeset), fn: function, type: :error)

          {:error, other} ->
            default = {other, "#{unknown_error_prefix}#{inspect(other)}", :unknown}
            {_error, string, type} =
              Enum.find(errors, default, fn({error, _string, _type}) -> 
                case other do
                  ^error -> true
                  _ -> false
                end
              end)

            format_error(string, fn: function, type: type)
        end
    end
  end

  @doc false
  def error_auth(reason, options \\ []) do
    function = Keyword.get(options, :fn, nil)

    error_string =
      case Mix.env do
        :dev ->
          case reason do
            # Estos errores son para debuggin, en producción regresar un único error
            "typ" -> "El tipo de JWT es incorrecto"
            :invalid_issuer -> "El issuer de JWT es inválido"
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
            # %ArgumentError{message: "argument error: [\"dude\"]"}}
            # %CaseClauseError{term: {:error, {:badmatch, false}}}}
            # %MatchError{term: false}
            # %Poison.SyntaxError{message: "Unexpected end of input at position 155", pos: nil, token: nil}}
          end
        _ -> "No autorizado"
      end

    format_error(error_string, fn: function, type: :no_auth)
  end

  @doc false
  def error_request_header(options \\ []) do
    function = Keyword.get(options, :fn, nil)

    format_error(
      "Falta el header de autorización", 
      fn: function, 
      type: :no_header
    )
  end

  # ----------------------------------------------------------------------------

  defp format_error(error_string, options) do
    multi_id = Keyword.get(options, :multi_id, nil)
    function = Keyword.get(options, :fn, nil)
    type = Keyword.get(options, :type, nil)

    prefix =
      case type do
        :error -> "❌ "
        :no_auth -> "⛔ "
        :no_header -> "🔑 "
        :unknown -> "❓ "
        _ -> ""
      end

    case multi_id do
      nil ->
        case function do
          {function_name, _arity} -> 
            {:error, "#{prefix}[#{function_name}]: #{error_string}"}
          _ -> 
            {:error, "#{prefix}#{error_string}"}
        end

      _ ->
        case function do
          {function_name, _arity} -> 
            {:error, "#{prefix}[#{function_name}@#{multi_id}]: #{error_string}"}
          _ -> 
            {:error, "#{prefix}[@#{multi_id}]: #{error_string}"}
        end
    end
  end
end
