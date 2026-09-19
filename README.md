# Enterprise DNS Resolution

![Azure](https://img.shields.io/badge/Azure-Cloud-0089D6?style=flat&logo=microsoftazure)
![IaC](https://img.shields.io/badge/IaC-Bicep-007ACC?style=flat&logo=arm)
![Verification](https://img.shields.io/badge/Validation-Verified-success?style=flat)
![Architecture](https://img.shields.io/badge/Scope-Authoritative%20DNS-blueviolet?style=flat)

Enterprise-grade authoritative DNS zone configuration and subdomain routing deployed via Infrastructure-as-Code (Bicep) and validated against Azure Anycast nameservers.

---

## 1. Business Problem & Architecture Overview

Organizations hosting public-facing endpoints require highly available, low-latency, and distributed domain name resolution. Managing custom DNS virtual machines introduces operational patching burdens, single points of failure, and heightened attack surfaces. 

This project provisions an authoritative public DNS zone backed by Microsoft’s Anycast network, separating infrastructure apex metadata from modular host mapping.

   Internet / Client Query ([www.labdemo.com](https://www.labdemo.com))
                      │
                      ▼
        [ Azure Anycast Edge DNS ]
 ns1-05.azure-dns.com / ns2-05.azure-dns.net
                      │
     ┌────────────────┴────────────────┐
     ▼                                 ▼
[ Apex Zone ]                   [ Host Record Set ]labdemo.com                     www.labdemo.com (A Record)Type: Public DNS Zone           Target: 10.10.10.10 (TTL: 3600s)
### Architectural Resource Scope

| Resource Type | Name / Scope | Type | Purpose |
| :--- | :--- | :--- | :--- |
| `Microsoft.Network/dnszones` | `labdemo.com` | Public | Authoritative Root DNS Zone |
| `Microsoft.Network/dnszones/A` | `www` | Child (`/www`) | Host resolution to endpoint IPv4[cite: 4] |
| `Microsoft.Network/dnszones/NS` | `@` | System Apex | Authoritative Anycast nameserver delegation[cite: 4] |
| `Microsoft.Network/dnszones/SOA` | `@` | System Apex | Start of Authority zone metadata[cite: 4] |

---

## 2. Codified Infrastructure (Bicep)

Raw ARM templates frequently export system-generated, read-only apex NS and SOA records containing static serial numbers[cite: 4]. This implementation uses idiomatic Bicep to decouple platform records and manage application-layer routing deterministically.

```bicep
// Provision Global Authoritative DNS Zone
resource dnsZone 'Microsoft.Network/dnszones@2023-07-01-preview' = {
  name: zoneName
  location: 'global'
  properties: {
    zoneType: 'Public'
  }
}

// Provision Subdomain A-Record Mapping
resource aRecord 'Microsoft.Network/dnszones/A@2023-07-01-preview' = {
  parent: dnsZone
  name: 'www'
  properties: {
    TTL: aRecordTtl
    ARecords: [
      {
        ipv4Address: targetIpv4Address
      }
    ]
  }
}
Deploy using Azure CLI:Bashaz deployment group create \
  --resource-group rg-dns-networking \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
3. Implementation & Verification ProofA. Authoritative Zone InstantiationThe public DNS zone was provisioned across Azure's globally distributed Anycast network, establishing redundant primary nameservers (ns1-05.azure-dns.com through ns4-05.azure-dns.info).   B. Host Record Set PopulationThe www host record was populated with a 3600-second TTL mapping directly to the target endpoint 10.10.10.10 alongside system apex SOA/NS records.   C. Authoritative Name Resolution ValidationBecause the custom domain lacks parent registrar delegation, resolution was tested by directly querying the authoritative Azure Anycast nameserver (ns1-05.azure-dns.com) via nslookup.   Bash$ nslookup [www.labdemo.com](https://www.labdemo.com) ns1-05.azure-dns.com.
Server:         ns1-05.azure-dns.com.
Address:        13.107.236.5#53

Name:   [www.labdemo.com](https://www.labdemo.com)
Address: 10.10.10.10
