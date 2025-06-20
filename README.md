<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI/ML landing zone which supports multiple ai project scenarios.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_vnet_definition"></a> [vnet\_definition](#input\_vnet\_definition)

Description: n/a

Type:

```hcl
object({
    name          = optional(string)
    address_space = string
    enable_ddos   = optional(bool, false)
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      dns_servers    = optional(list(string))
      }
    )), {})
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_bastion_definition"></a> [bastion\_definition](#input\_bastion\_definition)

Description: n/a

Type:

```hcl
object({
    name  = optional(string)
    sku   = optional(string, "Standard")
    tags  = optional(map(string), {})
    zones = optional(list(string), ["1", "2", "3"])
  })
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_firewall_definition"></a> [firewall\_definition](#input\_firewall\_definition)

Description: n/a

Type:

```hcl
object({
    name  = optional(string)
    sku   = optional(string, "AZFW_VNet")
    tier  = optional(string, "Standard")
    zones = optional(list(string), ["1", "2", "3"])
    tags  = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_flag_platform_landing_zone"></a> [flag\_platform\_landing\_zone](#input\_flag\_platform\_landing\_zone)

Description: Flag to indicate if the platform landing zone is enabled. If true, the module will deploy resources in a platform landing zone.

Type: `bool`

Default: `true`

### <a name="input_law_definition"></a> [law\_definition](#input\_law\_definition)

Description: Definition of the Log Analytics Workspace to be created.

Type:

```hcl
object({
    name      = optional(string)
    retention = optional(number, 30)
    sku       = optional(string, "PerGB2018")
    tags      = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix)

Description: Optional Prefix to be used for naming resources. This is useful for ensuring standard naming without requiring a name input for each name.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to be assigned to this resource

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_subnets"></a> [subnets](#output\_subnets)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_ai_lz_vnet"></a> [ai\_lz\_vnet](#module\_ai\_lz\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: =0.7.1

### <a name="module_azure_bastion"></a> [azure\_bastion](#module\_azure\_bastion)

Source: Azure/avm-res-network-bastionhost/azurerm

Version: 0.7.2

### <a name="module_firewall"></a> [firewall](#module\_firewall)

Source: Azure/avm-res-network-azurefirewall/azurerm

Version: 0.3.0

### <a name="module_firewall_policy"></a> [firewall\_policy](#module\_firewall\_policy)

Source: Azure/avm-res-network-firewallpolicy/azurerm

Version: 0.3.3

### <a name="module_firewall_route_table"></a> [firewall\_route\_table](#module\_firewall\_route\_table)

Source: Azure/avm-res-network-routetable/azurerm

Version: 0.4.1

### <a name="module_fw_pip"></a> [fw\_pip](#module\_fw\_pip)

Source: Azure/avm-res-network-publicipaddress/azurerm

Version: 0.2.0

### <a name="module_log_analytics_workspace"></a> [log\_analytics\_workspace](#module\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.4.2

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->