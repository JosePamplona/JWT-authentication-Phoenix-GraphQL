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

  def token_ttl(type) do
    {amount, unit} = Application.get_env(:jay_auth, JayAuth.Guardian)[:token_ttl][type]
    cond do
      unit == :second || unit == :seconds -> amount
      unit == :minute || unit == :minutes -> amount * 60
      unit == :hour || unit == :hours -> amount * 3600
      unit == :day || unit == :days -> amount * 86_400
      unit == :week || unit == :weeks -> amount * 604_800
    end
  end
end