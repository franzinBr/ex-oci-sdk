defmodule ExOciSdk.ResponsePolicy do
  @moduledoc false
  # Defines policies for handling HTTP responses

  defstruct status_codes_success: 200..299

  @type t :: %__MODULE__{
          status_codes_success: list(integer()) | Range.t()
        }
end
