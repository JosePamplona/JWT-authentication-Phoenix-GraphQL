defmodule JayAuth.Context do
  @behaviour Plug
 
  import Plug.Conn
  # import Ecto.Query, only: [where: 2]
 
  alias JayAuth.Accounts
  alias JayAuth.Guardian
 
  def init(opts), do: opts
 
  def call(conn, _) do
    case build_context(conn) do
      {:ok, context} ->
        put_private(conn, :absinthe, %{context: context})

      {:error, reason} ->
        put_private(conn, :absinthe, %{context: %{error: reason}})
      
      _ -> conn
    end
  end

  # ----------------------------------------------------------------------------
 
  defp build_context(conn) do
    with ["Bearer " <> access_jwt] <- get_req_header(conn, "authorization"),
         {:ok, user, token} <- authorize(access_jwt) do
      {:ok, %{user: user, token: token}}
    end
  end
 
  defp authorize(access_jwt) do
    case Guardian.decode_and_verify(access_jwt, %{typ: "access"}) do
      {:ok, claims} ->
        with {:ok, user} <- Guardian.resource_from_claims(claims) do
          token = Accounts.get_token(claims["tok"])
          cond do
            !token -> {:error, :token_not_found}
            token.type != "acc" -> {:error, :wrong_type}
            token.valid == false -> {:error, :token_not_valid}
            user.id != token.user_id -> {:error, :dont_belongs}
            true -> {:ok, user, token}
          end
        end

      {:error, :token_expired} ->
        with %{claims: %{"sub" => user_id}} <- Guardian.peek(access_jwt),
             {_amount, _result} <- Accounts.delete_user_expired_tokens(user_id) do
          {:error, :token_expired}
        end

      {:error, reason} -> {:error, reason}
    end
  end

  
end