#!/bin/bash
find ./apps/ -maxdepth 1 -mindepth 1 | while read -r chart; do helm template "$chart" --values values.yaml >> ./apps.yaml; done
