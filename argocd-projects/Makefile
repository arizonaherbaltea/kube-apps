.PHONY: base projects

HELM ?= /usr/bin/env helm

base: ## the app of apps that will maintain, i.e. CRUD (create, update, delete) argocd applications in gitops fashion. 
	@ $(HELM) template ./base/ --values values.yaml > ./argocd-projects.yaml

projects: ##  Don't directly apply this output to kubectl or argocd - just for debugging purposes.  Makes the entire collection of argocd applications which will be managed by the app of apps.
	@ $(HELM) template ./projects/ --values values.yaml > ./appprojects.yaml
