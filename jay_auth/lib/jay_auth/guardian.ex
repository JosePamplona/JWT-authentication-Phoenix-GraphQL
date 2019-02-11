defmodule JayAuth.Guardian do
  use Guardian, otp_app: :jay_auth

  def subject_for_token(resource, _claims), do: {:ok, to_string(resource.id)}
  
  def resource_from_claims(%{"sub" => id}) do
    case JayAuth.Accounts.get_user!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end