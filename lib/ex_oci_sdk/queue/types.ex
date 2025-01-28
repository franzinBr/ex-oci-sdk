defmodule ExOciSdk.Queue.Types do
  @moduledoc """
  Defines types used by the Queue Client.
  """

  @typedoc """
  Unique identifier for a queue.
  """
  @type queue_id :: String.t()

  @typedoc """
  Receipt identifier for a message. Used in operations that manipulate existing messages.
  """
  @type message_receipt :: String.t()

  @typedoc """
  Request identifier used for tracing and debugging purposes.
  """
  @type opc_request_id :: String.t()

  @typedoc """
  Unique identifier for a channel within a queue.
  """
  @type channel_id :: String.t()

  @typedoc """
  Filter string for querying specific channels.
  """
  @type channel_filter :: String.t()

  @typedoc """
  Default Queue service settings

  * `:service_endpoint` - Default OCI service endpoint
  * `:content_type` - Default content type for requests
  * `:accept` - Default accept header for requests
  """
  @type service_settings :: %{
          service_endpoint: String.t(),
          content_type: String.t(),
          accept: String.t()
        }

  @typedoc """
  Message map containing the actual content and associated metadata.
  """
  @type message :: %{
          content: String.t(),
          metadata: message_metadata()
        }

  @typedoc """
  Metadata map associated with a message, including channel information and custom properties.
  """
  @type message_metadata :: %{
          channel_id: channel_id(),
          custom_properties: %{String.t() => String.t()}
        }

  @typedoc """
  Options for creating a new queue client.

  * `:service_endpoint` - Custom service endpoint URL
  """
  @type queue_client_create_opts :: [
          service_endpoint: String.t()
        ]

  @typedoc """
  Default options available for most queue operations.

  * `:opc_request_id` - Custom request identifier for tracing
  """
  @type queue_client_default_opts :: [
          opc_request_id: opc_request_id()
        ]

  @typedoc """
  Options for retrieving messages from a queue.

  * `:opc_request_id` - Custom request identifier
  * `:visibility_in_seconds` - Duration the message remains invisible to other consumers
  * `:timeout_in_seconds` - How long to wait for messages if queue is empty
  * `:limit` - Maximum number of messages to retrieve
  * `:channel_filter` - Filter for specific channels
  """
  @type get_messages_opts :: [
          opc_request_id: opc_request_id(),
          visibility_in_seconds: pos_integer(),
          timeout_in_seconds: pos_integer(),
          limit: pos_integer(),
          channel_filter: channel_filter()
        ]

  @typedoc """
  Options for retrieving queue statistics.

  * `:opc_request_id` - Custom request identifier
  * `:channel_filter` - Filter for specific channels
  """
  @type get_stats_opts :: [
          opc_request_id: opc_request_id(),
          channel_filter: channel_filter()
        ]

  @typedoc """
  Options for listing channels in a queue.

  * `:opc_request_id` - Custom request identifier
  * `:limit` - Maximum number of channels to retrieve
  * `:page` - Page number for pagination
  * `:channel_filter` - Filter for specific channels
  """
  @type list_channels_opts :: [
          opc_request_id: opc_request_id(),
          limit: pos_integer(),
          page: pos_integer(),
          channel_filter: channel_filter()
        ]

  @typedoc """
  Map for putting multiple messages into a queue.
  """
  @type put_messages_input :: %{
          messages: [message()]
        }

  @typedoc """
  Structure for deleting multiple messages from a queue.
  """
  @type delete_messages_input :: %{
          entries: [
            %{
              receipt: message_receipt()
            }
          ]
        }

  @typedoc """
  Map for updating a single message's visibility timeout.
  """
  @type update_message_input :: %{
          visibility_in_seconds: pos_integer()
        }

  @typedoc """
  Structure for updating visibility timeout for multiple messages.
  """
  @type update_messages_input :: %{
          entries: [
            %{
              receipt: message_receipt(),
              visibility_in_seconds: pos_integer()
            }
          ]
        }
end
