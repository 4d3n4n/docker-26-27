variable "VERSION" {
  default = "1.0"
}

variable "GIT_SHA" {
  default = "local"
}

variable "REGISTRY" {
  default = "127.0.0.1:5000"
}

group "default" {
  targets = ["api", "worker"]
}

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.version"  = VERSION
    "org.opencontainers.image.revision" = GIT_SHA
    "org.opencontainers.image.source"   = "https://github.com/4d3n4n/docker-26-27"
  }
  # Modèle remplacé par chaque cible concrète pour isoler ses couches.
  cache-to = ["type=registry,ref=${REGISTRY}/cache:template,mode=max"]
}

target "_worker-base" {
  context    = "./starter/shop-worker"
  dockerfile = "Dockerfile"
  secret     = ["id=pipconf,src=./starter/shop-worker/pip.conf"]
  args = {
    APP_VERSION = VERSION
    GIT_SHA     = GIT_SHA
  }
}

target "api" {
  inherits   = ["_common"]
  context    = "../tp01-optimisation-image/starter/shopapi"
  dockerfile = "Dockerfile"
  tags       = ["${REGISTRY}/shop-api:${VERSION}"]
  args = {
    APP_VERSION = VERSION
    GIT_SHA     = GIT_SHA
  }
  cache-from = ["type=registry,ref=${REGISTRY}/cache:api"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:api,mode=max"]
}

target "worker" {
  inherits   = ["_common", "_worker-base"]
  tags       = ["${REGISTRY}/shop-worker:${VERSION}"]
  cache-from = ["type=registry,ref=${REGISTRY}/cache:worker"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:worker,mode=max"]
}

target "worker-test" {
  inherits  = ["_worker-base"]
  target    = "test"
  platforms = ["linux/amd64", "linux/arm64"]
  output    = ["type=cacheonly"]
}
