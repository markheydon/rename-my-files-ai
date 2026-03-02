# ADR-0003: Use GlobalStandard Deployment Type for Azure OpenAI

**Status:** Accepted

**Date:** 2026-02-25

**Authors:** Mark Heydon

---

## Context

When deploying Azure OpenAI models, Microsoft offers multiple deployment types with different data processing characteristics:

- **Global deployment types** (GlobalStandard, GlobalProvisioned, GlobalBatch): Data may be processed in any Azure region where the model is deployed
- **DataZone deployment types** (DataZoneStandard, DataZoneProvisioned, DataZoneBatch): Data processed only within specified data zones (US or EU)
- **Regional deployment types** (Standard, ProvisionedManaged): Data processed only in the specified region

We needed to deploy `gpt-4o-mini` in the `uksouth` region for this utility. During testing, we discovered that:

1. The `gpt-4o-mini` model is **not available** with the regional `Standard` SKU in `uksouth`
2. The `gpt-4o-mini` model **is available** with `GlobalStandard` in `uksouth` (and also in EU/US DataZone types)
3. `GlobalStandard` is approximately **10% cheaper** than `Standard` ($0.15 input / $0.60 output per 1M tokens vs. $0.165 / $0.66)

This forced a choice between:
- **Option A**: Use `GlobalStandard` (globally distributed, higher availability, lower cost)
- **Option B**: Switch to `DataZoneStandard` with EU data zone compliance
- **Option C**: Change regions to one that supports `Standard` SKU with `gpt-4o-mini`

### Data Processing Reality

