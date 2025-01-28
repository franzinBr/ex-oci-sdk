defmodule ExOciSdk.Queue.QueueClient do
  @moduledoc """
  Client for interacting with OCI Queue Service messages and operations.

  This module handles message-level operations for OCI Queues, including:

  - Reading messages (`get_messages/3`)
  - Writing messages (`put_messages/4`)
  - Deleting messages (`delete_message/4`, `delete_messages/4`)
  - Updating messages (`update_message/5`, `update_messages/4`)
  - Retrieving queue stats (`get_stats/3`)
  - Listing channels (`list_channels/3`)

  For queue administration operations like creating, deleting, and updating queues,
  see `ExOciSdk.Queue.QueueAdminClient`.
  """

  alias ExOciSdk.{Client, Request, RequestBuilder}
  alias ExOciSdk.Queue.Types
  alias ExOciSdk.Response.Types, as: ResponseTypes

  defstruct [
    :client,
    :service_endpoint
  ]

  @typedoc """
  Queue client structure containing the base client and service configuration.

  * `:client` - The base OCI client instance, see `t:ExOciSdk.Client.t/0`
  * `:service_endpoint` - Optional custom service endpoint URL
  """
  @type t :: %__MODULE__{
          client: Client.t(),
          service_endpoint: String.t() | nil
        }

  @doc """
  Creates a new QueueClient instance.

  ## Parameters

    * `client` - Base sdk client, see `t:ExOciSdk.Client.t/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_create_opts/0`
  """
  @spec create(Client.t(), Types.queue_client_create_opts()) :: t()
  def create(%Client{} = client, opts \\ []) do
    %__MODULE__{
      client: client,
      service_endpoint: Keyword.get(opts, :service_endpoint, nil)
    }
  end

  @doc """
  Returns defaults service configuration settings `t:ExOciSdk.Queue.Types.service_settings/0`.
  """
  @spec service_settings() :: Types.service_settings()
  def service_settings do
    %{
      service_endpoint: "https://cell-1.queue.messaging.{region}.oci.oraclecloud.com/20210201",
      content_type: "application/json",
      accept: "application/json"
    }
  end

  @doc """
  Retrieves messages from a queue.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.get_messages_opts/0`

  ## Returns

    * `{:ok, response}` - On success, where response contains the messages
    * `{:error, reason}` - On failure

  """
  @spec get_messages(t(), Types.queue_id(), Types.get_messages_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def get_messages(%__MODULE__{} = queue_client, queue_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/queues/#{queue_id}/messages")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "visibilityInSeconds" => Keyword.get(opts, :visibility_in_seconds),
      "timeoutInSeconds" => Keyword.get(opts, :timeout_in_seconds),
      "limit" => Keyword.get(opts, :limit),
      "channelFilter" => Keyword.get(opts, :channel_filter)
    })
    |> Request.execute(queue_client.client)
  end

  @doc """
  Puts messages into a queue.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `put_messages_details` - Message details, see `t:ExOciSdk.Queue.Types.put_messages_details/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec put_messages(
          t(),
          Types.queue_id(),
          Types.put_messages_details(),
          Types.queue_client_default_opts()
        ) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def put_messages(%__MODULE__{} = queue_client, queue_id, put_messages_details, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:post, service_endpoint, "/queues/#{queue_id}/messages")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_body(put_messages_details)
    |> Request.execute(queue_client.client)
  end

  @doc """
  Retrieves statistics for a queue.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.get_stats_opts/0`

  ## Returns

    * `{:ok, response}` - On success, where response contains queue statistics
    * `{:error, reason}` - On failure
  """
  @spec get_stats(t(), Types.queue_id(), Types.get_stats_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def get_stats(%__MODULE__{} = queue_client, queue_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/queues/#{queue_id}/stats")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_query("channelId", Keyword.get(opts, :channel_id))
    |> Request.execute(queue_client.client)
  end

  @doc """
  Lists channels in a queue.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.list_channels_opts/0`


  ## Returns

    * `{:ok, response}` - On success, where response contains list of channels
    * `{:error, reason}` - On failure
  """
  @spec list_channels(t(), Types.queue_id(), Types.list_channels_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def list_channels(%__MODULE__{} = queue_client, queue_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/queues/#{queue_id}/channels")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "limit" => Keyword.get(opts, :limit),
      "page" => Keyword.get(opts, :page),
      "channelFilter" => Keyword.get(opts, :channel_filter)
    })
    |> Request.execute(queue_client.client)
  end

  @doc """
  Deletes a single message from a queue.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `message_receipt` - Receipt of the message to delete
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec delete_message(
          t(),
          Types.queue_id(),
          Types.message_receipt(),
          Types.queue_client_default_opts()
        ) :: {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def delete_message(%__MODULE__{} = queue_client, queue_id, message_receipt, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :delete,
      service_endpoint,
      "/queues/#{queue_id}/messages/#{message_receipt}"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> Request.execute(queue_client.client)
  end

  @doc """
  Deletes multiple messages from a queue in a single request.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `delete_messages_details` - Details of messages to delete, see `t:ExOciSdk.Queue.Types.delete_messages_details/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec delete_messages(
          t(),
          Types.queue_id(),
          Types.delete_messages_details(),
          Types.queue_client_default_opts()
        ) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def delete_messages(%__MODULE__{} = queue_client, queue_id, delete_messages_details, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :post,
      service_endpoint,
      "/queues/#{queue_id}/messages/actions/deleteMessages"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_body(delete_messages_details)
    |> Request.execute(queue_client.client)
  end

  @doc """
  Updates a single message's visibility timeout.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `message_receipt` - Receipt of the message to update
    * `update_message_details` - Update details, see `t:ExOciSdk.Queue.Types.update_message_details/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec update_message(
          t(),
          Types.queue_id(),
          Types.message_receipt(),
          Types.update_message_details(),
          Types.queue_client_default_opts()
        ) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def update_message(
        %__MODULE__{} = queue_client,
        queue_id,
        message_receipt,
        update_message_details,
        opts \\ []
      ) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :put,
      service_endpoint,
      "/queues/#{queue_id}/messages/#{message_receipt}"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_body(update_message_details)
    |> Request.execute(queue_client.client)
  end

  @doc """
  Updates visibility timeout for multiple messages in a single request.

  ## Parameters

    * `queue_client` - Queue client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `update_messages_details` - Update details, see `t:ExOciSdk.Queue.Types.update_messages_details/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_client_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec update_messages(
          t(),
          Types.queue_id(),
          Types.update_messages_details(),
          Types.queue_client_default_opts()
        ) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def update_messages(%__MODULE__{} = queue_client, queue_id, update_messages_details, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :post,
      service_endpoint,
      "/queues/#{queue_id}/messages/actions/updateMessages"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_body(update_messages_details)
    |> Request.execute(queue_client.client)
  end
end
