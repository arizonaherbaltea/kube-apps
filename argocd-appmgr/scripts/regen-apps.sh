#!/bin/bash
list=$(cat ./list.txt)

file=$(cat << EOF
apiVersion: v2
name: ArgoCD Applications
description: Contains one or more Argocd Application specs

type: application

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
# Versions are expected to follow Semantic Versioning (https://semver.org/)
version: 1.0.0

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application. Versions are not expected to
# follow Semantic Versioning. They should reflect the version the application is using.
appVersion: "1.0"

EOF
)


while read -r line; do
  name="$line"
  mkdir -p "./apps/${name}"
  mkdir -p "./apps/${name}/templates"
  echo "$file" > "./apps/${name}/Chart.yaml"
done < <(echo "$list")
