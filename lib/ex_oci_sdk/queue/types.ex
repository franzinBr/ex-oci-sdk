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
  A unique identifier for tracking asynchronous work requests. This ID is returned when operations that change state are initiated
  and can be used to monitor the status and progress of long-running operations through work request APIs.
  """
  @type work_request_id :: String.t()

  @typedoc """
  The OCID (Oracle Cloud ID) that uniquely identifies a compartment.
  A compartment is a logical container used to organize and isolate cloud resources.
  """
  @type compartment_id :: String.t()

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
  @type queue_default_opts :: [
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
  Options for listing queues.

  * `:opc_request_id` - Custom request identifier
  * `:id` - Unique identifier of the queue to filter by
  * `:display_mame` - Name of the queue to filter results
  * `:compartment_id` - OCID of the compartment to filter queues
  * `:lifecycle_state` - Current state of the queue (e.g. CREATING, UPDATING, ACTIVE, DELETING, DELETED and FAILED)
  * `:limit` - Maximum number of queues to retrieve
  * `:page` - Page number for pagination
  * `:sort_order` - Order of results (ASC or DESC)
  * `:sort_by` - Field to sort the results by (e.g. timeCreated, displayName)
  """
  @type list_queues_opts :: [
          opc_request_id: opc_request_id(),
          id: String.t(),
          display_name: String.t(),
          compartment_id: compartment_id(),
          lifecycle_state: String.t(),
          limit: pos_integer(),
          page: pos_integer(),
          sort_order: String.t(),
          sort_by: String.t()
        ]

  @typedoc """
  Default options for create a queue

  * `:opc_request_id` - Custom request identifier for tracing
  * `:opc_retry_token` - A token that uniquely identifies a request. If you need to retry the request, use the same retry token. This ensures that the server recognizes the request as a retry and not as a new request

  """
  @type create_queue_opts :: [
          opc_request_id: opc_request_id(),
          opc_retry_token: String.t()
        ]

  @typedoc """
  Default options available for operations that change state of a queue (delete, move, purge).

  * `:opc_request_id` - Custom request identifier for tracing
  * `:if_match` - Used for optimistic concurrency control. Ensures the resource hasn't been modified since you last retrieved it.
    Contains the resource's ETag value from a previous GET request.
    If the ETag values don't match, the operation will fail with a 412 Precondition Failed error
  """
  @type queue_admin_default_opts :: [
          opc_request_id: opc_request_id(),
          if_match: String.t()
        ]

  @typedoc """
  Options for listing work requests.

  * `:opc_request_id` - Custom request identifier for tracing
  * `:compartment_id` - OCID of the compartment to filter work requests
  * `:work_request_id` - Filter work requests by their unique identifier
  * `:limit` - Maximum number of work requests to retrieve per page
  * `:page` - Page number for pagination when retrieving a list of work requests
  """
  @type list_work_requests_opts :: [
          opc_request_id: opc_request_id(),
          compartment_id: compartment_id(),
          work_request_id: work_request_id(),
          limit: pos_integer(),
          page: pos_integer()
        ]

  @typedoc """
  Options for listing work requests.

  * `:opc_request_id` - Custom request identifier for tracing
  * `:limit` - Maximum number of work requests to retrieve per page
  * `:page` - Page number for pagination when retrieving a list of work requests
  """
  @type list_work_requests_default_opts :: [
          opc_request_id: opc_request_id(),
          limit: pos_integer(),
          page: pos_integer()
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

  @typedoc """
  Map structure for creating a queue

  * `display_name` - The name of the queue displayed in the console
  * `compartment_id` - The OCID of the compartment where the queue will be created
  * `retention_in_seconds` - How long messages are kept in the queue before automatic deletion
  * `visibility_in_seconds` - How long a message is invisible to other consumers after being retrieved
  * `timeout_in_seconds` - Maximum time allowed for processing a message before it returns to the queue
  * `channel_consumption_limit` - Maximum number of messages that can be consumed simultaneously
  * `dead_letter_queue_delivery_count` - Number of delivery attempts before moving to dead letter queue
  * `custom_encryption_key_id` - The OCID of the custom encryption key
  * `freeform_tags` - Simple key-value pairs for organizing resources
  * `defined_tags` - Predefined tags that restrict values by a definite schema
  """
  @type create_queue_input :: %{
          display_name: String.t(),
          compartment_id: compartment_id(),
          retention_in_seconds: pos_integer(),
          visibility_in_seconds: pos_integer(),
          timeout_in_seconds: pos_integer(),
          channel_consumption_limit: pos_integer(),
          dead_letter_queue_delivery_count: pos_integer(),
          custom_encryption_key_id: String.t(),
          freeform_tags: %{String.t() => String.t()},
          defined_tags: %{String.t() => %{String.t() => term()}}
        }

  @typedoc """
  Map structure for purging a queue.

  * `purge_type` - Type of purge operation. Valid values are "NORMAL", "DLQ", or "BOTH"
  * `channel_ids` - List of channel IDs to be purged (optional)
  """
  @type purge_queue_input :: %{
          required(:purge_type) => String.t(),
          optional(:channel_ids) => [String.t()]
        }

  @typedoc """
  Map structure for updating a queue.

  * `display_name` - The name of the queue displayed in the console
  * `visibility_in_seconds` - How long a message is invisible to other consumers after being retrieved
  * `timeout_in_seconds` - Maximum time allowed for processing a message before it returns to the queue
  * `channel_consumption_limit` - Maximum number of messages that can be consumed simultaneously
  * `dead_letter_queue_delivery_count` - Number of delivery attempts before moving to dead letter queue
  * `custom_encryption_key_id` - The OCID of the custom encryption key
  * `freeform_tags` - Simple key-value pairs for organizing resources
  * `defined_tags` - Predefined tags that restrict values by a definite schema
  """
  @type update_queue_input :: %{
          display_name: String.t(),
          visibility_in_seconds: pos_integer(),
          timeout_in_seconds: pos_integer(),
          channel_consumption_limit: pos_integer(),
          dead_letter_queue_delivery_count: pos_integer(),
          custom_encryption_key_id: String.t(),
          freeform_tags: %{String.t() => String.t()},
          defined_tags: %{String.t() => %{String.t() => term()}}
        }

  @typedoc """
  Map structure for changing a queue's compartment.

  * `compartment_id` - The OCID of the destination compartment. After the change operation completes,
  """
  @type change_queue_compartment_input :: %{
          compartment_id: compartment_id()
        }
end
