# Azure AI/ML Landing Zone Pattern Module - Architecture Diagram

## Overall Landing Zone Architecture

```mermaid
graph TB
    subgraph External["External Access"]
        USERS["End Users"]
        ADMINS["Administrators"]
    end

    subgraph Edge["Edge & Access Layer"]
        APPGW["Application Gateway<br/>v2 WAF"]
        BASTION["Bastion Host<br/>Secure RDP/SSH"]
    end

    subgraph APILayer["API & Integration Layer"]
        APIM["API Management<br/>API Gateway & Portal"]
        ACR["Container Registry<br/>Image Repository"]
    end

    subgraph Compute["Compute & Orchestration"]
        CAE["Container App Environment<br/>Kubernetes-like"]
        JUMPVM["Jump VM"]
        BUILDVM["Build VM"]
    end

    subgraph AIFoundry["AI Foundry"]
        HUB["AI Foundry Account<br/>(Central Management)"]
        PROJ1["AI Project 1"]
        PROJ2["AI Project 2"]
        AGENT["AI Agent Service"]
    end

    subgraph DataServices["Data & Knowledge Services"]
        AISEARCH["AI Search<br/>(Full-text & Vector)"]
        COSMOS["Cosmos DB<br/>(NoSQL)"]
        BING["Bing Grounding<br/>(Grounded Answers)"]
    end

    subgraph DataStorage["Storage & Secrets"]
        SA["Storage Account<br/>(Blob/File/Queue)"]
        KV["Key Vault<br/>(Secrets & Encryption)"]
        LAW["Log Analytics Workspace<br/>(Monitoring)"]
    end

    subgraph Network["Network Infrastructure"]
        VNET["Virtual Network<br/>192.168.0.0/20"]

        subgraph Subnets["Subnet Tiers"]
            GWESUBNET["Gateway Subnet<br/>(App Gateway)"]
            CASUBNET["Container App Subnet"]
            BASTIONSUBNET["Bastion Subnet"]
            VMSUBNET["VM Subnet"]
            PESUBNET["Private Endpoint Subnet"]
        end

        subgraph Security["Network Security"]
            NSG["Network Security Groups"]
            FW["Azure Firewall<br/>(Optional)"]
            PDNS["Private DNS Zones"]
        end
    end

    subgraph Management["Management & Monitoring"]
        CONFIG["App Configuration<br/>Settings & Feature Flags"]
        DIAG["Diagnostic Settings"]
        POLICY["WAF Policy<br/>Security Rules"]
    end

    subgraph Integration["Integration & Connectivity"]
        VWAN["Virtual WAN Hub<br/>(Optional - Platform LZ)"]
        PEERING["VNet Peering<br/>(Optional)"]
    end

    %% External connections
    USERS --> APPGW
    ADMINS --> BASTION

    %% Edge layer
    APPGW --> APIM
    BASTION --> JUMPVM
    APIM --> CAE

    %% API & Container layer
    ACR --> CAE
    CAE --> AISEARCH
    CAE --> COSMOS
    CAE --> SA
    CAE --> KV

    %% AI Foundry connections
    HUB --> PROJ1
    HUB --> PROJ2
    PROJ1 --> AISEARCH
    PROJ1 --> COSMOS
    PROJ2 --> AISEARCH
    PROJ2 --> COSMOS

    %% Knowledge services
    AISEARCH --> BING
    COSMOS --> BING

    %% Networking
    APPGW -.->|Deployed in| GWESUBNET
    CAE -.->|Deployed in| CASUBNET
    BASTION -.->|Deployed in| BASTIONSUBNET
    JUMPVM -.->|Deployed in| VMSUBNET
    AISEARCH -.->|PE in| PESUBNET
    COSMOS -.->|PE in| PESUBNET
    SA -.->|PE in| PESUBNET
    KV -.->|PE in| PESUBNET

    VNET --> Subnets
    VNET --> Security
    PDNS -.->|DNS| AISEARCH
    PDNS -.->|DNS| COSMOS
    PDNS -.->|DNS| SA
    PDNS -.->|DNS| KV

    %% Management
    APPGW --> POLICY
    AISEARCH --> DIAG
    COSMOS --> DIAG
    SA --> DIAG
    KV --> DIAG
    CAE --> CONFIG
    CAE --> LAW

    %% Integration
    VNET -.->|Peers with| PEERING
    VNET -.->|Connects to| VWAN

    style External fill:#E8D999,stroke:#A89A5C,color:#000
    style Edge fill:#8BA882,stroke:#556B4D,color:#fff
    style APILayer fill:#A68BB8,stroke:#6B5A7B,color:#fff
    style Compute fill:#C9A4A4,stroke:#8B6666,color:#fff
    style AIFoundry fill:#8BA5C7,stroke:#5A7A99,color:#fff
    style DataServices fill:#D9B0B3,stroke:#8B6666,color:#fff
    style DataStorage fill:#A68BB8,stroke:#6B5A7B,color:#fff
    style Network fill:#8BA882,stroke:#556B4D,color:#fff
    style Management fill:#C9A678,stroke:#8B6F47,color:#fff
    style Integration fill:#DDD4C4,stroke:#888,color:#000
```

