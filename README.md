# fdb-docker


Dockerfiles to build FoundationDB dinaries that worn on both `arm64` and `amd64` architectures

## Building

```
docker build -f docker/fdb-pkg.Dockerfile docker --build-arg FDB_VERSION=7.1.42 -t foundationdb-pkg
```

```
docker build -f docker/fdb-binary.Dockerfile docker --build-arg FDB_VERSION=7.1.42 -t foundationdb
```

## Running precompiled image

```
docker run -p 4500:4500 -e FDB_NETWORKING_MODE=host us-docker.pkg.dev/dev-staging-308107/devbox-containers/foundationdb:7.1.42
```