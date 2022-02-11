# dblab-azure-demo

Disclaimer: this repository is for demo purposes only.
The setup is **NOT** production ready and relies on external scripts to setup the demo. 
USE AT YOUR OWN RISK.

## How to use

1. Update the `0-prepare.sh` script to have you project specific values
1. Create a `terraform/config.azurerm.tfbackend` file which contains the backend configuration for you terraform setup
1. Run `1-terraform-apply.sh`