## Deployment ComponentBreakdown

```mermaid
graph TB
    subgraph LZA["AI/ML LZ Components"]

        subgraph NetComp["Network Components"]
            VN["VNet<br/>Address Space: 192.168.0.0/20"]
            RF["Route Tables<br/>Firewall Routing"]
            NSG1["NSG: Management"]
            NSG2["NSG: Container Apps"]
            NSG3["NSG: VM Subnet"]
        end

        subgraph EdgeComp["Edge & Gateway"]
            WF["Azure Firewall<br/>(Optional - PLZ Integration)"]
            WAF["WAF Policy<br/>OWASP Protection"]
            AG["App Gateway v2<br/>Layer 7 Load Balancing"]
        end

        subgraph APIComp["API & Container"]
            APIM["API Management<br/>Standard/Premium"]
            ACR["Container Registry<br/>Premium for Private Link"]
            CAE["Container App Environment"]
        end

        subgraph AIComp["AI & Data"]
            AIH["AI Foundry Account<br/>Central Management"]
            AIP["AI Projects<br/>Development Workspaces"]
            AIS["AI Search<br/>Vector + Full-text"]
            COSMOSDB["Cosmos DB<br/>Multi-region Capable"]
            BING["Bing Grounding<br/>Web Context"]
        end

        subgraph StorageComp["Storage & Security"]
            ST["Storage Account<br/>ZRS Replication"]
            KVT["Key Vault<br/>Standard Tier"]
            CONF["App Configuration<br/>Standard"]
        end

        subgraph ComputeComp["Compute Resources"]
            BVVM["Build VM<br/>Build Agent Host"]
            JVVM["Jump VM<br/>Admin Access"]
            BASTNHOST["Bastion Host<br/>Secure Access"]
        end

        subgraph ObsComp["Observability"]
            LAWSP["Log Analytics<br/>30-day Retention"]
            DIAGSET["Diagnostic Settings<br/>All Services"]
        end
    end

    style NetComp fill:#8BA882,color:#fff
    style EdgeComp fill:#C9A4A4,color:#fff
    style APIComp fill:#A68BB8,color:#fff
    style AIComp fill:#8BA5C7,color:#fff
    style StorageComp fill:#A68BB8,color:#fff
    style ComputeComp fill:#D4B896,color:#fff
    style ObsComp fill:#C9A678,color:#000
```

## Networking Architecture

