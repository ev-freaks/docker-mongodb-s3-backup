ARG MONGO_MAJOR_VERSION="5"

FROM mongo:${MONGO_MAJOR_VERSION}

LABEL maintainer="remus@ev-freaks.com"

# Install the AWS cli incl. python dependencies; curl is used to query the ECS task metadata
# endpoint for the task's availability zone (same-AZ read preference)
RUN apt-get update \
  && apt-get install awscli jq curl --no-install-recommends -y \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./app/ /app/
RUN chmod +x main.sh

ENTRYPOINT [ "./main.sh" ]
CMD [ "backup" ]
