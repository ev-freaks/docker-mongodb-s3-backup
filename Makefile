DOCKER_REPO := ev-freaks/mongodb-s3-backup

build:
	docker build -t "${DOCKER_REPO}" .

.PHONY: build
