ARG FUNCTION_DIR="/home/app/"
ARG RUNTIME_VERSION="3.12"
ARG DISTRO_VERSION="3.19"

FROM python:${RUNTIME_VERSION}-alpine${DISTRO_VERSION} AS python-alpine
# Install GCC (Alpine uses musl but we compile and link dependencies with GCC)
RUN apk add --no-cache \
    libstdc++

# Stage 2 - build function and dependencies
FROM python-alpine AS build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}
RUN apk add --no-cache aws-cli
# to go back to autoconf=2.71-r2; the upgrade to 2.72-r0 breaks the awslambdaric install
RUN echo https://dl-cdn.alpinelinux.org/alpine/v3.19/main >> /etc/apk/repositories
RUN echo https://dl-cdn.alpinelinux.org/alpine/v3.19/community >> /etc/apk/repositories

RUN apk add autoconf=2.71-r2 automake bash binutils cmake g++ gcc libtool make nodejs

# it has to be 3.16, too, after that it was removed :'(
RUN apk add --no-cache --update --repository=https://dl-cdn.alpinelinux.org/alpine/v3.16/main/ libexecinfo-dev

ARG FUNCTION_DIR
ARG RUNTIME_VERSION
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}
# Copy handler function
COPY app/* ${FUNCTION_DIR}

RUN python3 -m pip install awslambdaric --target ${FUNCTION_DIR}


FROM public.ecr.aws/newrelic-lambda-layers-for-docker/newrelic-lambda-layers-lambdaextension:2.3.14-arm64
FROM python-alpine

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}
RUN python3 -m pip install -t . newrelic newrelic-lambda

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# ***Required only to test in local***
# ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
# COPY entry.sh /
# RUN chmod 755 /usr/bin/aws-lambda-rie /entry.sh
# ENTRYPOINT [ "/entry.sh" ]
# CMD [ "app.handler" ]
# ***Required only to test in local***

# *** For Deployment Comment the above local code and uncomment the below two lines**
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]