defmodule ExOciSdk.Queue.QueueAdminClientTest do
  use ExUnit.Case, async: true

  alias ExOciSdk.{Config, Client}
  alias ExOciSdk.Queue.QueueAdminClient

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

    test "create queue admin client with defaults options", %{client: client} do
      queue_admin_client = QueueAdminClient.create(client)

      assert queue_admin_client.client == client
      assert queue_admin_client.service_endpoint == nil
    end

    test "create queue admin client with valid options", %{client: client} do
      queue_admin_client =
        QueueAdminClient.create(client, service_endpoint: "https://queue-custom.com")

      assert queue_admin_client.client == client
      assert queue_admin_client.service_endpoint == "https://queue-custom.com"
    end
  end

  describe "service_settings/0" do
    test "queue admin client service settings default" do
      settings = QueueAdminClient.service_settings()

      assert settings.service_endpoint ==
               "https://messaging.{region}.oci.oraclecloud.com/20210201"

      assert settings.content_type == "application/json"
      assert settings.accept == "application/json"
    end
  end

  describe "get_queue/3" do
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

      queue_admin_client = QueueAdminClient.create(client)

      queue_string = ~s({
         "id": "ocid1.queue.oc1.xxx",
         "compartmentId": "ocid1.compartment.oc1.xxx",
         "displayName": "test-queue",
         "lifecycleState": "DELETED"
       })

      queue_parsed = %{
        "id" => "ocid1.queue.oc1.xxx",
        "compartment_id" => "ocid1.compartment.oc1.xxx",
        "display_name" => "test-queue",
        "lifecycle_state" => "DELETED"
      }

      %{
        queue_admin_client: queue_admin_client,
        queue_string: queue_string,
        queue_parsed: queue_parsed
      }
    end

    test "get queue with default opts", %{
      queue_admin_client: queue_admin_client,
      queue_string: queue_string,
      queue_parsed: queue_parsed
    } do
      queue_id = "ocid1.queue.oc1.xxx"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == queue_string
        queue_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{queue_admin_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}"

        {:ok,
         %{
           status_code: 200,
           body: queue_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "get_queue_request_id"}
           ]
         }}
      end)

      assert {:ok, result} = QueueAdminClient.get_queue(queue_admin_client, queue_id)
      assert result.data == queue_parsed
      assert result.metadata[:opc_request_id] == "get_queue_request_id"
    end
  end

  describe "list_queues/2" do
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

      queue_admin_client = QueueAdminClient.create(client)

      queues_string = ~s({
         "items": [
           {
             "id": "ocid1.queue.oc1.xxx",
             "compartmentId": "ocid1.compartment.oc1.xxx",
             "displayName": "test-queue-1",
             "lifecycleState": "ACTIVE"
           },
           {
             "id": "ocid1.queue.oc1.yyy",
             "compartmentId": "ocid1.compartment.oc1.xxx",
             "displayName": "test-queue-2",
             "lifecycleState": "ACTIVE"
           }
         ]
       })

      queues_parsed = %{
        "items" => [
          %{
            "id" => "ocid1.queue.oc1.xxx",
            "compartment_id" => "ocid1.compartment.oc1.xxx",
            "display_name" => "test-queue-1",
            "lifecycle_state" => "ACTIVE"
          },
          %{
            "id" => "ocid1.queue.oc1.yyy",
            "compartment_id" => "ocid1.compartment.oc1.xxx",
            "display_name" => "test-queue-2",
            "lifecycle_state" => "ACTIVE"
          }
        ]
      }

      %{
        queue_admin_client: queue_admin_client,
        queues_string: queues_string,
        queues_parsed: queues_parsed
      }
    end

    test "list queues with default opts", %{
      queue_admin_client: queue_admin_client,
      queues_string: queues_string,
      queues_parsed: queues_parsed
    } do
      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == queues_string
        queues_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{queue_admin_client.client.config.region}.oci.oraclecloud.com/20210201/queues?compartmentId=ocid1.compartment.oc1.xxx"

        {:ok,
         %{
           status_code: 200,
           body: queues_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "list_queues_request_id"},
             {"opc-next-page", "DDM@MDM@SLALKSLK!LK$331204=="}
           ]
         }}
      end)

      compartment_id = "ocid1.compartment.oc1.xxx"

      assert {:ok, result} =
               QueueAdminClient.list_queues(queue_admin_client, compartment_id: compartment_id)

      assert result.data == queues_parsed
      assert result.metadata[:opc_request_id] == "list_queues_request_id"
      assert result.metadata["opc-next-page"] == "DDM@MDM@SLALKSLK!LK$331204=="
    end

    test "list queues with filters", %{
      queue_admin_client: queue_admin_client,
      queues_string: queues_string,
      queues_parsed: queues_parsed
    } do
      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == queues_string
        queues_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "opc-request-id") == "custom_request_id"

        assert url ==
                 "https://messaging.#{queue_admin_client.client.config.region}.oci.oraclecloud.com/20210201/queues?compartmentId=ocid1.compartment.oc1.xxx&displayName=test-queue&limit=10&page=1"

        {:ok,
         %{
           status_code: 200,
           body: queues_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "custom_request_id"},
             {"opc-next-page", "DDM@MDM@SLALKSLK!LK$331204=="}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.list_queues(queue_admin_client,
                 compartment_id: "ocid1.compartment.oc1.xxx",
                 display_name: "test-queue",
                 limit: 10,
                 page: 1,
                 opc_request_id: "custom_request_id"
               )

      assert result.data == queues_parsed
      assert result.metadata[:opc_request_id] == "custom_request_id"
      assert result.metadata["opc-next-page"] == "DDM@MDM@SLALKSLK!LK$331204=="
    end
  end

  describe "create_queue/3" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      create_queue_input = %{
        "displayName" => "test-queue",
        "compartmentId" => "ocid1.compartment.oc1.xxx",
        "retentionInSeconds" => 3600,
        "visibilityInSeconds" => 30
      }

      create_queue_string = ~s({
        "displayName": "test-queue",
        "compartmentId": "ocid1.compartment.oc1.xxx",
        "retentionInSeconds": 3600,
        "visibilityInSeconds": 30
      })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == create_queue_input
        create_queue_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_admin_client = QueueAdminClient.create(client)

      %{
        queue_admin_client: queue_admin_client,
        create_queue_input: create_queue_input,
        create_queue_string: create_queue_string
      }
    end

    test "create queue with default opts", %{
      queue_admin_client: queue_admin_client,
      create_queue_input: create_queue_input,
      create_queue_string: create_queue_string
    } do
      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == create_queue_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{queue_admin_client.client.config.region}.oci.oraclecloud.com/20210201/queues"

        {:ok,
         %{
           status_code: 202,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "create_queue_request_id"},
             {"opc-work-request-id", "work_request_123"}
           ]
         }}
      end)

      assert {:ok, result} = QueueAdminClient.create_queue(queue_admin_client, create_queue_input)
      assert result.metadata[:opc_request_id] == "create_queue_request_id"
      assert result.metadata["opc-work-request-id"] == "work_request_123"
    end
  end

  describe "delete_queue/3" do
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

      queue_admin_client = QueueAdminClient.create(client)

      %{
        queue_admin_client: queue_admin_client
      }
    end

    test "delete queue with default opts", %{queue_admin_client: queue_admin_client} do
      queue_id = "ocid1.queue.oc1.phx.random_id"

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :delete
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{queue_admin_client.client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}"

        {:ok,
         %{
           status_code: 202,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "delete_request_123"},
             {"opc-work-request-id", "wr_delete_123"}
           ]
         }}
      end)

      assert {:ok, result} = QueueAdminClient.delete_queue(queue_admin_client, queue_id)
      assert result.metadata[:opc_request_id] == "delete_request_123"
      assert result.metadata["opc-work-request-id"] == "wr_delete_123"
    end
  end

  describe "purge_queue/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      purge_input = %{
        "purge_type" => "NORMAL",
        "channel_ids" => ["channel-1", "channel-2"]
      }

      purge_string = ~s({
         "purgeType": "NORMAL",
         "channelIds": ["channel-1", "channel-2"]
       })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == %{
                 "purgeType" => "NORMAL",
                 "channelIds" => ["channel-1", "channel-2"]
               }

        purge_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_admin_client = QueueAdminClient.create(client)

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        purge_input: purge_input,
        purge_string: purge_string,
        queue_id: "ocid1.queue.oc1.phx.unique_queue_id"
      }
    end

    test "purge queue with custom channel ids", %{
      client: client,
      queue_admin_client: queue_admin_client,
      purge_input: purge_input,
      purge_string: purge_string,
      queue_id: queue_id
    } do
      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == purge_string
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "if-match") == "etag_123"
        assert Map.get(headers, "opc-request-id") == "purge_request_123"

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/actions/purge"

        {:ok,
         %{
           status_code: 202,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "purge_request_123"},
             {"opc-work-request-id", "wr_purge_123"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.purge_queue(
                 queue_admin_client,
                 queue_id,
                 purge_input,
                 if_match: "etag_123",
                 opc_request_id: "purge_request_123"
               )

      assert result.metadata[:opc_request_id] == "purge_request_123"
      assert result.metadata["opc-work-request-id"] == "wr_purge_123"
    end
  end

  describe "update_queue/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

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

      expected_converted_input = %{
        "displayName" => "updated-queue-name",
        "visibilityInSeconds" => 60,
        "timeoutInSeconds" => 30,
        "deadLetterQueueDeliveryCount" => 5,
        "freeformTags" => %{
          "department" => "engineering",
          "environment" => "production"
        }
      }

      update_string = ~s({
          "displayName": "updated-queue-name",
          "visibilityInSeconds": 60,
          "timeoutInSeconds": 30,
          "deadLetterQueueDeliveryCount": 5,
          "freeformTags": {
            "department": "engineering",
            "environment": "production"
          }
        })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == expected_converted_input
        update_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_admin_client = QueueAdminClient.create(client)

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        update_input: update_input,
        update_string: update_string,
        queue_id: "ocid1.queue.oc1.phx.unique_queue_id"
      }
    end

    test "update queue with all fields and default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      update_input: update_input,
      update_string: update_string,
      queue_id: queue_id
    } do
      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :put
        assert body == update_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}"

        {:ok,
         %{
           status_code: 202,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "update_request_123"},
             {"opc-work-request-id", "wr_update_123"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.update_queue(
                 queue_admin_client,
                 queue_id,
                 update_input
               )

      assert result.metadata[:opc_request_id] == "update_request_123"
      assert result.metadata["opc-work-request-id"] == "wr_update_123"
    end
  end

  describe "change_queue_compartment/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../../support/config"))

      expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
      expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

      compartment_input = %{
        "compartment_id" => "ocid1.compartment.oc1.xxx.new_compartment"
      }

      expected_converted_input = %{
        "compartmentId" => "ocid1.compartment.oc1.xxx.new_compartment"
      }

      compartment_string = ~s({
         "compartmentId": "ocid1.compartment.oc1.xxx.new_compartment"
       })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == expected_converted_input
        compartment_string
      end)

      client =
        Client.create!(config,
          http_client: {ExOciSdk.HTTPClientMock, []},
          json: {ExOciSdk.JSONMock, []}
        )

      queue_admin_client = QueueAdminClient.create(client)

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        compartment_input: compartment_input,
        compartment_string: compartment_string,
        queue_id: "ocid1.queue.oc1.phx.unique_queue_id"
      }
    end

    test "change compartment with default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      compartment_input: compartment_input,
      compartment_string: compartment_string,
      queue_id: queue_id
    } do
      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :post
        assert body == compartment_string
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/queues/#{queue_id}/actions/changeCompartment"

        {:ok,
         %{
           status_code: 202,
           body: "",
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "change_comp_request_123"},
             {"opc-work-request-id", "wr_change_123"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.change_queue_compartment(
                 queue_admin_client,
                 queue_id,
                 compartment_input
               )

      assert result.metadata[:opc_request_id] == "change_comp_request_123"
      assert result.metadata["opc-work-request-id"] == "wr_change_123"
    end
  end

  describe "get_work_request/3" do
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

      queue_admin_client = QueueAdminClient.create(client)

      work_request_string = ~s({
        "compartmentId": "ocid1.compartment.oc1.xxx",
        "id": "ocid1.queueworkrequest.oc1.xxx",
        "operationType": "CREATE_QUEUE",
        "percentComplete": 100.0,
        "resources": [
          %{
            "actionType": "CREATED",
            "entityType": "queue",
            "entityUri": "/queues/ocid1.queue.oc1.xxx",
            "identifier": "ocid1.queue.oc1.xxx"
          }
        ],
        "status": "SUCCEEDED",
        "timeAccepted": "2025-02-03T00:37:33.707Z",
        "timeFinished": "2025-02-03T00:37:44.757Z",
        "timeStarted": "2025-02-03T00:37:44.590Z"
      })

      work_request_converted = %{
        "compartment_id" => "ocid1.compartment.oc1.xxx",
        "id" => "ocid1.queueworkrequest.oc1.xxx",
        "operation_type" => "CREATE_QUEUE",
        "percent_complete" => 100.0,
        "resources" => [
          %{
            "action_type" => "CREATED",
            "entity_type" => "queue",
            "entity_uri" => "/queues/ocid1.queue.oc1.xxx",
            "identifier" => "ocid1.queue.oc1.xxx"
          }
        ],
        "status" => "SUCCEEDED",
        "time_accepted" => "2025-02-03T00:37:33.707Z",
        "time_finished" => "2025-02-03T00:37:44.757Z",
        "time_started" => "2025-02-03T00:37:44.590Z"
      }

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        work_request_string: work_request_string,
        work_request_converted: work_request_converted
      }
    end

    test "get work request with default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      work_request_string: work_request_string,
      work_request_converted: work_request_converted
    } do
      work_request_id = "ocid1.queueworkrequest.oc1.xxx"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == work_request_string
        work_request_converted
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/workRequests/#{work_request_id}"

        {:ok,
         %{
           status_code: 200,
           body: work_request_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "get_work_request_123"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.get_work_request(queue_admin_client, work_request_id)

      assert result.data == work_request_converted
      assert result.metadata[:opc_request_id] == "get_work_request_123"
      assert result.data["status"] == "SUCCEEDED"
      assert result.data["percent_complete"] == 100.0
      assert result.data["operation_type"] == "CREATE_QUEUE"

      [resource] = result.data["resources"]
      assert resource["action_type"] == "CREATED"
      assert resource["entity_type"] == "queue"
    end
  end

  describe "list_work_requests/2" do
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

      queue_admin_client = QueueAdminClient.create(client)

      work_requests_string = ~s({
        "items": [
          {
            "compartmentId": "ocid1.compartment.oc1.xxx",
            "id": "ocid1.queueworkrequest.oc1.xxx",
            "operationType": "CREATE_QUEUE",
            "percentComplete": 100.0,
            "resources": [
              {
                "actionType": "CREATED",
                "entityType": "queue",
                "entityUri": "/queues/ocid1.queue.oc1.xxx",
                "identifier": "ocid1.queue.oc1.xxx"
              }
            ],
            "status": "SUCCEEDED",
            "timeAccepted": "2025-02-03T00:37:33.707Z",
            "timeFinished": "2025-02-03T00:37:44.757Z",
            "timeStarted": "2025-02-03T00:37:44.590Z"
          }
        ]
      })

      work_requests_parsed = %{
        "items" => [
          %{
            "compartment_id" => "ocid1.compartment.oc1.xxx",
            "id" => "ocid1.queueworkrequest.oc1.xxx",
            "operation_type" => "CREATE_QUEUE",
            "percent_complete" => 100.0,
            "resources" => [
              %{
                "action_type" => "CREATED",
                "entity_type" => "queue",
                "entity_uri" => "/queues/ocid1.queue.oc1.xxx",
                "identifier" => "ocid1.queue.oc1.xxx"
              }
            ],
            "status" => "SUCCEEDED",
            "time_accepted" => "2025-02-03T00:37:33.707Z",
            "time_finished" => "2025-02-03T00:37:44.757Z",
            "time_started" => "2025-02-03T00:37:44.590Z"
          }
        ]
      }

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        work_requests_string: work_requests_string,
        work_requests_parsed: work_requests_parsed
      }
    end

    test "list work requests with default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      work_requests_string: work_requests_string,
      work_requests_parsed: work_requests_parsed
    } do
      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == work_requests_string
        work_requests_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/workRequests?compartmentId=ocid1.compartment.oc1.xxx"

        {:ok,
         %{
           status_code: 200,
           body: work_requests_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "list_work_requests_123"},
             {"opc-next-page", "NEXT_PAGE_TOKEN"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.list_work_requests(queue_admin_client,
                 compartment_id: "ocid1.compartment.oc1.xxx"
               )

      assert result.data == work_requests_parsed
      assert result.metadata[:opc_request_id] == "list_work_requests_123"
      assert result.metadata["opc-next-page"] == "NEXT_PAGE_TOKEN"
    end
  end

  describe "list_work_request_logs/3" do
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

      queue_admin_client = QueueAdminClient.create(client)

      work_request_logs_string = ~s({
        "items": [
          {
            "message": "Generated data encryption key",
            "timestamp": "2025-02-03T00:37:44.730Z"
          },
          {
            "message": "Successfully created Queue",
            "timestamp": "2025-02-03T00:37:44.771Z"
          }
        ]
      })

      work_request_logs_parsed = %{
        "items" => [
          %{
            "message" => "Generated data encryption key",
            "timestamp" => "2025-02-03T00:37:44.730Z"
          },
          %{
            "message" => "Successfully created Queue",
            "timestamp" => "2025-02-03T00:37:44.771Z"
          }
        ]
      }

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        work_request_logs_string: work_request_logs_string,
        work_request_logs_parsed: work_request_logs_parsed
      }
    end

    test "list work request logs with default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      work_request_logs_string: work_request_logs_string,
      work_request_logs_parsed: work_request_logs_parsed
    } do
      work_request_id = "ocid1.queueworkrequest.oc1.xxx"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == work_request_logs_string
        work_request_logs_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/workRequests/#{work_request_id}/logs"

        {:ok,
         %{
           status_code: 200,
           body: work_request_logs_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "list_work_request_logs_123"},
             {"opc-next-page", "NEXT_PAGE_TOKEN"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.list_work_request_logs(queue_admin_client, work_request_id)

      assert result.data == work_request_logs_parsed
      assert result.metadata[:opc_request_id] == "list_work_request_logs_123"
      assert result.metadata["opc-next-page"] == "NEXT_PAGE_TOKEN"
    end
  end

  describe "list_work_request_errors/3" do
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

      queue_admin_client = QueueAdminClient.create(client)

      work_request_errors_string = ~s({
        "items": [
          {
            "code": "InternalError",
            "message": "An internal error occurred",
            "timestamp": "2025-02-03T00:37:44.730Z"
          }
        ]
      })

      work_request_errors_parsed = %{
        "items" => [
          %{
            "code" => "InternalError",
            "message" => "An internal error occurred",
            "timestamp" => "2025-02-03T00:37:44.730Z"
          }
        ]
      }

      %{
        client: client,
        queue_admin_client: queue_admin_client,
        work_request_errors_string: work_request_errors_string,
        work_request_errors_parsed: work_request_errors_parsed
      }
    end

    test "list work request errors with default opts", %{
      client: client,
      queue_admin_client: queue_admin_client,
      work_request_errors_string: work_request_errors_string,
      work_request_errors_parsed: work_request_errors_parsed
    } do
      work_request_id = "ocid1.queueworkrequest.oc1.xxx"

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == work_request_errors_string
        work_request_errors_parsed
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn method, url, body, headers, _options ->
        assert method == :get
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        assert url ==
                 "https://messaging.#{client.config.region}.oci.oraclecloud.com/20210201/workRequests/#{work_request_id}/errors"

        {:ok,
         %{
           status_code: 200,
           body: work_request_errors_string,
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "list_work_request_errors_123"},
             {"opc-next-page", "NEXT_PAGE_TOKEN"}
           ]
         }}
      end)

      assert {:ok, result} =
               QueueAdminClient.list_work_request_errors(queue_admin_client, work_request_id)

      assert result.data == work_request_errors_parsed
      assert result.metadata[:opc_request_id] == "list_work_request_errors_123"
      assert result.metadata["opc-next-page"] == "NEXT_PAGE_TOKEN"
    end
  end
end
