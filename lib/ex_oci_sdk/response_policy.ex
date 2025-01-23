defmodule ExOciSdk.ResponsePolicy do
  @moduledoc """
  Defines policies for handling HTTP responses
  """
  defstruct status_codes_success: [200]

  @type t :: %__MODULE__{
          status_codes_success: [integer()]
        }
end
