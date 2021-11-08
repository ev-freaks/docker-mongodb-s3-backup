FROM mongo:5

LABEL maintainer="remus@ev-freaks.com"

# Install the AWS cli incl. python dependencies
RUN apt-get update \
  && apt-get install awscli jq --no-install-recommends -y \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./app/ /app/
RUN chmod +x main.sh

ENTRYPOINT [ "./main.sh" ]
CMD [ "backup" ]
