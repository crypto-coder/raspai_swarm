
FROM node:19-alpine AS base
WORKDIR /app
RUN apk update && apk add rsync

CMD ["/bin/sh"]
