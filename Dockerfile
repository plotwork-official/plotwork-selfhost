# syntax=docker/dockerfile:1
#
# The self-hosted Plotwork engine, from the built files in this repository. Nothing is compiled or installed here: dist/ is the
# bundle the source repository built and tested, checked against checksums.txt before this runs. The image is distroless
# Node 24 with that bundle and nothing else: no shell, no package manager, no node_modules. It runs as the image's nonroot user
# (65532), writes nothing to disk, and makes no outbound request. The base is pinned by digest, an index that holds both the
# linux/amd64 and linux/arm64 images, so one build serves both.
#
#   docker build --build-arg VERSION="$(cat VERSION)" -t plotwork-selfhost .

FROM gcr.io/distroless/nodejs24-debian12:nonroot@sha256:14d42e2511532589a7c7e01a753667a74fcc96266e137e8125006b87b0c32d0a

ARG VERSION=unknown

LABEL org.opencontainers.image.title="plotwork-selfhost" \
      org.opencontainers.image.description="The Plotwork diagram engine: MCP over Streamable HTTP and a REST API. No accounts, no hosting, no network." \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.vendor="Buun Group" \
      org.opencontainers.image.licenses="LicenseRef-Plotwork-Self-Hosted-1.0" \
      org.opencontainers.image.url="https://docs.plotwork.dev/mcp/self-hosting" \
      org.opencontainers.image.documentation="https://docs.plotwork.dev/mcp/self-hosting" \
      org.opencontainers.image.source="https://github.com/plotwork-official/plotwork-selfhost"

WORKDIR /app
COPY dist/ /app/
COPY LICENSE THIRD-PARTY-NOTICES.md /licenses/

ENV NODE_ENV=production \
    PLOTWORK_HOST=0.0.0.0 \
    PLOTWORK_PORT=3106

USER 65532:65532
EXPOSE 3106
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD ["/nodejs/bin/node", "/app/healthcheck.mjs"]
CMD ["/app/server.mjs"]
