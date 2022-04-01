## ArgoCD Application Manager
Contains the application manifests for argocd to declaratively deploy new applications, following this convention:
* https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
* https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/


### Directory Structure
#### apps/
  * contains subfolders of bounded contexts or argocd projects.
  * in each subfolder are a collection of argocd applications.

#### base/
  * contains the helm chart for the top-level app of apps or argocd app manager, which will spawn all of the sub-managers - one per bounded context
  * `make base` command will output the kubernetes manifest that can be `kubectl`-ed to create the top app of apps.


### ~~Submanagers~~
~~These are also app of apps which are defined in a separate repo, one for each bounded context or argocd project. Each submanager then manages (CRUD) all the apps for that bounded context.~~
```
                  app-manager (main)
                 /       |          \
              proj1     proj2      proj3   (submanagers)
             /    \      |         /    \
          app1   app2   appA     app!   app?  (argocd application for real workloads)
```


### Setup
1. adjust the values.yaml to suit the cluster, repo, ect
2. change directory to where Makefile is.
3. generate the `argocd-appmgr.yaml` to use when creating the base app
``` shell
make base
```
4. copy contents of `./argocd-appmgr.yaml` and create a new argocd application with that spec. For example it can be directly copy, pasted, applied in the argocd ui or even with `kubectl`.
5. sync the argocd-appmgr app and consider autosync.
6. add more applications under the `./apps` folder.
7. repeat 5-7

* **Note: for security purposes, consider revoking access to the `values.yaml:base.project` argocd project for everyone (such as developers) except infrastructure to reduce exposure in the case where someone accidentally deletes the app of apps. Deleting the app of apps with cascade enabled will remove all argocd apps and their kubernetes resources, which could result in a wide outage.**


### Application Full Example
These reside in `./apps/<bounded_context>/templates/<application_name>.yaml`
* use the templates already in there and add in any additional `spec:` details for that particular app.
* this full example shows all the various configurations that can be applied.
``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  # You'll usually want to add your resources to the argocd namespace.
  namespace: argocd
  # Add a this finalizer ONLY if you want these to cascade delete.
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # The project the application belongs to.
  project: default

  # Source of the application manifests
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook

    # helm specific config
    helm:
      # Extra parameters to set (same as setting through values.yaml, but these take precedence)
      parameters:
      - name: "nginx-ingress.controller.service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
        value: mydomain.example.com
      - name: "ingress.annotations.kubernetes\\.io/tls-acme"
        value: "true"
        forceString: true # ensures that value is treated as a string

      # Release name override (defaults to application name)
      releaseName: guestbook

      # Helm values files for overriding values in the helm chart
      # The path is relative to the spec.source.path directory defined above
      valueFiles:
      - values-prod.yaml

      # Values file as block file
      values: |
        ingress:
          enabled: true
          path: /
          hosts:
            - mydomain.example.com
          annotations:
            kubernetes.io/ingress.class: nginx
            kubernetes.io/tls-acme: "true"
          labels: {}
          tls:
            - secretName: mydomain-tls
              hosts:
                - mydomain.example.com

      # Optional Helm version to template with. If omitted it will fall back to look at the 'apiVersion' in Chart.yaml
      # and decide which Helm binary to use automatically. This field can be either 'v2' or 'v3'.
      version: v2

    # kustomize specific config
    kustomize:
      # Optional kustomize version. Note: version must be configured in argocd-cm ConfigMap
      version: v3.5.4
      # Optional image name prefix
      namePrefix: prod-
      # Optional images passed to "kustomize edit set image".
      images:
      - gcr.io/heptio-images/ks-guestbook-demo:0.2

    # directory
    directory:
      recurse: true
      jsonnet:
        # A list of Jsonnet External Variables
        extVars:
        - name: foo
          value: bar
          # You can use "code to determine if the value is either string (false, the default) or Jsonnet code (if code is true).
        - code: true
          name: baz
          value: "true"
        # A list of Jsonnet Top-level Arguments
        tlas:
        - code: false
          name: foo
          value: bar

    # plugin specific config
    plugin:
      name: mypluginname
      # environment variables passed to the plugin
      env:
        - name: FOO
          value: bar

  # Destination cluster and namespace to deploy the application
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook

  # Sync policy
  syncPolicy:
    automated: # automated sync by default retries failed attempts 5 times with following delays between attempts ( 5s, 10s, 20s, 40s, 80s ); retry controlled using `retry` field.
      prune: true # Specifies if resources should be pruned during auto-syncing ( false by default ).
      selfHeal: true # Specifies if partial app sync should be executed when resources are changed only in target Kubernetes cluster and no git change detected ( false by default ).
      allowEmpty: false # Allows deleting all application resources during automatic syncing ( false by default ).
    syncOptions:     # Sync options which modifies sync behavior
    - Validate=false # disables resource validation (equivalent to 'kubectl apply --validate=false') ( true by default ).
    - CreateNamespace=true # Namespace Auto-Creation ensures that namespace specified as the application destination exists in the destination cluster.
    - PrunePropagationPolicy=foreground # Supported policies are background, foreground and orphan.
    - PruneLast=true # Allow the ability for resource pruning to happen as a final, implicit wave of a sync operation
    # The retry feature is available since v1.7
    retry:
      limit: 5 # number of failed sync attempt retries; unlimited number of attempts if less than 0
      backoff:
        duration: 5s # the amount to back off. Default unit is seconds, but could also be a duration (e.g. "2m", "1h")
        factor: 2 # a factor to multiply the base duration after each failed retry
        maxDuration: 3m # the maximum amount of time allowed for the backoff strategy

  # Ignore differences at the specified json pointers
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```