```mermaid
graph TB
    subgraph Internet["Internet"]
        EXTERNAL["External Traffic"]
    end

    subgraph HubSpoke["Platform Landing Zone"]
        PLZHUB["PLZ Hub VNet"]
        PLZFW["Firewall"]
    end

    subgraph AILZ["AI/ML Landing Zone"]
        VNET["AI LZ VNet"]

        subgraph GW["Gateway Subnet"]
            APPGW["App Gateway"]
            WAF["WAF Policy"]
        end

        subgraph CASubnet["Container App Subnet"]
            CAE["Container App<br/>Environment"]
        end

        subgraph BasSubnet["Bastion Subnet"]
            BASTION["Bastion Host"]
        end

        subgraph VMSubnet["VM Subnet"]
            JUMPVM["Jump VM"]
            BUILDVM["Build VM"]
        end

        subgraph PESubnet["PE Subnet<br/>192.168.4.0/27"]
            PE1["PE: AI Foundry"]
            PE2["PE: Key Vault"]
            PE3["PE: Storage"]
            PE4["PE: AI Search"]
            PE5["PE: Cosmos DB"]
        end

        VNET --> GW
        VNET --> CASubnet
        VNET --> BasSubnet
        VNET --> VMSubnet
        VNET --> PESubnet
    end

    subgraph PrivateLinkServices["Private Link Services"]
        AIH["AI Foundry<br/>Private Endpoint"]
        KVH["Key Vault<br/>Private Endpoint"]
        SAH["Storage Account<br/>Private Endpoint"]
        AISH["AI Search<br/>Private Endpoint"]
        COSMOSH["Cosmos DB<br/>Private Endpoint"]
    end

    subgraph PDNS["Private DNS Zones"]
        PDNSAI["privatelink.cognitiveservices.azure.com"]
        PDNSKV["privatelink.vaultcore.azure.net"]
        PDNSSA["privatelink.blob.core.windows.net"]
        PDNSAIS["privatelink.search.windows.net"]
        PDNSCOSMOS["privatelink.documents.azure.com"]
    end

    EXTERNAL --> APPGW
    APPGW --> BASTION
    BASTION --> JUMPVM
    JUMPVM --> CAE
    CAE --> PE1
    CAE --> PE2
    CAE --> PE3
    CAE --> PE4
    CAE --> PE5

    PE1 --> AIH
    PE2 --> KVH
    PE3 --> SAH
    PE4 --> AISH
    PE5 --> COSMOSH

    AIH -.->|DNS| PDNSAI
    KVH -.->|DNS| PDNSKV
    SAH -.->|DNS| PDNSSA
    AISH -.->|DNS| PDNSAIS
    COSMOSH -.->|DNS| PDNSCOSMOS

    PLZFW -.->|Optional| VNET

    style Internet fill:#E8D999,stroke:#A89A5C,color:#000
    style AILZ fill:#F5F5F5,stroke:#888,color:#000
    style HubSpoke fill:#CCC,stroke:#999,color:#000
    style GW fill:#8BA882,color:#fff
    style CASubnet fill:#C9A4A4,color:#fff
    style BasSubnet fill:#D4B896,color:#000
    style VMSubnet fill:#D4B896,color:#000
    style PESubnet fill:#A68BB8,color:#fff
    style PrivateLinkServices fill:#8BA5C7,color:#fff
    style PDNS fill:#D9B0B3,color:#000
```

## AI Services Architecture

```mermaid
graph TB
    subgraph AICore["🔵 AI Foundry Core"]
        HUB["AI Foundry Account<br/>- Project Management<br/>- Model Catalog<br/>- Deployment Control"]

        P1["Project 1<br/>Development"]
        P2["Project 2<br/>Development"]
        P3["Project N<br/>Development"]
    end

    subgraph AICapabilities["Project Capabilities"]
        AGENTS["AI Agents<br/>Autonomous Actions"]
        PROMPT["Prompt Flow<br/>LLM Orchestration"]
        EVAL["Evaluation<br/>Quality Assessment"]
        DEPLOY["Model Deployment<br/>Inference Endpoints"]
    end

    subgraph KnowledgeServices["Knowledge & Grounding"]
        CON["Connections<br/>to Data Sources"]

        KB["Knowledge Bases<br/>Stored in Storage"]
        VS["Vector Stores<br/>Embedded Data"]

        AISEARCH["AI Search Index<br/>- Semantic Search<br/>- Vector Search<br/>- Hybrid"]

        BING["Bing Grounding<br/>Web Context"]
    end

    subgraph DataSources["🟣 Data & Storage"]
        SA["Storage Account<br/>- Documents<br/>- Models<br/>- Artifacts"]
        COSMOS["Cosmos DB<br/>- Session Data<br/>- Custom Stores<br/>- Metadata"]
        KV["Key Vault<br/>- API Keys<br/>- Secrets<br/>- Model Keys"]
    end

    subgraph Inference["Model Inference"]
        DEPLOY_MODELS["Deployed Models<br/>- GPT-4o<br/>- Custom Models<br/>- Fine-tuned"]
        ENDPOINTS["API Endpoints<br/>REST/Stream"]
    end

    HUB --> P1
    HUB --> P2
    HUB --> P3

    P1 --> AGENTS
    P1 --> PROMPT
    P1 --> EVAL
    P1 --> DEPLOY

    P1 --> CON
    CON --> KB
    CON --> VS
    CON --> AISEARCH
    AISEARCH --> BING

    KB --> SA
    VS --> SA
    COSMOS --> CON
    KV --> CON

    DEPLOY --> DEPLOY_MODELS
    DEPLOY_MODELS --> ENDPOINTS
    ENDPOINTS --> AISEARCH
    ENDPOINTS --> COSMOS

    style AICore fill:#8BA5C7,color:#fff
    style AICapabilities fill:#A68BB8,color:#fff
    style KnowledgeServices fill:#D9B0B3,color:#000
    style DataSources fill:#A68BB8,color:#fff
    style Inference fill:#D4B896,color:#000
```

