# mongodb-s3-backup

A Docker Image to run MongoDB backups unattended using mongoexport. Available for both arm64 and x86 (amd64) architectures.

There are also two versions of the docker image for MogoDB versions 4 and 5.

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

For same-AZ routing to actually take effect, tag each replica set member with its zone, e.g.:

```js
cfg = rs.conf()
cfg.members.forEach(m => { m.tags = { ...m.tags, az: "eu-central-1a" } }) // set per member
rs.reconfig(cfg)
```

[task metadata endpoint]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v4-fargate.html

## Test image locally

Test official image

```bash
docker run --rm --env-file .env -e AWS_PROFILE=$AWS_PROFILE -v ~/.aws:/root/.aws evfreaks/mongodb-s3-backup:5 backup collection1 collection2
```

Build and test -testing image

```shell
make build
docker run --rm --env-file .env -e AWS_PROFILE=$AWS_PROFILE -v ~/.aws:/root/.aws evfreaks/mongodb-s3-backup:5 backup collection1 collection2
```