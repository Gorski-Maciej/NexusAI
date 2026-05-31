# =============================================================================
# TigerBeetle + Busybox — extended image for Docker healthcheck
# =============================================================================
# The official ghcr.io/tigerbeetle/tigerbeetle image is scratch-based and
# contains only the tigerbeetle binary.  This Dockerfile adds a statically
# linked busybox binary so Docker HEALTHCHECK can verify TCP connectivity
# on port 3000 without requiring a shell or package manager.
# =============================================================================

FROM busybox:stable AS busybox

FROM ghcr.io/tigerbeetle/tigerbeetle:latest

COPY --from=busybox /bin/busybox /busybox

ENTRYPOINT ["/tigerbeetle"]
