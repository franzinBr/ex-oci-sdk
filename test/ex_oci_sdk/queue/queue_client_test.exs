defmodule ExOciSdk.Queue.QueueClientTest do
  use ExUnit.Case, async: true

  alias ExOciSdk.{Config, Client, KeyConverter}
  alias ExOciSdk.Queue.QueueClient

  import Mox

  setup :verify_on_exit!

  describe "create/2" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      %{
        client: client
      }
    end

    test "create queue client with defaults options", %{client: client} do
      queue_client = QueueClient.create(client)

      assert queue_client.client == client
      assert queue_client.service_endpoint == nil
    end

    test "create queue client with valid options", %{client: client} do
      queue_client = QueueClient.create(client, service_endpoint: "https://queue-custom.com")

      assert queue_client.client == client
      assert queue_client.service_endpoint == "https://queue-custom.com"
    end
  end

  describe "service_settings/0" do
    test "queue client service settings default" do
      settings = QueueClient.service_settings()

      assert settings.service_endpoint ==
               "https://cell-1.queue.messaging.{region}.oci.oraclecloud.com/20210201"

      assert settings.content_type == "application/json"
      assert settings.accept == "application/json"
    end
  end

  describe "get_messages/3" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == ""
        ""
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      messages_string = ~s({"messages": [
               %{
                    "content": "Hello world",
                    "createdAt": "2025-01-25T10:50:25.878Z",
                    "deliveryCount": 1,
                    "expireAfter": "2025-01-26T10:50:25.878Z",
                    "id": 33339044425066221,
                    "receipt": "AfKbbsfco-TnAAU0D6rtUoGKauWgNErIQwtgLDQ47kAYAWGLnADQVpDK@MDKmskkJSAKJDSKjksjkJKAJKSJKAWKJH",
                    "visibleAfter": "2025-01-25T10:53:30.775Z"
                 }
             ]})

      messages_parsed = %{
        "messages" => [
          %{
            "content" => "Hello world",
            "created_at" => "2025-01-25T10:50:25.878Z",
            "delivery_count" => 1,
            "expire_after" => "2025-01-26T10:50:25.878Z",
            "id" => 33_339_044_425_066_221,
            "receipt" =>
              "AfKbbsfco-TnAAU0D6rtUoGKauWgNErIQwtgLDQ47kAYAWGLnADQVpDK@MDKmskkJSAKJDSKjksjkJKAJKSJKAWKJH",
            "visible_after" => "2025-01-25T10:53:30.775Z"
          }
        ]
      }

      %{
        queue_client: queue_client,
        messages_string: messages_string,
        messages_parsed: messages_parsed
      }
    end

    test "get messages from queue client with defaults opts", %{
      queue_client: queue_client,
      messages_string: messages_string,
      messages_parsed: messages_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == messages_string
        messages_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages"

        {:ok,
         %{
           status_code: 200,
           body: messages_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "fffjBBBddCCCsdss555"}
           ]
         }}
      end)

      assert {:ok, messages} = QueueClient.get_messages(queue_client, queue_id)
      assert messages.data == messages_parsed
      assert messages.metadata[:opc_request_id] == "fffjBBBddCCCsdss555"
    end

    test "get messages from queue client with valids opts", %{
      queue_client: queue_client,
      messages_string: messages_string,
      messages_parsed: messages_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == messages_string
        messages_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert Map.get(headers, "opc-request-id") == "fffffff"

        assert(
          url ==
            "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages?channelFilter=xpto&limit=10&timeoutInSeconds=5&visibilityInSeconds=60"
        )

        {:ok,
         %{
           status_code: 200,
           body: messages_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "fffffff"}
           ]
         }}
      end)

      assert {:ok, messages} =
               QueueClient.get_messages(queue_client, queue_id,
                 limit: 10,
                 timeout_in_seconds: 5,
                 visibility_in_seconds: 60,
                 channel_filter: "xpto",
                 opc_request_id: "fffffff"
               )

      assert messages.data == messages_parsed
      assert messages.metadata[:opc_request_id] == "fffffff"
    end
  end

  describe "put_messages/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      messages = %{
        "messages" => [
          %{
            "content" => "Hello world",
            "channel" => "default"
          }
        ]
      }

      messages_string = ~s({
        "messages": [
          {
            "content": "Hello world"
          }
        ]
      })

      response = %{
        "messages" => [
          %{
            "id" => 33_339_044_425_066_221
          }
        ]
      }

      response_string = ~s({
        "messages": [
          {
            "id": 33339044425066221
          }
        ]
      })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == messages
        messages_string
      end)

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == response_string
        response
      end)

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        messages: messages,
        messages_string: messages_string,
        response: response,
        response_string: response_string
      }
    end

    test "put messages to queue client with default opts", %{
      queue_client: queue_client,
      messages: messages,
      messages_string: messages_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == messages_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "aaaabbbcccddd"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.put_messages(queue_client, queue_id, messages)
      assert result.data == response
      assert result.metadata[:opc_request_id] == "aaaabbbcccddd"
    end

    test "put messages to queue client with valid opts", %{
      queue_client: queue_client,
      messages: messages,
      messages_string: messages_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == messages_string
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-request-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-request-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.put_messages(queue_client, queue_id, messages,
                 opc_request_id: "custom-request-id"
               )

      assert result.data == response
      assert result.metadata[:opc_request_id] == "custom-request-id"
    end
  end

  describe "get_stats/3" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      stats_string = ~s({
        "backlog": 42,
        "inFlightMessages": 7,
        "visibleMessages": 35,
        "deadLetterMessages": 0
      })

      stats_parsed = %{
        "backlog" => 42,
        "in_flight_messages" => 7,
        "visible_messages" => 35,
        "dead_letter_messages" => 0
      }

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == ""
        ""
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        stats_string: stats_string,
        stats_parsed: stats_parsed
      }
    end

    test "get stats from queue client with default opts", %{
      queue_client: queue_client,
      stats_string: stats_string,
      stats_parsed: stats_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == stats_string
        stats_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/stats"

        {:ok,
         %{
           status_code: 200,
           body: stats_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "stats-request-id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.get_stats(queue_client, queue_id)
      assert result.data == stats_parsed
      assert result.metadata[:opc_request_id] == "stats-request-id"
    end

    test "get stats from queue client with valid opts", %{
      queue_client: queue_client,
      stats_string: stats_string,
      stats_parsed: stats_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == stats_string
        stats_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-stats-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/stats?channelId=channel-1"

        {:ok,
         %{
           status_code: 200,
           body: stats_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-stats-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.get_stats(queue_client, queue_id,
                 channel_id: "channel-1",
                 opc_request_id: "custom-stats-id"
               )

      assert result.data == stats_parsed
      assert result.metadata[:opc_request_id] == "custom-stats-id"
    end
  end

  describe "list_channels/3" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      channels_string = ~s({
        "items": [
          {
            "channelId": "channel-1",
            "messageCount": 42
          },
          {
            "channelId": "channel-2",
            "messageCount": 17
          }
        ]
      })

      channels_parsed = %{
        "items" => [
          %{
            "channel_id" => "channel-1",
            "message_count" => 42
          },
          %{
            "channel_id" => "channel-2",
            "message_count" => 17
          }
        ]
      }

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == ""
        ""
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        channels_string: channels_string,
        channels_parsed: channels_parsed
      }
    end

    test "list channels from queue client with default opts", %{
      queue_client: queue_client,
      channels_string: channels_string,
      channels_parsed: channels_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == channels_string
        channels_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/channels"

        {:ok,
         %{
           status_code: 200,
           body: channels_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "channels-request-id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.list_channels(queue_client, queue_id)
      assert result.data == channels_parsed
      assert result.metadata[:opc_request_id] == "channels-request-id"
    end

    test "list channels from queue client with valid opts", %{
      queue_client: queue_client,
      channels_string: channels_string,
      channels_parsed: channels_parsed
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == channels_string
        channels_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-channels-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/channels?channelFilter=test&limit=10&page=1"

        {:ok,
         %{
           status_code: 200,
           body: channels_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-channels-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.list_channels(queue_client, queue_id,
                 limit: 10,
                 page: 1,
                 channel_filter: "test",
                 opc_request_id: "custom-channels-id"
               )

      assert result.data == channels_parsed
      assert result.metadata[:opc_request_id] == "custom-channels-id"
    end
  end

  describe "delete_message/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == ""
        ""
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{queue_client: queue_client}
    end

    test "delete message from queue client with default opts", %{queue_client: queue_client} do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"
      message_receipt = "message-receipt-123"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :delete
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/#{message_receipt}"

        {:ok,
         %{
           status_code: 204,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "delete-request-id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.delete_message(queue_client, queue_id, message_receipt)
      assert result.data == nil
      assert result.metadata[:opc_request_id] == "delete-request-id"
    end

    test "delete message from queue client with valid opts", %{queue_client: queue_client} do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"
      message_receipt = "message-receipt-123"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :delete
        assert body == ""
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-delete-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/#{message_receipt}"

        {:ok,
         %{
           status_code: 204,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-delete-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.delete_message(queue_client, queue_id, message_receipt,
                 opc_request_id: "custom-delete-id"
               )

      assert result.data == nil
      assert result.metadata[:opc_request_id] == "custom-delete-id"
    end
  end

  describe "delete_messages/5" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

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

      delete_messages_string = ~s({
      "entries": [
        {
          "receipt": "message-receipt-1"
        },
        {
          "receipt": "message-receipt-2"
        }
      ]
    })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == delete_messages
        delete_messages_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        delete_messages: delete_messages,
        delete_messages_string: delete_messages_string
      }
    end

    test "delete messages from queue client with default opts", %{
      queue_client: queue_client,
      delete_messages: delete_messages,
      delete_messages_string: delete_messages_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == delete_messages_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/actions/deleteMessages"

        {:ok,
         %{
           status_code: 204,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "delete-request-id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.delete_messages(queue_client, queue_id, delete_messages)
      assert result.data == nil
      assert result.metadata[:opc_request_id] == "delete-request-id"
    end

    test "delete messages from queue client with valid opts", %{
      queue_client: queue_client,
      delete_messages: delete_messages,
      delete_messages_string: delete_messages_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == delete_messages_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/actions/deleteMessages"

        {:ok,
         %{
           status_code: 204,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-delete-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.delete_messages(queue_client, queue_id, delete_messages,
                 opc_request_id: "custom-delete-id"
               )

      assert result.data == nil
      assert result.metadata[:opc_request_id] == "custom-delete-id"
    end
  end

  describe "update_message/5" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      update_message = %{
        "visibilityInSeconds" => 30
      }

      update_message_string = ~s({
        "visibilityInSeconds": 30
      })

      response = %{
        "receipt" => "new-message-receipt-123",
        "visibleAfter" => "2025-01-25T10:53:30.775Z"
      }

      response_string = ~s({
        "receipt": "new-message-receipt-123",
        "visibleAfter": "2025-01-25T10:53:30.775Z"
      })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == update_message
        update_message_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        update_message: update_message,
        update_message_string: update_message_string,
        response: response,
        response_string: response_string
      }
    end

    test "update message in queue client with default opts", %{
      queue_client: queue_client,
      update_message: update_message,
      update_message_string: update_message_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"
      message_receipt = "message-receipt-123"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == response_string
        response
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :put
        assert body == update_message_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/#{message_receipt}"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "update-request-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.update_message(queue_client, queue_id, message_receipt, update_message)

      assert result.data == response |> KeyConverter.camel_to_snake()
      assert result.metadata[:opc_request_id] == "update-request-id"
    end

    test "update message in queue client with valid opts", %{
      queue_client: queue_client,
      update_message: update_message,
      update_message_string: update_message_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"
      message_receipt = "message-receipt-123"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == response_string
        response
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :put
        assert body == update_message_string
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-update-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/#{message_receipt}"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-update-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.update_message(queue_client, queue_id, message_receipt, update_message,
                 opc_request_id: "custom-update-id"
               )

      assert result.data == response |> KeyConverter.camel_to_snake()
      assert result.metadata[:opc_request_id] == "custom-update-id"
    end
  end

  describe "update_messages/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      update_messages = %{
        "messages" => [
          %{
            "receipt" => "message-receipt-1",
            "visibilityInSeconds" => 30
          },
          %{
            "receipt" => "message-receipt-2",
            "visibilityInSeconds" => 60
          }
        ]
      }

      update_messages_string = ~s({
        "messages": [
          {
            "receipt": "message-receipt-1",
            "visibilityInSeconds": 30
          },
          {
            "receipt": "message-receipt-2",
            "visibilityInSeconds": 60
          }
        ]
      })

      response = %{
        "messages" => [
          %{
            "receipt" => "new-message-receipt-1",
            "visible_after" => "2025-01-25T10:53:30.775Z"
          },
          %{
            "receipt" => "new-message-receipt-2",
            "visible_after" => "2025-01-25T11:23:30.775Z"
          }
        ]
      }

      response_string = ~s({
        "messages": [
          {
            "receipt": "new-message-receipt-1",
            "visibleAfter": "2025-01-25T10:53:30.775Z"
          },
          {
            "receipt": "new-message-receipt-2",
            "visibleAfter": "2025-01-25T11:23:30.775Z"
          }
        ]
      })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == update_messages
        update_messages_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_client = QueueClient.create(client)

      %{
        queue_client: queue_client,
        update_messages: update_messages,
        update_messages_string: update_messages_string,
        response: response,
        response_string: response_string
      }
    end

    test "update messages in queue client with default opts", %{
      queue_client: queue_client,
      update_messages: update_messages,
      update_messages_string: update_messages_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == response_string
        response
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == update_messages_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/actions/updateMessages"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "batch-update-request-id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueClient.update_messages(queue_client, queue_id, update_messages)
      assert result.data == response
      assert result.metadata[:opc_request_id] == "batch-update-request-id"
    end

    test "update messages in queue client with valid opts", %{
      queue_client: queue_client,
      update_messages: update_messages,
      update_messages_string: update_messages_string,
      response: response,
      response_string: response_string
    } do
      queue_id = "ocid1.queue.random-region.amaaabaa2ikrzdya6issa228717dhhdhsahffjsjjazzznffnpo8"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == response_string
        response
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == update_messages_string
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom-batch-update-id"

        assert url ==
                 "https://cell-1.queue.messaging.#{queue_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/messages/actions/updateMessages"

        {:ok,
         %{
           status_code: 200,
           body: response_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom-batch-update-id"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueClient.update_messages(queue_client, queue_id, update_messages,
                 opc_request_id: "custom-batch-update-id"
               )

      assert result.data == response
      assert result.metadata[:opc_request_id] == "custom-batch-update-id"
    end
  end
end
