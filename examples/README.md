# Examples

- Create a directory for each example.
- Create a `_header.md` file in each directory to describe the example.
- See the `default` example provided as a skeleton - this must remain, but you can add others.
- Run `make fmt && make docs` from the repo root to generate the required documentation.
- If you want an example to be ignored by the end to end pipeline add a `.e2eignore` file to the example directory.

## Application Gateway v2 Internet Routing

The `standalone` example demonstrates the use of the `use_internet_routing` variable which enables direct internet routing instead of firewall routing when `flag_platform_landing_zone = true`. This is particularly useful for Azure Application Gateway v2 deployments that require direct internet connectivity and cannot use virtual appliance routing.

> **Note:** Examples must be deployable and idempotent. Ensure that no input variables are required to run the example and that random values are used to ensure unique resource names. E.g. use the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) to generate a unique name for a resource.
