#!/bin/bash

if [[ -z "$1" ]]; then
	>&2 echo "Please specify a TFC Org by running with"
	>&2 echo "$0 my-org-name 2021-12-01"

	if [[ -z "${TFC_TOKEN}" ]]; then
		>&2 echo
		>&2 echo "Please also set TFC_TOKEN"
		>&2 echo "You can generate one at https://app.terraform.io/app/your-org-name-here/settings/authentication-tokens"
		exit 1
	fi
	exit 1
fi
TFC_ORG=$1

FROM_DATE=2021-12-01
if [[ -z "$2" ]]; then
	>&2 echo "from date not specified, using ${FROM_DATE}"
else
	FROM_DATE=$2
fi

if [[ -z "${TFC_TOKEN}" ]]; then
	>&2 echo "Please enter TFC_TOKEN"
	>&2 echo "You can generate one at https://app.terraform.io/app/$1/settings/authentication-tokens"
	read -s TFC_TOKEN
fi

if ! command -v jq &> /dev/null
then
	>&2 echo "jq could not be found. Please install: https://stedolan.github.io/jq/"
	exit 1
fi

echo "ID,Name,State Versions,"

workspaces=$(curl -s \
	--header "Authorization: Bearer $TFC_TOKEN" \
	--header "Content-Type: application/vnd.api+json" \
	https://app.terraform.io/api/v2/organizations/${TFC_ORG}/workspaces)
workspace_ids=$(echo ${workspaces}| jq -r .data[].id)

for id in ${workspace_ids}; do
	name=$(echo ${workspaces} | jq -r ".data[] | select(.id == \"${id}\") | .attributes.name")

	states=$(
		curl -s \
			--header "Authorization: Bearer $TFC_TOKEN" \
			--header "Content-Type: application/vnd.api+json" \
			"https://app.terraform.io/api/v2/state-versions?filter%5Bworkspace%5D%5Bname%5D=${name}&filter%5Borganization%5D%5Bname%5D=${TFC_ORG}&page%5Bsize%5D=100" \
				| jq ".data[]
					| select (.attributes.\"created-at\" | . != null)
					| select (.attributes.\"created-at\" >= \"${FROM_DATE}\")
					| .attributes.\"created-at\"" \
				| jq --slurp length
	)

	echo ${id},${name},${states},
done


