# dblab-azure-demo

Disclaimer: this repository is for demo purposes only.
The setup is **NOT** production ready and relies on external scripts to setup the demo. 
**USE AT YOUR OWN RISK.**

## How to use

1. Create a .env file which looks like the example below. Fill out all the fields so they can be picked up by the scripts!
1. Source the .env file by running `source .env`. 
1. Execute `sh 0-prepare.sh`. This will create the Terraform state storage account in Azure.
1. Execute `sh 1-terraform-apply.sh`. This will create all the required infrastructure to run this demo. Note this will create resource in Azure and will generate some cost. Validate that the used SKUs. When prompted, review the Terraform plan and type `yes` and hitting `<enter>` to provision the infrastructure.
1. Execute `sh 2-init-vm.sh`. This will install all the dependencies and configure everything to run DBLab on the instance and connect it to the Azure Database for PostgreSQL. This will also inject some data into the database so you can test the cloning with some data. When prompted to add the instance to the list of known hosts, accept it by typing `yes` and hitting `<enter>`
1. Execute `sh 3-start-dblab.sh`. This will start the actual DLE server and make the UI available. It will launch the UI and show the token in the output of the script.

## Helper scripts

- `50-login-into-vm.sh`: does as advertised. It downloads the private key to connect to the VM and opens an SSH connection to it.
- `51-open-web-ui.sh`: opens the GUI for DLE and outputs the token.

## Cleanup
In order to clean up, execute the following steps. 
Note, this will delete ALL data you have stored in the Azure Database for PostgreSQL and remove all DBLab clones you have created.

1. Execute `sh 99-terraform-destroy.sh`. This will remove all infrastructure used in the demo.
1. Execute `sh 100-destroy.sh`. This will remove the storage account that houses the Terraform state.

## Example .env file

```bash
export location="westeurope"
export rgstate="rg-dblab-demo-state"
export sastate="sadblabdemostate" #changeme as this needs to be globally unique ;)
export subscription="xxxx1234-1234-1234-1234-xxxxxx123456"
```