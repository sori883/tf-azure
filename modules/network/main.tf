resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# APIM の VNet injection 用サブネット（Microsoft.ApiManagement/service に委任）。
resource "azurerm_subnet" "apim" {
  name                 = "apim"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.apim_subnet_prefix

  delegation {
    name = "apim-delegation"
    service_delegation {
      name = "Microsoft.ApiManagement/service"
      # prepareNetworkPolicies は Azure 側が自動付与するため、
      # 明示しないと plan のたびに差分が出る（恒久ドリフト）。
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
    }
  }
}

# Private Endpoint 用サブネット。
resource "azurerm_subnet" "pe" {
  name                 = "private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.pe_subnet_prefix
}

# APIM サブネット用 NSG。VNet injection に必要な最小ルールを設定する。
# 参考: https://learn.microsoft.com/azure/api-management/virtual-network-reference
resource "azurerm_network_security_group" "apim" {
  name                = "${var.name_prefix}-apim-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # --- Inbound ---
  security_rule {
    name                       = "Client-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "Management-Endpoint-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "LoadBalancer-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6390"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  # --- Outbound ---
  security_rule {
    name                       = "Storage-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }
  security_rule {
    name                       = "SQL-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "SQL"
  }
  security_rule {
    name                       = "KeyVault-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
  }
  security_rule {
    name                       = "AzureAD-Outbound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
  }
  security_rule {
    name                       = "Monitor-Outbound"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "1886"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }
}

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

# APIM の VNet injection（stv2）に必須の Standard Public IP。
resource "azurerm_public_ip" "apim" {
  name                = "${var.name_prefix}-apim-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  # stv2 の injection では Public IP に DNS ラベルが必須。
  domain_name_label = "${var.name_prefix}-apim"
  tags              = var.tags
}

# Azure OpenAI 用 Private DNS Zone。
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "${var.name_prefix}-openai-dnslink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = var.tags
}
