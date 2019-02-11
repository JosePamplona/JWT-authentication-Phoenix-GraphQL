defmodule JayAuth.Accounts.Resolver do
  alias Ecto.Multi
  alias JayAuth.Accounts
  alias JayAuth.Accounts.User
  alias JayAuth.Repo
  alias JayAuthWeb.ErrorHelpers

  @doc false
  def get_user(_root, args, _info) do
    {:ok, Accounts.get_user!(args.id)}
  end

  @doc false
  def create_user(_root, args, _info) do
    Multi.new
    |> Multi.run(:user, fn(_changes) -> 
      Accounts.create_user(args) 
    end)
    |> Repo.transaction()
    |> ErrorHelpers.format_resolver_result(
      multi_return: :user, 
      resolver: __ENV__.function
    )
  end
  def create_user1(_root, args, _info) do
    Multi.new
    |> Multi.insert(:user, User.create_changeset(%User{}, args))
    |> Repo.transaction()
    |> ErrorHelpers.format_resolver_result(
      multi_return: :user, 
      resolver: __ENV__.function
    )
  end
  def create_user2(_root, args, _info) do
    args
    |> Accounts.create_user()
    |> ErrorHelpers.format_resolver_result(resolver: __ENV__.function)
  end

  @doc false
  def login(_root, args, _info) do
    with {:ok, user} <- Accounts.login_with_email_pass(args.email, args.pass),
         {:ok, acc_token} <- Accounts.create_token(%{user_id: user.id, type: "acc"}),
         {:ok, ref_token} <- Accounts.create_token(%{user_id: user.id, type: "ref"}),
         {:ok, acc_jwt, _} <- JayAuth.Guardian.encode_and_sign(user, %{tok: acc_token.id}, token_type: "access"),
         {:ok, ref_jwt, _} <- JayAuth.Guardian.encode_and_sign(user, %{tok: ref_token.id}, token_type: "refresh") do
      {:ok, %{user: user, access_jwt: acc_jwt, refresh_jwt: ref_jwt}}
    end
    |> case do
      {:ok, result} -> {:ok, result}
      # {:error, _} -> {:error, "No se pudo hacer login"}
      # Estos errores son para debuggin, en producción regresar un único error
      {:error, :incorrect_pass} -> {:error, "Password incorrecto"}
      {:error, :user_not_found} -> {:error, "No existe el usuario: #{args.email}"}
      {:error, %{valid?: false} = changeset} -> {:error, ErrorHelpers.error_changeset(changeset)}
      {:error, other} -> {:error, "Error desconocido: #{inspect(other)}"}
    end
  end

  @doc false
  def refresh(_root, args, _info) do
    case JayAuth.Guardian.decode_and_verify(args.refresh_jwt, %{typ: "refresh"}) do
      {:ok, %{"tok" => token_id}} ->
        with {:ok, user} <- Accounts.login_with_email_token(args.email, token_id),
             {:ok, _} <- Accounts.delete_token(token_id),
             {:ok, acc_token} <- Accounts.create_token(%{user_id: user.id, type: "acc"}),
             {:ok, ref_token} <- Accounts.create_token(%{user_id: user.id, type: "ref"}),
             {:ok, acc_jwt, _} <- JayAuth.Guardian.encode_and_sign(user, %{tok: acc_token.id}, token_type: "access"),
             {:ok, ref_jwt, _} <- JayAuth.Guardian.encode_and_sign(user, %{tok: ref_token.id}, token_type: "refresh") do
          {:ok, %{user: user, access_jwt: acc_jwt, refresh_jwt: ref_jwt}}
        end

      {:error, :token_expired} -> 
        %{claims: %{"tok" => token_id}} = JayAuth.Guardian.peek(args.refresh_jwt)
        Accounts.delete_token(token_id)
        {:error, :token_expired}

      {:error, reason} -> {:error, reason}
    end
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> ErrorHelpers.error_auth(reason)
    end
  end
  
  @doc false
  def logout(_, _, %{context: %{error: reason}}), do: ErrorHelpers.error_auth(reason)
  def logout(_root, _args, %{context: %{user: session_user, token: token}}) do
    token.id
    |> Accounts.delete_token()
    |> case do
      {:ok, _result} -> {:ok, session_user}
      {:error, %{valid?: false} = changeset} -> {:error, ErrorHelpers.error_changeset(changeset)}
      {:error, other} -> {:error, "Error desconocido: #{inspect(other)}"}
    end
  end

  @doc false
  def some_action(_, _, %{context: %{error: reason}}), do: ErrorHelpers.error_auth(reason)
  def some_action(_root, _args, %{context: %{user: session_user}}) do
    response =
      """
      All righty matey!!!  You are the user: #{session_user.email}

      #{inspect(Repo.preload(session_user, :tokens), pretty: true)}
      """
      IO.puts response
    {:ok, response}
  end

end