# My Atomic AlmaLinux Respin

Welcome to your brand-new Atomic AlmaLinux Respin!

## Initial Setup

### Set basic configuration

In the ["config"](.github/actions/config/action.yml) action, you'll find a job where you can configure several key variables:

- `REGISTRY`: The container registry to push your image to (default: GitHub Container Registry `ghcr.io`).
- `REGISTRY_USER`: Your username for the registry.
- `IMAGE_PATH`: The path/namespace for your image.
- `IMAGE_NAME`: The name of your image.
- `PLATFORMS`: A quoted, comma-separated list of platforms to build for (e.g., `"amd64,arm64"`).

If your registry is not GitHub or you need a specific token, search for `REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}`
in the workflow files and replace it with the appropriate secret.

### Pick a base desktop image

By default, this template uses the base image `quay.io/almalinuxorg/atomic-desktop-gnome:10`, maintained by the
[AlmaLinux Atomic SIG](https://wiki.almalinux.org/sigs/Atomic.html). If you prefer KDE, you can use
`quay.io/almalinuxorg/atomic-desktop-kde:10` instead.

To switch images, change the `FROM` line in the [Dockerfile](Dockerfile). If your image use a different
signing key, download the new Cosign public key and specify its name in the `upstream-public-key`
parameter in `.github/workflows/build.yml`, or remove the parameter to disable key verification.

### Set up container signing (Optional, highly recommended)

Container signing is important for end-user security and is fully supported by
the CI. By default, the CI will check the signature of your base image to make
sure it hasn't been tampered with. You can also sign your own image to give
your users the same security guarantees.

If you'd like to sign your images using Cosign:

1. Generate a cosign key:
   ```sh
   podman run --rm -it -v /tmp:/cosign-keys bitnami/cosign generate-key-pair
   ```
   Leave the password blank. The keys will be in `/tmp/cosign.{key,pub}`.
2. Add `cosign.pub` to the repository as `/cosign.pub`, commit, and push. This file is public and
   needed for signature verification. **NEVER** commit your `cosign.key` to the repo!!
3. In GitHub repo settings, go to "Secrets and variables" > "Actions". Create a secret called
   `SIGNING_SECRET` and paste the contents of `cosign.key`. Store `cosign.key` securely and delete
   it from `/tmp`. You can also do this via the GitHub CLI:
   ```bash
   gh secret set SIGNING_SECRET < cosign.key
   ```

### Set up Cloudflare R2 for ISO storage

By default, the CI uploads built ISO images as GitHub Artifacts. These can be large, and artifact storage is limited, so you may want to upload ISOs to Cloudflare R2 (free tier).

Follow these steps:

1. **Sign up for [Cloudflare R2](https://www.cloudflare.com/developer-platform/products/r2/)** and create a new bucket. Use any name and location; the free tier only supports the Standard storage class.
2. **Create an API token** with "Object Read & Write" permissions, limited to your new bucket. Save the Access Key ID and Secret Access Key.
3. **Add the following repository secrets in GitHub:**
   - `R2_ACCOUNT_ID`: Your Cloudflare account ID (found in the dashboard URL: `https://dash.cloudflare.com/<R2_ACCOUNT_ID>/home`)
   - `ACCESS_KEY_ID`: The Access Key ID from your API token
   - `SECRET_ACCESS_KEY`: The Secret Access Key from your API token
   - `BUCKET`: Your bucket name
4. **Update your workflow:**
   In the `build-iso` job of [`build-iso.yml`](/.github/workflows/build-iso.yml), uncomment the secret definitions for these secrets and set `upload-to-cloudflare: true` in the workflow inputs:
   ```yaml
   upload-to-cloudflare: true
   ```
5. **Enable public access (optional):**
   In the Cloudflare dashboard, select your R2 bucket and enable the "Public Development URL" if you want to share ISOs publicly. This gives you a URL prefix for downloads.

## Customizing your respin

Now you're ready to make your respin your own!

### Adding files

Place any files you want to include in your image in [`/files/system/`](files/system/). The
directory structure and permissions will be preserved. This is ideal for adding themes,
backgrounds, configuration files, etc.

### Executing commands

Scripts in [`/files/scripts/`](files/scripts/) are run during image creation. The `build.sh`
script copies files from `/files/system/` into the image, then runs all scripts in order,
and finally runs `cleanup.sh`.

- Start by editing [`10-base.sh`](files/scripts/10-base.sh) to suit your needs.
- Add more scripts as needed, using the naming scheme `XX-whatever.sh` (where `XX` is a number).
- Do **not** modify `build.sh`, `cleanup.sh`, `90-signing.sh`, or `91-image-info.sh` unless you know what you're doing.

### Build your new image

After adding your files and scripts, commit your changes. The CI will build a new image
for you automatically. You can also build locally:

```sh
make image
```

#### Local development with Makefile

The provided `Makefile` includes several useful commands for local development and testing:

- `make image`: Build the container image using Podman.
- `make clean`: Remove the `./output` directory and build artifacts.
- `make iso`: Build a bootable ISO image using [bootc-image-builder](https://github.com/osbuild/bootc-image-builder).
- `make qcow2`: Build a QCOW2 disk image using bootc-image-builder.
- `make run-qemu-iso`: Boot the generated ISO in QEMU for testing. Creates a virtual disk if needed.
- `make run-qemu-qcow`: Boot the generated QCOW2 disk image in QEMU for testing.
- `make run-qemu`: Boot the raw disk image in QEMU (after installation).

> **Note:** You may need `sudo` privileges and Podman installed. For more details, see
>  the `Makefile`. QEMU is only optionally needed for local testing.

## Using your image with bootc

Your respin is designed to work with [bootc](https://github.com/containers/bootc), a tool for
managing and updating container-based operating system images. Here are some basics to get you started:

### Installing your image

Build or download the ISO for your image, boot into it and follow the installation procedure.

### Switching from another image

> [!CAUTION]
> This is entirely unsupported and may not work at all. In fact, it probably doesn't
> work at all and it's a terrible idea to even try. Don't do this.

If you're already running a bootc image and wish to change to this one, you may be able to do
this via `bootc switch`. As you won't have the correct signing key or configuration, you'll
have to disable it first:

```sh
sudo cp /etc/containers/policy.json /etc/containers/policy.json.old
sudo echo '{"default": [{"type": "insecureAcceptAnything"}]}' > /etc/containers/policy.json
sudo bootc switch --transport registry <REGISTRY>/<IMAGE_PATH>/<IMAGE_NAME>:latest
```

(fill in `<REGISTRY>/<IMAGE_PATH>/<IMAGE_NAME>` with your actual bootc image location)

After this, reboot into your new image. Now we can fix it to enforce key verification
with the new image's `policy.json`:

```sh
sudo cp /usr//etc/containers/policy.json /etc/containers/policy.json
```

Now your image should be able to update itself correctly. Or not at all. Remember,
this is entirely unsupported!!

### Upgrading your system

Once installed, your system will automatically check for updates in the background using a
systemd unit provided by bootc. You can also manually trigger an upgrade:

```sh
sudo bootc upgrade
```

This will pull the latest image and prepare it for the next boot. On reboot, the system
will run the new image version.

### Checking status and troubleshooting

- To see the current image and status:
  ```sh
  bootc status
  ```
- To roll back to the previous image after an upgrade:
  ```sh
  sudo bootc rollback
  ```

## Continuous Integration (CI)

This template is set up with GitHub Actions workflows to build, test, and (optionally)
sign your images automatically on every push or pull request. See the `.github/workflows/`
directory for details.

## Troubleshooting

- **Build fails locally:** Ensure you have Podman and QEMU installed, and that you have the necessary permissions (try running with `sudo`).
- **CI build fails:** Check the Actions tab in GitHub for logs. Make sure your secrets and configuration are correct.
- **Image doesn't boot in QEMU:** Double-check your custom scripts and added files for errors, check the build logs for errors.

## Resources

- [AlmaLinux Atomic SIG](https://wiki.almalinux.org/sigs/Atomic.html)
- [AlmaLinux Atomic Desktop Images](https://github.com/AlmaLinux/atomic-desktop)
- [bootc documentation](https://github.com/containers/bootc)
- [Podman documentation](https://podman.io/)
- [QEMU documentation](https://www.qemu.org/)