## Deployment Phases

```mermaid
graph LR
    Start["🚀 Start Deployment"]

    P1["Phase 1<br/>Networking<br/>- VNet<br/>- Subnets<br/>- NSGs"]

    P2["Phase 2<br/>Gateway Layer<br/>- App Gateway<br/>- WAF Policy<br/>- Firewall"]

    P3["Phase 3<br/>AI Platform<br/>- AI Hub<br/>- AI Projects<br/>- Agent Service"]

    P4["Phase 4<br/>Data Services<br/>- AI Search<br/>- Cosmos DB<br/>- Storage"]

    P5["Phase 5<br/>Compute<br/>- Container Apps<br/>- VMs<br/>- Bastion"]

    P6["Phase 6<br/>Integration<br/>- API Management<br/>- Container Registry<br/>- Connections"]

    P7["Phase 7<br/>Monitoring<br/>- Log Analytics<br/>- Diagnostics<br/>- Alerts"]

    End["✅ Deployment Complete"]

    Start --> P1
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5
    P5 --> P6
    P6 --> P7
    P7 --> End

    style P1 fill:#8BA882,color:#fff
    style P2 fill:#C9A4A4,color:#fff
    style P3 fill:#8BA5C7,color:#fff
    style P4 fill:#D9B0B3,color:#000
    style P5 fill:#D4B896,color:#000
    style P6 fill:#A68BB8,color:#fff
    style P7 fill:#C9A678,color:#000
```

##Configuration Scenarios

### Scenario 1: StandaloneAI Foundry Only

```mermaid
graph TB
    VN["VNet<br/>Simple Configuration"]
    AF["AI Foundry<br/>Default Settings"]
    PROJ["AI Projects<br/>Public Access"]
    LAW["Log Analytics<br/>Basic Monitoring"]

    VN --> AF
    AF --> PROJ
    PROJ --> LAW
```

### Scenario 2: Enterprise Full Stack

```mermaid
graph TB
    FW["Firewall<br/>Network Protection"]
    AG["App Gateway<br/>Public Endpoint"]
    APIM["API Management<br/>API Portal"]
    CAE["Container Apps<br/>Workload Hosting"]
    AIH["AI Foundry<br/>With Agent Service"]
    KB["Knowledge Services<br/>AI Search + Cosmos"]
    ACR["Container Registry<br/>Image Management"]

    FW --> AG
    AG --> APIM
    APIM --> CAE
    CAE --> AIH
    CAE --> KB
    APIM --> ACR

    style FW fill:#C9A4A4,color:#fff
    style AG fill:#8BA882,color:#fff
    style APIM fill:#A68BB8,color:#fff
    style CAE fill:#D4B896,color:#000
    style AIH fill:#8BA5C7,color:#fff
    style KB fill:#D9B0B3,color:#000
    style ACR fill:#A68BB8,color:#fff
```

## Key Design Decisions

| Component | Standard Pattern | Enterprise Pattern |
|-----------|------------------|-------------------|
| **Network** | Simple VNet | VNet w/ Multiple Subnets + Firewall |
| **Ingress** | App Gateway | App Gateway + WAF + API Management |
| **AI Foundry** | Project-only | Hub + Multiple Projects + Agents |
| **Data** | Storage Account | Cosmos DB + AI Search + BING |
| **Access** | Public Endpoints | Private Endpoints + Bastion |
| **Security** | Network ACLs | Full Zero-Trust with CMK |
| **Monitoring** | Log Analytics | LAW + Diagnostics + Alerts |
| **Compute** | VMs Optional | Container Apps + VMs + Bastion |

## Related Modules

- **terraform-azurerm-avm-ptn-aiml-ai-foundry**: AI Foundry account and project management
- **Example Deployments**:
  - `default/` - Standard LZ setup
  - `default-byo-vnet/` - Bring your own VNet
  - `standalone/` - Single dedicated deployment
  - `standalone-byo-vnet/` - Standalone with external network

## Documentation References

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [AI/ML Landing Zone Accelerator](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
