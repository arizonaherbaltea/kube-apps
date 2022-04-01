# # Helps migrate argocd appprojects from kubernetes to git

# print out all argocd appprojects and filter to only relevate details for making a chart template
kubectl -n argo-cd get appproject | awk '{print $1}' | grep -v -e 'NAME' -e 'default' \
| while read -r proj; do kubectl -n argo-cd -o json get appproject "$proj"; done  \
| jq -rc '{"apiVersion": .apiVersion,"kind": .kind, "metadata":{"name": .metadata.name, "namespace": "{{ .Values.argocd.namespace }}" }, spec: .spec}'


# copypasta output from above into heredoc (ndjson)
file=$(cat << EOF
EOF
)


# declare text replacements to insert helm templating
from1=$( cat << 'EOF' | sed -z -e 's/\n/\\n/g'
  namespace: '{{ .Values.argocd.namespace }}'
EOF
)
to1=$( cat << EOF | sed -z -e 's/\n/\\n/g'
  namespace: '{{ .Values.argocd.namespace }}'
EOF
)


# convert to yaml and output as helm chart template
echo "$file" | jq -rc '.' \
| while read -r line; do
  name="$(echo "$line" | jq -rc '.metadata.name')"
  ## add templating operators/replacements/ect to the helm chart template
  echo "$line" \
  | yq --yaml-output '.' \
  | sed -z "s^$from1^$to1^g" \
  > projects/templates/${name}.yaml
done
