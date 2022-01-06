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

echo "ID,Name,Applies,"

workspaces=$(curl -s \
	--header "Authorization: Bearer $TFC_TOKEN" \
	--header "Content-Type: application/vnd.api+json" \
	https://app.terraform.io/api/v2/organizations/${TFC_ORG}/workspaces)
workspace_ids=$(echo ${workspaces}| jq -r .data[].id)

for id in ${workspace_ids}; do

# Example, where it tried to apply, but failed
#
# {
#   "errored-at": "2021-07-11T14:53:36+00:00",
#   "planned-at": "2021-07-11T14:52:36+00:00",
#   "applying-at": "2021-07-11T14:52:46+00:00",
#   "planning-at": "2021-07-11T14:52:09+00:00",
#   "confirmed-at": "2021-07-11T14:52:44+00:00",
#   "plan-queued-at": "2021-07-11T14:52:08+00:00",
#   "apply-queued-at": "2021-07-11T14:52:44+00:00",
#   "plan-queueable-at": "2021-07-11T14:52:08+00:00"
# }
# i.e. no "applied-at"

# And another, where it succeeded
# {
#   "applied-at": "2021-05-30T21:37:28+00:00",
#   "planned-at": "2021-05-30T21:34:24+00:00",
#   "applying-at": "2021-05-30T21:36:43+00:00",
#   "planning-at": "2021-05-30T21:33:49+00:00",
#   "confirmed-at": "2021-05-30T21:36:41+00:00",
#   "plan-queued-at": "2021-05-30T21:33:49+00:00",
#   "apply-queued-at": "2021-05-30T21:36:42+00:00",
#   "plan-queueable-at": "2021-05-30T21:33:46+00:00"
# }
# i.e. we have an "applied-at" date

	# list all runs in the workspace, with successful applies
	applies=$(
		curl -s \
			--header "Authorization: Bearer $TFC_TOKEN" \
			--header "Content-Type: application/vnd.api+json" \
			https://app.terraform.io/api/v2/workspaces/${id}/runs?page%5Bsize%5D=100 \
				| jq ".data[]
					| select (.attributes.\"status-timestamps\".\"applying-at\" | . != null)
					| select (.attributes.\"status-timestamps\".\"applying-at\" >= \"${FROM_DATE}\")
					| .attributes.\"status-timestamps\".\"applying-at\"" \
				| jq --slurp length
	)

	name=$(echo ${workspaces} | jq -r ".data[] | select(.id == \"${id}\") | .attributes.name")

	echo ${id},${name},${applies},
done

