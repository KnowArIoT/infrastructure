#!/bin/bash

## Local system enviroments
API_URL="https://api.digitalocean.com/v2"
TOKEN="N/A"
LBAPI="N/A"
LBDB="N/A"
TAG="ARIOT"
TYPE="API"
TOTAL_DROPLETS=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "$API_URL/droplets?tag_name=${TAG}${TYPE}" | jq .meta.total)

## DigitalOcean enviroments
DROPLET_NAME="ariot-api-"
DROPLET_REGION="lon1"
DROPLET_SIZE="512mb"
DROPLET_API_IMAGE="N/A"
DROPLET_DB_IMAGE="N/A"

## Calculations
CPU=$(grep -c "^processor" /proc/cpuinfo)
CURRENT_LOAD=$(cat /proc/loadavg | awk '{print $1}')
AVERAGE_LOAD=$(($(echo ${CURRENT_LOAD} | awk '{print 100 * $1}') / ${CPU}))

## Logic
if [ ${TOTAL_DROPLETS} -le 5 ] ; then
	if [ ${AVERAGE_LOAD} -ge 60 ] ; then
		if [ ${TYPE} == "API" ] ; then
  			add_droplet_to_lbapi $(create_api_droplet_from_snapshot | jq .droplet.id)
  		else
  			add_droplet_to_lbapi $(create_db_droplet_from_snapshot | jq .droplet.id)
  		fi
	fi
fi

## API droplet creation
create_api_droplet_from_snapshot {
  curl -X POST "$API_URL/droplets" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d "{\"name\":\"${DROPLET_NAME}${TOTAL_DROPLETS}\",
  	\"region\":\"${DROPLET_REGION}\",
  	\"size\":\"${DROPLET_SIZE}\",
  	\"tags\":\"${TAG}\",
  	\"private_networking\":\"true\",
  	\"monitoring\":\"true\",
  	\"image\": \"${DROPLET_API_IMAGE}\"}"
}

## DB droplet creation
create_db_droplet_from_snapshot {
  curl -X POST "$API_URL/droplets" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d "{\"name\":\"${DROPLET_NAME}${TOTAL_DROPLETS}\",
  	\"region\":\"${DROPLET_REGION}\",
  	\"size\":\"${DROPLET_SIZE}\",
  	\"tags\":\"${TAG}\",
  	\"private_networking\":\"true\",
  	\"monitoring\":\"true\",
  	\"image\": \"${DROPLET_DBIMAGE}\"}"
}

## LB
add_droplet_to_lbapi {
  curl -X POST "$API_URL/load_balancers/$LBAPI/droplets" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"droplet_ids": [$1]}' 
}