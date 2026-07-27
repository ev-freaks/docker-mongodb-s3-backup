# mongodb-s3-backup

A Docker Image to run MongoDB backups unattended using mongoexport. Available for both arm64 and x86 (amd64) architectures, built on MongoDB 7.

Published to `ghcr.io/ev-freaks/mongodb-s3-backup:7`.

## In a nutshell

This image will create a backup of specific tables using `mongoexport`, by creating one gzipped file per MongoDB collection (table).

The backup script stores all the backup artifacts in S3, the S3 bucket name and path being fully configurable using environment variables.

Per invocation, the script will create a folder `YYYYMMDD-HHmmss` to save the backup artifacts.

| EVN var name | Description | Example |
| --- | --- | --- |
| MONGODB_BACKUP_URI|MongoDB URI|`mongodb://my-mongo-server.intern/my-database`
| MONGODB_BACKUP_S3_URL|S3 URL where the backup generations should be stored|`s3://my-bucket-name/my/path`


## Usage

Execute this image using an "action" parameter, followed by a list of collections to be processed (leave empty to process all available collections in the database).
 
Currently, the only supported action name is `backup`.

### Read preference / availability zone

Each `mongoexport` reads a full collection with no query or projection, so on a large
collection this is a meaningful amount of cross-AZ data transfer if it happens to land on a
replica set member in a different AZ than the task.

The image now always exports with `readPreference=secondaryPreferred` (never reads from the
primary), and when run as an ECS task it also queries the [task metadata endpoint]
(`$ECS_CONTAINER_METADATA_URI_V4/task`) for the task's own availability zone and prefers a
replica set member tagged with a matching `az` tag. Outside of ECS, or before the replica set
members are tagged, it falls back to any secondary.

For same-AZ routing to actually take effect, tag each replica set member with its own zone
(each member needs a different value - keyed by `host` here so it's clear which is which):

```js
cfg = rs.conf()
const az = {
  'mongodb-node-a.example.com:27017': 'eu-central-1a',
  'mongodb-node-b.example.com:27017': 'eu-central-1b',
  'mongodb-node-c.example.com:27017': 'eu-central-1c',
}
cfg.members.forEach(m => { m.tags = { ...m.tags, az: az[m.host] } })
rs.reconfig(cfg)
```

[task metadata endpoint]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v4-fargate.html

## Test image locally

Test official image

```bash
docker run --rm --env-file .env -e AWS_PROFILE=$AWS_PROFILE -v ~/.aws:/root/.aws ghcr.io/ev-freaks/mongodb-s3-backup:7 backup collection1 collection2
```

Build and test -testing image

```shell
make build
docker run --rm --env-file .env -e AWS_PROFILE=$AWS_PROFILE -v ~/.aws:/root/.aws ghcr.io/ev-freaks/mongodb-s3-backup:7 backup collection1 collection2
```