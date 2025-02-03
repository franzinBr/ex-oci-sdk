# Queue Client

Oracle Cloud Infrastructure (OCI) Queue is a fully managed serverless queue service that enables you to asynchronously process workloads by exchanging messages between different components of distributed applications. It provides reliable message storage and delivery with high availability, guaranteeing at-least-once message delivery.

OCI Queue service helps you build loosely coupled, distributed applications by allowing different parts of your system to communicate asynchronously. Common use cases include:

- Task distribution for worker processes
- Event-driven architectures
- Microservices communication
- Background job processing
- Workload buffering

The QueueClient module provides a robust interface for interacting with OCI Queue Service, handling all message-level operations efficiently.

## Create Queue Client

First, create a new QueueClient instance:

```elixir
# Create a base client with your OCI configuration
config = ExOciSdk.Config.from_file!("path/to/config")
client = ExOciSdk.Client.create!(config)

# Initialize the QueueClient
queue_client = ExOciSdk.Queue.QueueClient.create(client)
```

see more details in `ExOciSdk.Queue.QueueClient.create/2`

## Core Features

### Reading Messages

Retrieve messages from a queue with configurable visibility timeout and batch size:

```elixir
queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.get_messages(queue_client, queue_id,
  visibility_in_seconds: 30,
  timeout_in_seconds: 5,
  limit: 10,
  channel_filter: "my-channel"
)
```

see more details in `ExOciSdk.Queue.QueueClient.get_messages/3`

### Writing Messages

Put new messages into a queue:

```elixir
messages = %{
  "messages" => [
    %{
      "content" => "Hello world",
      "metadata" => %{
        "channel_id" => "default",
        "custom_properties" => %{
          "priority" => "high",
          "source" => "user_service"
        }
      }
    },
    %{
      "content" => "Hello world2"
    },
    %{
      "content" => "Hello world3",
    }
  ]
}

queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.put_messages(queue_client, queue_id, messages)
```

see more details in `ExOciSdk.Queue.QueueClient.put_messages/4`

### Managing Message Visibility

Update visibility timeout for a single message:

```elixir
update_input = %{
  "visibility_in_seconds" => 30
}

queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.update_message(queue_client, queue_id, message_receipt, update_input)
```

Or update multiple messages at once:

```elixir
update_messages = %{
  "messages" => [
    %{
      "receipt" => "message-receipt-1",
      "visibility_in_seconds" => 30
    },
    %{
      "receipt" => "message-receipt-2",
      "visibility_in_seconds" => 60
    }
  ]
}

queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.update_messages(queue_client, queue_id, update_messages)
```

see more details in `ExOciSdk.Queue.QueueClient.update_messages/4`

### Deleting Messages

Delete a single message:

```elixir
queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.delete_message(queue_client, queue_id, message_receipt)
```

see more details in `ExOciSdk.Queue.QueueClient.delete_message/4`

Or delete multiple messages in one operation:

```elixir
delete_messages = %{
  "entries" => [
    %{
      "receipt" => "message-receipt-1"
    },
    %{
      "receipt" => "message-receipt-2"
    }
  ]
}

queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.delete_messages(queue_client, queue_id, delete_messages)
```

see more details in `ExOciSdk.Queue.QueueClient.delete_messages/4`

### Queue Statistics

Get statistics about your queue:

```elixir
queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.get_stats(queue_client, queue_id,
  channel_id: "my-channel"
)
```

see more details in `ExOciSdk.Queue.QueueClient.get_stats/3`

### Channel Listing

List channels in a queue:

```elixir

queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

{:ok, response} = ExOciSdk.Queue.QueueClient.list_channels(queue_client, queue_id,
  limit: 10,
  page: 1,
  channel_filter: "my-channel"
)
```

see more details in `ExOciSdk.Queue.QueueClient.list_channels/3`

## Configuration Options

### Client Creation Options

When creating a QueueClient, you can specify:
- `service_endpoint`: Custom service endpoint URL (optional)

### Operation Options

Most operations accept these common options:
- `opc_request_id`: Custom request identifier for tracing and debugging
- Additional operation-specific options as documented in each function

## Response Format

All operations return a tuple in the format:
- `{:ok, response}` on success
- `{:error, reason}` on failure

The response contains:
- `data`: The operation's result data
- `metadata`: Additional information including the `opc_request_id`

## Error Handling

The client handles various error scenarios and returns appropriate error tuples. Always check the return value and handle both success and error cases in your code.
