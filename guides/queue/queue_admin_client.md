# Queue Admin Client

Queue Admin Client provides comprehensive administrative capabilities for managing queues in your OCI environment. It handles queue lifecycle operations including creation, configuration, deletion, and maintenance of queues. The client supports both synchronous operations (like retrieving queue details) and asynchronous operations (like queue creation) through work requests.


## Create Queue Admin Client

First, create a new QueueAdminClient instance:

```elixir
# Create a base client with your OCI configuration
config = ExOciSdk.Config.from_file!("path/to/config")
client = ExOciSdk.Client.create!(config)

# Initialize the QueueAdminClient
queue_admin_client = ExOciSdk.Queue.QueueAdminClient.create(client)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.create/2`

## Core Features

- Queue lifecycle management (create, update, delete)
- Queue configuration and settings management
- Work request tracking for asynchronous operations
- Queue compartment management
- Queue statistics and monitoring

## Queue Management Operations

### Creating Queues

Create a new queue with specified configuration:

```elixir
create_queue_input = %{
  "display_name" => "my-queue",
  "compartment_id" => "ocid1.compartment.oc1.xxx",
  "retention_in_seconds" => 3600,
  "visibility_in_seconds" => 30
}

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.create_queue(queue_admin_client, create_queue_input)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.create_queue/3`

### Retrieving Queue Details

Get details about a specific queue:

```elixir
queue_id = "ocid1.queue.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.get_queue(queue_admin_client, queue_id)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.get_queue/3`

### Listing Queues

List queues with optional filtering:

```elixir
{:ok, response} = ExOciSdk.Queue.QueueAdminClient.list_queues(queue_admin_client,
  compartment_id: "ocid1.compartment.oc1.xxx",
  display_name: "my-queue",
  limit: 10,
  page: 1
)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.list_queues/2`

### Updating Queues

Update queue configuration:

```elixir
update_input = %{
  "display_name" => "updated-queue-name",
  "visibility_in_seconds" => 60,
  "timeout_in_seconds" => 30,
  "dead_letter_queue_delivery_count" => 5,
  "freeform_tags" => %{
    "department" => "engineering",
    "environment" => "production"
  }
}

queue_id = "ocid1.queue.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.update_queue(queue_admin_client, queue_id, update_input)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.update_queue/4`

### Deleting Queues

Delete a queue:

```elixir
queue_id = "ocid1.queue.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.delete_queue(queue_admin_client, queue_id)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.delete_queue/3`

### Purging Queue Messages

Purge messages from a queue:

```elixir
purge_input = %{
  "purge_type" => "NORMAL",
  "channel_ids" => ["channel-1", "channel-2"]
}

queue_id = "ocid1.queue.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.purge_queue(queue_admin_client, queue_id, purge_input)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.purge_queue/4`

### Moving Queues Between Compartments

Change queue compartment:

```elixir
compartment_input = %{
  "compartment_id" => "ocid1.compartment.oc1.xxx.new_compartment"
}

queue_id = "ocid1.queue.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.change_queue_compartment(queue_admin_client, queue_id, compartment_input)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.change_queue_compartment/4`

## Work Request Operations

The following queue operations are asynchronous and return work request IDs:

- `create_queue/3`: Creating new queues
- `delete_queue/3`: Deleting existing queues
- `purge_queue/4`: Purging messages from queues
- `update_queue/4`: Updating queue configurations
- `change_queue_compartment/4`: Moving queues between compartments

These work request operations help track the status of asynchronous operations:

### Get Work Request Status

Check the status of an asynchronous operation:

```elixir
work_request_id = "ocid1.queueworkrequest.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.get_work_request(queue_admin_client, work_request_id)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.get_work_request/3`

### List Work Requests

List all work requests in a compartment:

```elixir
{:ok, response} = ExOciSdk.Queue.QueueAdminClient.list_work_requests(queue_admin_client,
  compartment_id: "ocid1.compartment.oc1.xxx",
  limit: 10,
  page: 1
)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.list_work_requests/2`

### List Work Request Errors

View errors for a specific work request:

```elixir
work_request_id = "ocid1.queueworkrequest.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.list_work_request_errors(queue_admin_client, work_request_id)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.list_work_request_errors/3`

### List Work Request Logs

Access detailed operation logs:

```elixir
work_request_id = "ocid1.queueworkrequest.oc1.xxx"

{:ok, response} = ExOciSdk.Queue.QueueAdminClient.list_work_request_logs(queue_admin_client, work_request_id)
```

see more details in `ExOciSdk.Queue.QueueAdminClient.list_work_request_logs/3`

## Configuration Options

### Client Creation Options

When creating a QueueAdminClient, you can specify:
- `service_endpoint`: Custom service endpoint URL (optional)

### Operation Options

Most operations accept these common options:
- `opc_request_id`: Custom request identifier for tracing and debugging
- `if_match`: For optimistic concurrency control
- Additional operation-specific options as documented in each function

## Response Format

All operations return a tuple in the format:
- `{:ok, response}` on success
- `{:error, reason}` on failure

The response contains:
- `data`: The operation's result data
- `metadata`: Additional information including:
  - `opc_request_id`: Request identifier
  - `opc_work_request_id`: For asynchronous operations
  - `opc_next_page`: For paginated results

## Error Handling

The client handles various error scenarios and returns appropriate error tuples. Always check the return value and handle both success and error cases in your code.
