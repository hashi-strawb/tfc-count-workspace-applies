# Count Terraform Cloud Applies

A script which queries the Terraform Cloud API to count successful applies for all
workspaces in a recent time period.

## Requirements

The script just uses Bash and JQ
* Any recent version of Bash should work
* JQ can be installed from https://stedolan.github.io/jq


You also need a Terraform Cloud API token

You can generate one at https://app.terraform.io/app/${your-org-here}/settings/authentication-tokens

## Running

Set your TFC API token as an environment variable

```
read -s TFC_TOKEN && export TFC_TOKEN
```


Then run the script with
```
./applies.sh lmhd 2021-12-01
```


An example output:

```
ID,Name,Applies,
ws-daharcA9w55rgakA,vault-okta,18,
ws-mHMG4HMRvW91o8nM,dns,4,
ws-c5JL7FYqW4bSGqcQ,vault,0,
```
