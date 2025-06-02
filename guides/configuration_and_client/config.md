# Configuration

Before you can make your first API call to OCI, you need to set up authentication. The `ExOciSdk.Config` module is your starting point for interacting with OCI services. This guide will walk you through setting up your configuration properly.

## Required Credentials

To authenticate with OCI, you need:

1. **User OCID**: Your unique user identifier
2. **Tenancy OCID**: Your organization's unique identifier
3. **Private KEY**: private key for API
4. **Key Fingerprint**: Fingerprint of your API key
5. **Region**: Your OCI region

## Getting Your Credentials

### Finding Your OCIDs

1. Log into the OCI Console (https://cloud.oracle.com)
2. Click on your profile icon in the top right
3. To get your User OCID:
- Click on your username
- You will be directed to the "My Profile" page
- ind your User OCID under the "User Information" section
4. To get your Tenancy OCID:
- Return to the profile menu
- Click on "Tenancy: <YOUR_TENANCY>"
- You will be directed to the "Tenancy Details" page
- Find your Tenancy OCID under the "Tenancy Information" section

### Generating API Keys in OCI Console

1. In the OCI Console, go to your User Settings
2. Under "API Keys", click "Add API Key"
3. Choose "Generate API Key Pair"
4. Click "Download Private Key" and "Download Public Key"
5. Save the generated key fingerprint
6. Store the private key securely (e.g., in `~/.oci/oci_api_key.pem`)

## Configuration Methods

The SDK supports three ways to configure your credentials. Let's look at both:

### Method 1: Using OCI Config File

If you've used the [OCI CLI](https://github.com/oracle/oci-cli) before, you might already have a config file at ~/.oci/config. This is the easiest way to get started:

```elixir
# Use default profile from ~/.oci/config
config = ExOciSdk.Config.from_file!()

# Or specify a custom profile and path
config = ExOciSdk.Config.from_file!("/custom/path/config", "CUSTOM_PROFILE")
```

Your config file (`~/.oci/config`) should look like:
```ini
[DEFAULT]
user=ocid1.user.oc1..example
fingerprint=20:3b:97:13:55:1c:ef:3d:bb:04:28:cc:7e:00:5b:12
tenancy=ocid1.tenancy.oc1..example
region=sa-saopaulo-1
key_file=~/.oci/oci_api_key.pem
```

#### Profile Management

You can maintain multiple profiles in your config file:

```ini
[DEFAULT]
# Default profile settings...

[PROD]
# Production settings...

[DEV]
# Development settings...
```

Switch between profiles:
```elixir
prod_config = ExOciSdk.Config.from_file!(profile: "PROD")
dev_config = ExOciSdk.Config.from_file!(profile: "DEV")
```

### Method 2: From runtime environments (recommended for production)

This method allows you to configure OCI credentials through your Elixir application's runtime configuration.

```elixir
# Load configuration from application environment
config = ExOciSdk.Config.from_runtime!()
```

#### Setting Up Runtime Configuration

Add your OCI configuration to `config/runtime.exs`

```elixir
# config/runtime.exs
import Config

config :ex_oci_sdk,
  user: System.get_env("OCI_USER_OCID"),
  fingerprint: System.get_env("OCI_KEY_FINGERPRINT"),
  tenancy: System.get_env("OCI_TENANCY_OCID"),
  region: System.get_env("OCI_REGION") || "sa-saopaulo-1",
  key_file: System.get_env("OCI_PRIVATE_KEY_PATH") || "~/.oci/oci_api_key.pem"
```

Alternatively, you can provide the key content directly:

```elixir
# config/runtime.exs
import Config

config :ex_oci_sdk,
  user: System.get_env("OCI_USER_OCID"),
  fingerprint: System.get_env("OCI_KEY_FINGERPRINT"),
  tenancy: System.get_env("OCI_TENANCY_OCID"),
  region: System.get_env("OCI_REGION") || "sa-saopaulo-1",
  key_content: System.get_env("OCI_PRIVATE_KEY_CONTENT")
```


### Method 3: Direct Configuration

For more control or development suits, you can configure directly (be careful not to expose the private key):

```elixir
# Using key content directly
config = ExOciSdk.Config.new!(%{
  user: "ocid1.user.oc1..example",
  fingerprint: "20:3b:97:13:55:1c:ef:3d:bb:04:28:cc:7e:00:5b:12",
  tenancy: "ocid1.tenancy.oc1..example",
  region: "sa-saopaulo-1",
  key_content: "-----BEGIN PRIVATE KEY-----\n..."
})

# Or using a key file path
config = ExOciSdk.Config.new!(%{
  user: "ocid1.user.oc1..example",
  fingerprint: "20:3b:97:13:55:1c:ef:3d:bb:04:28:cc:7e:00:5b:12",
  tenancy: "ocid1.tenancy.oc1..example",
  region: "sa-saopaulo-1",
  key_file: "~/.oci/oci_api_key.pem"
})
```

## Important Tips

- Keep your private key in a secure location and never share it
- Never expose your private key in your code
- If you suspect your private key has been compromised, immediately delete it from the OCI Console to prevent unauthorized access
