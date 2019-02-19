defmodule JayAuth.Accounts.Graphql.Resolver do
  @moduledoc false
  
  alias Ecto.Multi
  alias JayAuth.Accounts
  alias JayAuth.Accounts.User
  alias JayAuth.Guardian
  alias JayAuth.Repo
  alias JayAuthWeb.ErrorHelpers

  @doc false
  def list_users(_root, _args, _info), do: {:ok, Accounts.list_users}

  @doc false
  def create_user(_root, args, _info) do
    Multi.new
    |> Multi.run(:user, fn(_changes) ->
      Accounts.create_user(args)
    end)
    |> Repo.transaction()
    |> ErrorHelpers.format_resolver_result(
      multi_return: :user,
      fn: __ENV__.function
    )
  end
  def create_user1(_root, args, _info) do
    Multi.new
    |> Multi.insert(:user, User.create_changeset(%User{}, args))
    |> Repo.transaction()
    |> ErrorHelpers.format_resolver_result(
      multi_return: :user, 
      fn: __ENV__.function
    )
  end
  def create_user2(_root, args, _info) do
    args
    |> Accounts.create_user()
    |> ErrorHelpers.format_resolver_result(fn: __ENV__.function)
  end

  @doc false
  def login(_root, args, _info) do
    with {:ok, user} <- Accounts.login_with_email_pass(args.email, args.pass),
         {:ok, acc_token} <- Accounts.create_token(%{user_id: user.id, type: "acc"}),
         {:ok, ref_token} <- Accounts.create_token(%{user_id: user.id, type: "ref"}),
         {:ok, acc_jwt, _} <- Guardian.encode_and_sign(user, %{tok: acc_token.id}, token_type: "access"),
         {:ok, ref_jwt, _} <- Guardian.encode_and_sign(user, %{tok: ref_token.id}, token_type: "refresh") do
      {:ok, %{user: user, access_jwt: acc_jwt, refresh_jwt: ref_jwt}}
    end
    |> ErrorHelpers.format_resolver_result(
      errors: [
        {:incorrect_pass, "Password incorrecto"},
        {:user_not_found, "No existe el usuario: #{args.email}"}
      ],
      fn: __ENV__.function
    )
  end

  @doc false
  def refresh(_root, args, _info) do
    case Guardian.decode_and_verify(args.refresh_jwt, %{typ: "refresh"}) do
      {:ok, %{"tok" => token_id}} ->
        with {:ok, user} <- Accounts.login_with_email_token(args.email, token_id),
             {:ok, _} <- Accounts.delete_token(token_id),
             {:ok, acc_token} <- Accounts.create_token(%{user_id: user.id, type: "acc"}),
             {:ok, ref_token} <- Accounts.create_token(%{user_id: user.id, type: "ref"}),
             {:ok, acc_jwt, _} <- Guardian.encode_and_sign(user, %{tok: acc_token.id}, token_type: "access"),
             {:ok, ref_jwt, _} <- Guardian.encode_and_sign(user, %{tok: ref_token.id}, token_type: "refresh") do
          {:ok, %{user: user, access_jwt: acc_jwt, refresh_jwt: ref_jwt}}
        end

      {:error, :token_expired} -> 
        with %{claims: %{"sub" => user_id}} <- Guardian.peek(args.refresh_jwt),
             {_amount, _result} <- Accounts.delete_user_expired_tokens(user_id) do
          {:error, :token_expired}
        end

      {:error, reason} -> {:error, reason}
    end
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> ErrorHelpers.error_auth(reason, fn: __ENV__.function)
    end
  end
  
  @doc false
  def logout(_root, _args, %{context: %{user: session_user, token: token}}) do
    token.id
    |> Accounts.delete_token()
    |> ErrorHelpers.format_resolver_result(
      return_replacement: session_user,
      fn: __ENV__.function
    )
  end
  def logout(_root, _args, %{context: %{error: reason}}),
    do: ErrorHelpers.error_auth(reason, fn: __ENV__.function)
  def logout(_root, _args, _info),
    do: ErrorHelpers.error_request_header(fn: __ENV__.function)

  @doc false
  def some_action(_root, _args, %{context: %{user: session_user}}) do
    user = Repo.preload(session_user, :tokens)
    tokens = 
      user.tokens
      |> Enum.with_index
      |> Enum.map(fn({e, i}) ->
        type =
          case e.type do
            "acc" -> "access"
            "ref" -> "refresh"
          end
        ttl =
          e.inserted_at
          |> NaiveDateTime.add(JayAuth.Guardian.token_ttl(type), :second)
          |> NaiveDateTime.diff(NaiveDateTime.utc_now)
          |> case do
            secs when secs < 0 -> "\e[31m\e[1mexpired\e[33m\e[1m"
            secs -> "#{secs} sec"
          end
        case i do
          0 -> "#{(i+1)}: [#{e.type}] #{e.id} (TTL: #{ttl})"
          _ -> "        #{(i+1)}: [#{e.type}] #{e.id} (TTL: #{ttl})"
        end
      end)
      |> Enum.join("\n")
    response =
      """
      \n\n\e[34m\e[1mAll righty matey!!!\e[0m
      You are the user: \e[33m\e[1m#{session_user.email}\e[0m
      Tokens: \e[33m\e[1m#{tokens}\e[0m
      """
      IO.puts response
    {:ok, user}
  end
  def some_action(_root, _args, %{context: %{error: reason}}), 
    do: ErrorHelpers.error_auth(reason, fn: __ENV__.function)
  def some_action(_root, _args, _info),
    do: ErrorHelpers.error_request_header(fn: __ENV__.function)

end