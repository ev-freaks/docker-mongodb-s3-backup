DOCKER_REPO := evfreaks/mongodb-s3-backup

all: build-and-push

builder:
	docker buildx create --name builder --use

build-and-push:
	docker buildx build --builder builder --platform linux/amd64,linux/arm64 -t "${DOCKER_REPO}:testing" --push .

inspect:
	docker buildx imagetools inspect "${DOCKER_REPO}:testing"

.PHONY: build
