locals {
  paired_region = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(azapi_resource.this.location) || (lower(region.display_name) == lower(azapi_resource.this.location)))][0].paired_region_name
  #paired_region_zones        = local.paired_region_zones_lookup != null ? local.paired_region_zones_lookup : []
  #paired_region_zones_lookup = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(local.paired_region) || (lower(region.display_name) == lower(local.paired_region)))][0].zones
  region_zones        = local.region_zones_lookup != null ? local.region_zones_lookup : []
  region_zones_lookup = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(azapi_resource.this.location) || (lower(region.display_name) == lower(azapi_resource.this.location)))][0].zones
  tags                = var.tags != null ? var.tags : {}
}
