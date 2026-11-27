mock_provider "azapi" {}

run "creates_managed_nat_gateway_with_public_ip" {
  command = apply

  variables {
    idle_timeout_in_minutes = 10
    location                = "eastus"
    name                    = "nat-unit-test"
    parent_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
    public_ip_name          = "nat-unit-test-pip"
    retry = {
      error_message_regex = ["RetryableError"]
      interval_seconds    = 5
    }
    tags = {
      environment = "unit"
    }
    timeouts = {
      create = "30m"
      delete = "30m"
    }
  }

  assert {
    condition     = azapi_resource.public_ip.name == "nat-unit-test-pip"
    error_message = "The managed public IP must preserve the configured naming convention."
  }

  assert {
    condition     = azapi_resource.public_ip.body.sku.name == "Standard" && azapi_resource.public_ip.body.properties.publicIPAllocationMethod == "Static"
    error_message = "The managed public IP must be Standard and statically allocated."
  }

  assert {
    condition     = azapi_resource.public_ip.tags.environment == "unit"
    error_message = "The managed public IP must receive the configured tags."
  }

  assert {
    condition     = azapi_resource.this.body.properties.idleTimeoutInMinutes == 10 && azapi_resource.this.body.sku.name == "Standard"
    error_message = "The managed NAT Gateway must preserve the configured timeout and Standard SKU."
  }

  assert {
    condition     = azapi_resource.this.body.zones == null && length(azapi_resource.public_ip.body.zones) == 3 && alltrue([for zone in ["1", "2", "3"] : contains(azapi_resource.public_ip.body.zones, zone)])
    error_message = "The Standard NAT Gateway must default to no explicit zone and its Standard public IP must default to zone redundancy."
  }

  assert {
    condition     = azapi_resource.this.body.properties.publicIpAddresses[0].id == azapi_resource.public_ip.id
    error_message = "The NAT Gateway must associate its managed public IP address."
  }

  assert {
    condition     = length(azapi_resource.this.retry.error_message_regex) == 1 && azapi_resource.this.retry.error_message_regex[0] == "RetryableError"
    error_message = "Consumer retry settings must reach the NAT Gateway AzAPI resource."
  }

  assert {
    condition     = output.resource_id == azapi_resource.this.id
    error_message = "The focused submodule must export the managed NAT Gateway resource ID."
  }
}

run "creates_single_zone_standard_nat_gateway" {
  command = plan

  variables {
    location       = "eastus"
    name           = "nat-unit-test"
    parent_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
    public_ip_name = "nat-unit-test-pip"
    zones          = ["1"]
  }

  assert {
    condition     = azapi_resource.this.body.sku.name == "Standard" && azapi_resource.this.body.zones[0] == "1" && azapi_resource.public_ip.body.zones[0] == "1"
    error_message = "The module must place both Standard resources in the one explicitly configured availability zone."
  }
}

run "rejects_multiple_standard_nat_gateway_zones" {
  command = plan

  variables {
    location       = "eastus"
    name           = "nat-unit-test"
    parent_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
    public_ip_name = "nat-unit-test-pip"
    zones          = ["1", "2"]
  }

  expect_failures = [var.zones]
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    location       = "eastus"
    name           = "nat-unit-test"
    parent_id      = "/not/a/resource/group"
    public_ip_name = "nat-unit-test-pip"
  }

  expect_failures = [var.parent_id]
}

run "rejects_invalid_idle_timeout" {
  command = plan

  variables {
    idle_timeout_in_minutes = 3
    location                = "eastus"
    name                    = "nat-unit-test"
    parent_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
    public_ip_name          = "nat-unit-test-pip"
  }

  expect_failures = [var.idle_timeout_in_minutes]
}
