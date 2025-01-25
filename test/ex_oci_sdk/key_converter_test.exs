defmodule ExOciSdk.KeyConverterTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.KeyConverter
  doctest ExOciSdk.KeyConverter

  describe "snake_to_camel/1" do
    test "converts simple map keys" do
      snake_case = %{
        compartment_id: "ocid1.compartment.oc1...",
        availability_domain: "AD-1",
        display_name: "test-instance"
      }

      expected = %{
        "compartmentId" => "ocid1.compartment.oc1...",
        "availabilityDomain" => "AD-1",
        "displayName" => "test-instance"
      }

      assert KeyConverter.snake_to_camel(snake_case) == expected
    end

    test "converts nested maps" do
      snake_case = %{
        instance_details: %{
          source_details: %{
            source_type: "image",
            image_id: "ocid1.image.oc1..."
          },
          shape_config: %{
            memory_in_gbs: 16,
            ocpus: 1
          }
        }
      }

      expected = %{
        "instanceDetails" => %{
          "sourceDetails" => %{
            "sourceType" => "image",
            "imageId" => "ocid1.image.oc1..."
          },
          "shapeConfig" => %{
            "memoryInGbs" => 16,
            "ocpus" => 1
          }
        }
      }

      assert KeyConverter.snake_to_camel(snake_case) == expected
    end

    test "trying to convert a non map value" do
      assert KeyConverter.snake_to_camel(2) == 2
    end

    test "empty key string" do
      assert KeyConverter.snake_to_camel(%{"" => "value"}) == %{"" => "value"}
    end

    test "empty value string" do
      assert KeyConverter.snake_to_camel(%{empty_key: ""}) == %{"emptyKey" => ""}
    end

    test "leading underscore" do
      assert KeyConverter.snake_to_camel(%{_leading_underscore: "value"}) == %{
               "leadingUnderscore" => "value"
             }
    end

    test "empty parts after split" do
      assert KeyConverter.snake_to_camel(%{empty__parts: "value"}) == %{"emptyParts" => "value"}
    end

    test "multiple consecutive underscores" do
      assert KeyConverter.snake_to_camel(%{multiple___underscores: "value"}) == %{
               "multipleUnderscores" => "value"
             }
    end

    test "converts lists of maps" do
      snake_case = %{
        nsg_rules: [
          %{
            direction: "INGRESS",
            source_type: "CIDR_BLOCK",
            source: "0.0.0.0/0",
            protocol: "6",
            tcp_options: %{
              destination_port_range: %{
                min: 22,
                max: 22
              }
            }
          }
        ]
      }

      expected = %{
        "nsgRules" => [
          %{
            "direction" => "INGRESS",
            "sourceType" => "CIDR_BLOCK",
            "source" => "0.0.0.0/0",
            "protocol" => "6",
            "tcpOptions" => %{
              "destinationPortRange" => %{
                "min" => 22,
                "max" => 22
              }
            }
          }
        ]
      }

      assert KeyConverter.snake_to_camel(snake_case) == expected
    end

    test "handle empty maps" do
      assert KeyConverter.snake_to_camel(%{}) == %{}
    end

    test "handles nil values" do
      snake_case = %{dedicated_vm_host_id: nil, ipxe_script: nil}

      assert KeyConverter.snake_to_camel(snake_case) == %{
               "dedicatedVmHostId" => nil,
               "ipxeScript" => nil
             }
    end

    test "preserves string keys in input maps" do
      snake_case = %{
        "already_string_key" => "value1",
        atom_key: "value2"
      }

      assert KeyConverter.snake_to_camel(snake_case) == %{
               "alreadyStringKey" => "value1",
               "atomKey" => "value2"
             }
    end
  end

  describe "camel_to_snake/1" do
    test "converts simple map keys" do
      camel_case = %{
        "compartmentId" => "ocid1.compartment.oc1...",
        "displayName" => "test-instance",
        "lifecycleState" => "RUNNING"
      }

      expected = %{
        "compartment_id" => "ocid1.compartment.oc1...",
        "display_name" => "test-instance",
        "lifecycle_state" => "RUNNING"
      }

      assert KeyConverter.camel_to_snake(camel_case) == expected
    end

    test "converts nested maps" do
      camel_case = %{
        "launchOptions" => %{
          "bootVolumeType" => "PARAVIRTUALIZED",
          "networkType" => "VFIO",
          "isPvEncryptionInTransitEnabled" => true
        }
      }

      expected = %{
        "launch_options" => %{
          "boot_volume_type" => "PARAVIRTUALIZED",
          "network_type" => "VFIO",
          "is_pv_encryption_in_transit_enabled" => true
        }
      }

      assert KeyConverter.camel_to_snake(camel_case) == expected
    end

    test "converts lists of maps" do
      camel_case = %{
        "volumeAttachments" => [
          %{
            "attachmentType" => "paravirtualized",
            "devicePath" => "/dev/oracleoci/oraclevdb",
            "displayName" => "volume-1",
            "isReadOnly" => false
          }
        ]
      }

      expected = %{
        "volume_attachments" => [
          %{
            "attachment_type" => "paravirtualized",
            "device_path" => "/dev/oracleoci/oraclevdb",
            "display_name" => "volume-1",
            "is_read_only" => false
          }
        ]
      }

      assert KeyConverter.camel_to_snake(camel_case) == expected
    end

    test "handle empty maps" do
      assert KeyConverter.camel_to_snake(%{}) == %{}
    end

    test "trying to convert a non map value" do
      assert KeyConverter.camel_to_snake(2) == 2
    end

    test "empty key string" do
      assert KeyConverter.camel_to_snake(%{"" => "value"}) == %{"" => "value"}
    end

    test "empty value string" do
      assert KeyConverter.camel_to_snake(%{"camelCase" => ""}) == %{"camel_case" => ""}
    end

    test "handles nil values" do
      camel_case = %{"dedicatedVmHostId" => nil, "ipxeScript" => nil}

      assert KeyConverter.camel_to_snake(camel_case) == %{
               "dedicated_vm_host_id" => nil,
               "ipxe_script" => nil
             }
    end

    test "preserves string keys in input maps" do
      camel_case = %{
        "alreadyStringKey" => "value1",
        atomKey: "value2"
      }

      assert KeyConverter.camel_to_snake(camel_case) == %{
               "already_string_key" => "value1",
               "atom_key" => "value2"
             }
    end

    test "converts with embedded acronyms" do
      camel_case = %{
        "bindingVCNValue" => "value1",
        "existingVNICId" => "ocid1.vnic...",
        "associatedNSGIds" => ["ocid1.nsg..."],
        "dedicatedVMHostId" => "ocid1.vmhost...",
        "createVNICDetails" => %{
          "assignPublicIPAddress" => true,
          "primaryIPV6Address" => "2001:db8::1"
        }
      }

      expected = %{
        "binding_vcn_value" => "value1",
        "existing_vnic_id" => "ocid1.vnic...",
        "associated_nsg_ids" => ["ocid1.nsg..."],
        "dedicated_vm_host_id" => "ocid1.vmhost...",
        "create_vnic_details" => %{
          "assign_public_ip_address" => true,
          "primary_ipv6_address" => "2001:db8::1"
        }
      }

      assert KeyConverter.camel_to_snake(camel_case) == expected
    end
  end
end
