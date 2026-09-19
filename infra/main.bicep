@description('The primary DNS zone name (e.g., labdemo.com)')
@minLength(3)
param zoneName string = 'labdemo.com'

@description('TTL for the A record set in seconds')
param aRecordTtl int = 3600

@description('Target IPv4 address for the www host')
param targetIpv4Address string = '10.10.10.10'

@description('Resource tags')
param tags object = {
  Environment: 'Production'
  ManagedBy: 'Bicep'
  Workload: 'Core-Networking'
}

// Authoritative Public DNS Zone
resource dnsZone 'Microsoft.Network/dnszones@2023-07-01-preview' = {
  name: zoneName
  location: 'global'
  tags: tags
  properties: {
    zoneType: 'Public'
  }
}

// Subdomain A Record Set
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

output dnsZoneId string = dnsZone.id
output nameServers array = dnsZone.properties.nameServers
output fqdn string = 'www.${zoneName}'