According to [Microsoft's official deployment types documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/deployment-types?view=foundry-classic):

> "For Global deployment types, prompts and responses might be processed in any geography where the model is deployed."

**What this means:**
- **At rest:** File contents remain in the Azure region you specify during resource creation
- **In transit (during processing):** File contents (prompts) and AI-generated responses can be processed in **any Azure region globally** where `gpt-4o-mini` is available
- **Not sent elsewhere:** Data is not sent to third parties; it remains within Microsoft Azure infrastructure
- **Duration:** Processing data is retained only for the duration of the API call

---

## Decision

**We chose `GlobalStandard` deployment type for the Azure OpenAI resource.**

This decision prioritizes:
1. **Model availability** - `gpt-4o-mini` required for cost-effective file renaming
2. **Cost efficiency** - 10% savings over alternative SKUs
3. **User flexibility** - Deployment works in any Azure region with `GlobalStandard` availability

**Critical requirement:** Users must explicitly acknowledge the data processing implications before using this utility, especially if they have strict data residency requirements.

---

## Consequences

### Positive Outcomes

1. **Model availability achieved** - `gpt-4o-mini` is now deployable in `uksouth` and other regions
2. **Cost reduction** - 10% cheaper than alternative SKUs ($0.15 vs $0.165 per 1M input tokens)
3. **Broader regional support** - `GlobalStandard` available in 40+ Azure regions vs. limited `Standard` availability for some models
4. **Higher default quotas** - `GlobalStandard` provides 200,000 tokens/minute vs. regional limits
5. **Global redundancy** - Traffic dynamically routed to available datacenters for resilience
6. **No data lock-in** - Users not restricted to single Azure region

### Trade-offs & Mitigations

1. **Data may be processed globally (NOT regionally stored)**
   - *Mitigation:* Documentation must clearly explain this to users
   - *Mitigation:* Prominent warning in user guide and deployment instructions
   - *Mitigation:* Clear guidance on `DataZoneStandard` alternative for EU/US compliance requirements

2. **Users with strict data residency requirements must use `DataZoneStandard` instead**
   - *Mitigation:* Document alternative deployment types
   - *Mitigation:* Provide guidance on when to use each deployment type
   - *Mitigation:* Consider providing deployment option in future versions

3. **Potential latency variance at high volume**
   - *Mitigation:* This utility processes files interactively (not high-volume batch), so impact is minimal
   - *Mitigation:* For production bulk processing, DataZone or Provisioned alternatives are available

---

## Alternatives Considered

### 1. DataZoneStandard (EU or US data zone)

**Description:** Process data only within EU member nations or US; maintains data zone compliance

**Pros:**
- ✅ Strict data residency guarantee (EU or US only)
- ✅ Same model availability as GlobalStandard
- ✅ Similar pricing to GlobalStandard

**Cons:**
- ❌ Requires users to explicitly choose EU or US data zone at deployment time
- ❌ Less flexible for international teams
- ❌ Adds complexity for users unfamiliar with data residency concepts
- ❌ Complicates documentation (must explain which data zone to use)

**Decision:** Rejected because this utility aims for simplicity; however, documented as recommended alternative for users with EU/US compliance requirements.

### 2. Regional Standard SKU in Alternative Region

**Description:** Deploy to a region where regional `Standard` SKU supports `gpt-4o-mini` (e.g., `eastus2`, `swedencentral`)

**Pros:**
- ✅ Strict single-region data processing
- ✅ Simpler mental model for data residency

**Cons:**
- ❌ Breaks user requirement to deploy in `uksouth`
- ❌ Forces geographic constraints on infrastructure
- ❌ Limits utility's geographic flexibility
- ❌ Conflicts with stated design goal of region flexibility

**Decision:** Rejected because user specifically wanted `uksouth` deployment, and GlobalStandard is available there.

### 3. Stick with Standard SKU + Limited Model Set

**Description:** Accept that `gpt-4o-mini` is unavailable and use older/different models in regional `Standard` SKU

**Pros:**
- ✅ Strict regional data processing
- ✅ Regional compliance guarantee

**Cons:**
- ❌ Requires different (likely more expensive or less capable) model
- ❌ Increases operational costs
- ❌ Reduces quality of file renaming suggestions
- ❌ Works against goal of cost-effective utility

**Decision:** Rejected because capability and cost requirements take priority.

---

## Implementation Details

### Bicep Configuration

```bicep
resource cognitiveServicesDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = {
  parent: cognitiveServicesAccount
  name: modelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    scaleSettings: {
      scaleType: 'Standard'
      capacity: 10
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
  sku: {
    name: 'GlobalStandard'  // ← This is the critical setting
    capacity: 10
  }
}
```

### Deployment Command

```powershell
az deployment group create \
  --resource-group $resourceGroupName \
  --template-file infra/main.bicep \
  --parameters location=$location modelDeploymentName=gpt-4o-mini-rmf
```

### Official Region Availability

`GlobalStandard` deployment type is available in 40+ regions including:
- UK South (`uksouth`)
- Sweden Central (`swedencentral`)
- East US 2 (`eastus2`)
- France Central (`francecentral`)
- And many others

See [Microsoft Foundry Models availability](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic#foundry-models-sold-directly-by-azure) for complete list.

---

## Data Residency Guidance for Users

### ⚠️ Important: Data Processing Locations

**Rename My Files uses Azure OpenAI with GlobalStandard deployment type.**

This means:

| Aspect | Behaviour |
|--------|----------|
| **File content at rest** | Stays in your Azure region (e.g., `uksouth`) |
| **File content during processing** | May be sent to any Azure region where the model is deployed |
| **Duration** | Milliseconds (only during the API call) |
| **Storage** | Not stored after processing completes |
| **Third parties** | Data remains within Azure; not shared with third parties |

### For Compliance-Sensitive Organisations

If your organisation requires:
- **All processing within EU:** Use `DataZoneStandard` in `francecentral` or other EU region
- **All processing within US:** Use `DataZoneStandard` in `eastus2` or other US region
- **Single-region processing:** Use regional `Standard` SKU in regions that support `gpt-4o-mini`

Contact your Azure administrator or review [Azure data residency](https://azure.microsoft.com/explore/global-infrastructure/data-residency/) for organisational policies.

### For Most Users

`GlobalStandard` provides:
- ✅ Good availability in your preferred region
- ✅ Lower costs
- ✅ Better resilience (traffic routed around outages)
- ✅ No practical privacy concerns (data processed within Azure, not exposed to internet)

---

## References

- [Microsoft Azure Deployment Types Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/deployment-types?view=foundry-classic)
- [Azure Data Residency](https://azure.microsoft.com/explore/global-infrastructure/data-residency/)
- [Microsoft Foundry Models Sold Directly by Azure](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic)
- [Azure OpenAI Service Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- [Business Continuity and Disaster Recovery for Foundry Models](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/business-continuity-disaster-recovery?view=foundry-classic)

---

## Related Decisions

- **ADR-0001:** Architecture overview and core technology choices
- **ADR-0002:** Use Azure CLI instead of Azure PowerShell module (cross-platform support)
