# mongodb-s3-backup

A Docker Image to run MongoDB backups unattended using mongoexport

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

## Test image locally

```bash
docker run --rm --env-file .env -e AWS_PROFILE=$AWS_PROFILE -v ~/.aws:/root/.aws evfreaks/mongodb-s3-backup backup collection1 collection2
```
