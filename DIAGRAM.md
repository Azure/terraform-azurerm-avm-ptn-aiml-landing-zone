# Code References and Usage Diagram

```mermaid
graph TD
    subgraph Monitoring ["Monitoring & Logging"]
        LAW[Log Analytics Workspace<br/>(avm-res-operationalinsights-workspace)]
    end

    subgraph Networking ["Networking Core"]
        VNet[Virtual Network<br/>(avm-res-network-virtualnetwork)]
        NSG[NSGs<br/>(avm-res-network-networksecuritygroup)]
        PDNS[Private DNS Zones<br/>(avm-res-network-privatednszone)]
        Peering[Hub Peering<br/>(avm-res-network-virtualnetwork)]

        VNet --> NSG
        VNet --> Peering
        PDNS -.-> VNet
    end

    subgraph NetworkSecurity ["Network Security & Access"]
        Firewall[Azure Firewall<br/>(avm-res-network-azurefirewall)]
        AppGw[Application Gateway<br/>(avm-res-network-applicationgateway)]
        WAF[WAF Policy<br/>(avm-res-network-appgw-waf-policy)]
        Bastion[Azure Bastion<br/>(avm-res-network-bastionhost)]

        Firewall --> VNet
        AppGw --> VNet
        AppGw --> WAF
        Bastion --> VNet
    end

    subgraph DataStorage ["Data & Storage"]
        KV[Key Vault<br/>(avm-res-keyvault-vault)]
        Cosmos[Cosmos DB<br/>(avm-res-documentdb-databaseaccount)]
        Storage[Storage Account<br/>(avm-res-storage-storageaccount)]
        ACR[Container Registry<br/>(avm-res-containerregistry-registry)]
        AppConfig[App Configuration<br/>(avm-res-appconfiguration-configurationstore)]

        KV --> VNet
        Cosmos --> VNet
        Storage --> VNet
        ACR --> VNet
        AppConfig --> VNet
    end

    subgraph AIServices ["AI Services"]
        Foundry[AI Foundry Pattern<br/>(avm-ptn-aiml-ai-foundry)]
        Search[AI Search<br/>(avm-res-search-searchservice)]
        Bing[Bing Grounding<br/>(azapi_resource)]

        Foundry --> Hub[AI Hub]
        Foundry --> Project[AI Projects]
        Foundry --> Models[Model Deployments]

        Foundry --> Storage
        Foundry --> KV
        Foundry --> ACR
        Foundry --> Search
        Foundry --> Cosmos

        Search --> VNet
    end

    subgraph Compute ["Compute Resources"]
        CAE[Container Apps Env<br/>(avm-res-app-managedenvironment)]
        JumpVM[Jump VM<br/>(avm-res-compute-virtualmachine)]
        BuildVM[Build VM<br/>(avm-res-compute-virtualmachine)]

        CAE --> VNet
        JumpVM --> VNet
        BuildVM --> VNet

        JumpVM --> KV
        BuildVM --> KV
    end

    subgraph Management ["Management"]
        APIM[API Management<br/>(avm-res-apimanagement-service)]
        APIM --> VNet
    end

    %% Diagnostics Connections
    VNet -.-> LAW
    Firewall -.-> LAW
    AppGw -.-> LAW
    KV -.-> LAW
    Cosmos -.-> LAW
    Storage -.-> LAW
    ACR -.-> LAW
    Search -.-> LAW
    CAE -.-> LAW
    APIM -.-> LAW

    classDef module fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef resource fill:#fff3e0,stroke:#e65100,stroke-width:2px;

    class VNet,NSG,PDNS,Peering,Firewall,AppGw,WAF,Bastion,KV,Cosmos,Storage,ACR,AppConfig,Foundry,Search,CAE,JumpVM,BuildVM,APIM,LAW module;
    class Hub,Project,Models,Bing resource;
```
