DOCKER_REPO := evfreaks/mongodb-s3-backup

build:
	docker build -t "${DOCKER_REPO}" .

.PHONY: build
