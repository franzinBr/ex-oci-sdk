# Copyright 2025 Alan Franzin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule ExOciSdk.Queue.QueueAdminClient do
  @moduledoc """
  Provides administrative operations for managing OCI Queues.

  This module implements the Oracle Cloud Infrastructure (OCI) Queue Admin,
  offering functionality to create, configure, and manage queues in OCI. It handles
  both synchronous operations (like retrieving queue details) and asynchronous
  operations (like queue creation and deletion) through work requests.

  ## Queue Management

  The client supports comprehensive queue lifecycle management:
    * Queue creation with configurable retention, visibility, and timeout settings (`create_queue/3`)
    * Queue retrieval and listing operations (`get_queue/3`, `list_queues/2`)
    * Queue updates for modifying existing configurations (`update_queue/4`)
    * Queue deletion with proper cleanup (`delete_queue/3`)
    * Queue purging to remove messages (`purge_queue/4`)
    * Moving queues between compartments (`change_queue_compartment/4`)

  ## Work Request Tracking

  Many operations in this module are asynchronous and return a work request ID.
  These operations include:
    * Creating queues (`create_queue/3`)
    * Deleting queues (`delete_queue/3`)
    * Purging messages (`purge_queue/4`)
    * Updating queue configurations (`update_queue/4`)
    * Moving queues between compartments (`change_queue_compartment/4`)

  The module provides functions to track and monitor these asynchronous operations:
    * `get_work_request/3` - Check operation status
    * `list_work_requests/2` - List all work requests in a compartment
    * `list_work_request_errors/3` - View operation errors
    * `list_work_request_logs/3` - Access detailed operation logs
  """

  alias ExOciSdk.ResponsePolicy
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
      service_endpoint: "https://messaging.{region}.oci.oraclecloud.com/20210201",
      content_type: "application/json",
      accept: "application/json"
    }
  end

  @doc """
  Retrieves details about a specific queue.

  Returns information about the queue including its configuration, state, and metadata.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec get_queue(t(), Types.queue_id(), Types.queue_default_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def get_queue(%__MODULE__{} = queue_admin_client, queue_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/queues/#{queue_id}")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Lists queues based on the provided filters.

  Returns a paginated list of queues that match the specified criteria. The response
  can be sorted and filtered by various queue attributes.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.list_queues_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec list_queues(t(), Types.list_queues_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def list_queues(%__MODULE__{} = queue_admin_client, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/queues")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "id" => Keyword.get(opts, :id),
      "displayName" => Keyword.get(opts, :display_name),
      "compartmentId" => Keyword.get(opts, :compartment_id),
      "lifecycleState" => Keyword.get(opts, :lifecycle_state),
      "limit" => Keyword.get(opts, :limit),
      "page" => Keyword.get(opts, :page),
      "sortOrder" => Keyword.get(opts, :sort_order),
      "sortBy" => Keyword.get(opts, :sort_by)
    })
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-next-page")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Creates a new queue with the specified configuration.

  Initiates an asynchronous operation to create a new queue in the specified compartment.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `create_queue_input` - Create queue input, see `t:ExOciSdk.Queue.Types.create_queue_input/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.create_queue_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec create_queue(t(), Types.create_queue_input(), Types.create_queue_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def create_queue(%__MODULE__{} = queue_admin_client, create_queue_input, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :post,
      service_endpoint,
      "/queues"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id),
      "opc-retry-token" => Keyword.get(opts, :opc_retry_token)
    })
    |> RequestBuilder.with_body(create_queue_input)
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-work-request-id")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Deletes a specified queue.

  Initiates an asynchronous operation to delete a queue and all its messages.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_admin_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec delete_queue(t(), Types.queue_id(), Types.queue_admin_default_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def delete_queue(%__MODULE__{} = queue_admin_client, queue_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :delete,
      service_endpoint,
      "/queues/#{queue_id}"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id),
      "if-match" => Keyword.get(opts, :if_match)
    })
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-work-request-id")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Purges messages from a queue based on the specified criteria.

  Initiates an asynchronous operation to remove messages from either the main queue,
  dead letter queue (DLQ), or both. Can optionally target specific channels.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier,
    * `purge_queue_input` - Purge queue input, see `t:ExOciSdk.Queue.Types.purge_queue_input/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_admin_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec purge_queue(
          t(),
          Types.queue_id(),
          Types.purge_queue_input(),
          Types.queue_admin_default_opts()
        ) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def purge_queue(%__MODULE__{} = queue_admin_client, queue_id, purge_queue_input, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :post,
      service_endpoint,
      "/queues/#{queue_id}/actions/purge"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id),
      "if-match" => Keyword.get(opts, :if_match)
    })
    |> RequestBuilder.with_body(purge_queue_input)
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-work-request-id")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Updates a queue's configuration.

  Initiates an asynchronous operation to modify the configuration of an existing queue.

  ## Parameters
    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier,
    * `update_queue_input` - Update queue input, see `t:ExOciSdk.Queue.Types.update_queue_input/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_admin_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec update_queue(
          t(),
          Types.queue_id(),
          Types.update_queue_input(),
          Types.queue_admin_default_opts()
        ) :: {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def update_queue(%__MODULE__{} = queue_admin_client, queue_id, update_queue_input, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :put,
      service_endpoint,
      "/queues/#{queue_id}"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id),
      "if-match" => Keyword.get(opts, :if_match)
    })
    |> RequestBuilder.with_body(update_queue_input)
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-work-request-id")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Moves a queue to a different compartment.

  Initiates an asynchronous operation to change the compartment of an existing queue.

  ## Parameters
    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `queue_id` - Target queue identifier,
    * `change_queue_compartment_input` - Change queue compartment input, see `t:ExOciSdk.Queue.Types.change_queue_compartment_input/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_admin_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success
    * `{:error, reason}` - On failure
  """
  @spec change_queue_compartment(
          t(),
          Types.queue_id(),
          Types.change_queue_compartment_input(),
          Types.queue_admin_default_opts()
        ) :: {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def change_queue_compartment(
        %__MODULE__{} = queue_admin_client,
        queue_id,
        change_queue_compartment_input,
        opts \\ []
      ) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :post,
      service_endpoint,
      "/queues/#{queue_id}/actions/changeCompartment"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id),
      "if-match" => Keyword.get(opts, :if_match)
    })
    |> RequestBuilder.with_body(change_queue_compartment_input)
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-work-request-id")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Retrieves the current status of an asynchronous queue operation.

  This function polls the status of operations like:
    `create_queue/3`,
    `delete_queue/3`,
    `purge_queue/4`,
    `update_queue/4`,
    `change_queue_compartment/4`
  that are being processed asynchronously in the queue service.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `work_request_id` - ID of the asynchronous operation.
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.queue_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success, returns status details
    * `{:error, reason}` - On failure
  """
  @spec get_work_request(t(), Types.work_request_id(), Types.queue_default_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def get_work_request(%__MODULE__{} = queue_admin_client, work_request_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(
      :get,
      service_endpoint,
      "/workRequests/#{work_request_id}"
    )
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Lists work requests in a compartment.

  Retrieves a paginated list of work requests for queue operations.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.list_work_requests_opts/0`

  ## Returns

    * `{:ok, response}` - On success, returns status details
    * `{:error, reason}` - On failure
  """
  @spec list_work_requests(t(), Types.list_work_requests_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def list_work_requests(%__MODULE__{} = queue_admin_client, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/workRequests")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "compartmentId" => Keyword.get(opts, :compartment_id),
      "workRequestId" => Keyword.get(opts, :work_request_id),
      "limit" => Keyword.get(opts, :limit),
      "page" => Keyword.get(opts, :page)
    })
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-next-page")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Lists errors associated with a work request.

  Retrieves a paginated list of errors that occurred during the execution of a
  specific work request. This helps diagnose failures in queue operations.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `work_request_id` - ID of the work request to get errors for
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.list_work_requests_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success, returns status details
    * `{:error, reason}` - On failure
  """
  @spec list_work_request_errors(t(), Types.list_work_requests_default_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def list_work_request_errors(%__MODULE__{} = queue_admin_client, work_request_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/workRequests/#{work_request_id}/errors")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "limit" => Keyword.get(opts, :limit),
      "page" => Keyword.get(opts, :page)
    })
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-next-page")
    )
    |> Request.execute(queue_admin_client.client)
  end

  @doc """
  Lists log entries for a work request.

  Retrieves a paginated list of log messages generated during the execution of a
  specific work request. This provides detailed progress and diagnostic information
  for queue operations.

  ## Parameters

    * `queue_admin_client` - Queue Admin client instance `t:t/0`
    * `work_request_id` - ID of the work request to get logs for
    * `opts` - Options list, see `t:ExOciSdk.Queue.Types.list_work_requests_default_opts/0`

  ## Returns

    * `{:ok, response}` - On success, returns status details
    * `{:error, reason}` - On failure
  """
  @spec list_work_request_logs(t(), Types.list_work_requests_default_opts()) ::
          {:ok, ResponseTypes.response_success()} | {:error, ResponseTypes.response_error()}
  def list_work_request_logs(%__MODULE__{} = queue_admin_client, work_request_id, opts \\ []) do
    settings = service_settings()
    service_endpoint = queue_admin_client.service_endpoint || settings.service_endpoint

    RequestBuilder.new(:get, service_endpoint, "/workRequests/#{work_request_id}/logs")
    |> RequestBuilder.with_headers(%{
      "content-type" => settings.content_type,
      "accept" => settings.accept,
      "opc-request-id" => Keyword.get(opts, :opc_request_id)
    })
    |> RequestBuilder.with_querys(%{
      "limit" => Keyword.get(opts, :limit),
      "page" => Keyword.get(opts, :page)
    })
    |> RequestBuilder.with_response_policy(
      ResponsePolicy.new()
      |> ResponsePolicy.with_headers_to_extract("opc-next-page")
    )
    |> Request.execute(queue_admin_client.client)
  end
end
