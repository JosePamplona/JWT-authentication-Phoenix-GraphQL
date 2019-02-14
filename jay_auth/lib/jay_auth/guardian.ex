defmodule JayAuth.Guardian do
  @moduledoc false
  
  use Guardian, otp_app: :jay_auth

  def subject_for_token(resource, _claims), do: {:ok, to_string(resource.id)}
  
  def resource_from_claims(%{"sub" => id}) do
    case JayAuth.Repo.get!(JayAuth.Accounts.User, id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end