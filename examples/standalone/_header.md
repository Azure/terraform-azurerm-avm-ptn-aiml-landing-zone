# Standalone example

This example demonstrates a configuration when the platform landing zone flag is set to false.  In this case, all supporting services are included as part of AI landing zone deployment.

The example omits `application_platform.container_apps[*].workload_profile_name`, so the Container App keeps the existing Consumption-profile behavior. For a dedicated-only environment, define the dedicated profile in `container_app_environment_definition.workload_profile` and set the Container App's `workload_profile_name` to the same profile name.
