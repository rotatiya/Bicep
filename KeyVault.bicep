targetScope = 'resourceGroup'
param pEnvironment string 
param pProjectName string 
param pLocationAbb string 
param pPostFix string 
param pLocation string

//param pUtilitiesSubnetId string = '/subscriptions/{subscriptionId}/resourceGroups/{ResourceGroup}/providers/Microsoft.Network/virtualNetworks/{VirtualNetworkName}/subnets/{subnet-Name}'
param pUtilitiesSubnetId string
//param pObjectId string = '685a2f0e-173a-4112-9329-120dacc06206'
param pObjectId string 

var vKeyVaultName = pEnvironment == 'prod' ? toLower('kv-${pEnvironment}-${pProjectName}-${pLocationAbb}-${pPostFix}')  : toLower('kv-dta-${pProjectName}-${pLocationAbb}-${pPostFix}')

var vPrivateEndpointName = 'pvtendpt-${pEnvironment}-${pProjectName}-keyvault-${pLocationAbb}-${pPostFix}'
param pAppServiceRegVnetSubnetId string


resource snKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: vKeyVaultName
  location: pLocation
  tags: {
    domainjoin: 'domainjoin'
  }
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    enablePurgeProtection: true
    enableSoftDelete: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: pObjectId
        permissions: {
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    createMode: 'default'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules:[
        {
          id: pAppServiceRegVnetSubnetId
        }
      ]
    }
  }

  resource snKVSecretAud 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-aud'
    properties: {
      value: 'addYourValueHere'
      contentType: 'Azure AD audience details for MSP'
    }
  }

  resource snKVSecretClientId 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-clientid'
    properties: {
      value: 'addYourValueHere'
      contentType: 'Azure AD app registration client id of MSP'
    }
  }

  resource snKVSecretDomain 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-domain'
    properties: {
      value: 'addYourValueHere'
      contentType: 'Azure AD domain'
    }
  }

  resource snKVSecretInstance 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-instance'
    properties: {
      value: 'addYourValueHere'
      contentType: 'Azure AD instance details'
    }
  }

  resource snKVSecretTenantid 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-tenantid'
    properties: {
      value: subscription().tenantId
      contentType: 'Azure AD tenant to authenticate and authorize'
    }
  }

  resource snKVSecretIssuer 'secrets@2022-07-01' = {
    name: 'kv-secret-azuread-issuer'
    properties: {
      value: 'addYourValueHere'
      contentType: 'Azure AD Issuer details'
    }
  }
}

resource snPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: vPrivateEndpointName
  location: pLocation
  tags: {
    domainjoin: 'domainjoin'
  }
  properties: {
    subnet: {
      id: pUtilitiesSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: vPrivateEndpointName
        properties: {
          privateLinkServiceId: snKeyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

