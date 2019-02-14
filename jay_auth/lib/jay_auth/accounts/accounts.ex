defmodule JayAuth.Accounts do
  @moduledoc false
  
  import Ecto.Query, warn: false
  
  alias JayAuth.Repo
  alias JayAuth.Accounts.User # ------------------------------------------------

  def list_users, do: Repo.all(User)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  def login_with_email_pass(email, pass) do
    user = Repo.get_by(User, email: String.downcase(email))

    cond do
      user && Comeonin.Pbkdf2.checkpw(pass, user.pass_hash) -> {:ok, user}
      user -> {:error, :incorrect_pass}
      true -> {:error, :user_not_found}
    end
  end

  alias JayAuth.Accounts.Token # -----------------------------------------------

  def get_token(id), do: Repo.get(Token, id)

  def create_token(attrs \\ %{}) do
    %Token{}
    |> Token.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_token(id) do
    case Repo.get(Token, id) do
      nil -> {:error, :token_not_found}
      token -> Repo.delete(token)
    end
  end

  def login_with_email_token(email, token_id) do
    user = Repo.get_by(User, email: String.downcase(email))
    token = Repo.get(Token, token_id)

    cond do
      !user -> {:error, :user_not_found}
      !token -> {:error, :token_not_found}
      token.type != "ref" -> {:error, :wrong_type}
      token.valid == false -> {:error, :token_not_valid}
      user.id == token.user_id -> {:ok, user}
      true -> {:error, :dont_belongs}
    end
  end
end