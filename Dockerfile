# ba0fde3d-bee7-4307-b97b-17d0d20aff50
# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx

COPY files/system /system_files/
COPY files/scripts /build_files/
COPY *.pub /keys/

# Base Image
FROM quay.io/almalinuxorg/atomic-desktop-gnome:10@sha256:7ebeb609ed9dda19ee233c2555c9ad7f040f04d14b3a39d34376c9db4f450195

ARG IMAGE_NAME
ARG IMAGE_REGISTRY
ARG VARIANT

RUN --mount=type=tmpfs,dst=/opt \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
