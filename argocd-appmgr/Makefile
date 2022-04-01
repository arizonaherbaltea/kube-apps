.PHONY: base regen-apps render-apps

HELM ?= /usr/bin/env helm

base: ## render the app of apps manifest that will maintain, i.e. CRUD (create, update, delete) argocd applications in gitops fashion. 
	@ $(HELM) template ./base/ --values values.yaml > ./argocd-appmgr.yaml

regen-apps: ##  add apps, which are grouped by bounded context and contain argocd app definitions for true workload apps, from list of projects.
	./scripts/regen-apps.sh

render-apps: ##  Don't directly apply this output to kubectl or argocd - just for debugging purposes.  Makes the entire collection of argocd applications which will be managed by the app of apps.
	rm ./apps.yaml
	./scripts/render-apps.sh
