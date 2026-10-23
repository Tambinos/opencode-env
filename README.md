### Setup
#### Kata Containers
Installation of latest Version
```bash
export VERSION=$(curl -sSL https://api.github.com/repos/kata-containers/kata-containers/releases/latest | jq -r .tag_name)

# Release tarballs use architecture names that differ from `uname -m`.
case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  s390x)   ARCH=s390x ;;
  ppc64le) ARCH=ppc64le ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

curl -fsSL -o kata-static.tar.zst \
  "https://github.com/kata-containers/kata-containers/releases/download/${VERSION}/kata-static-${VERSION}-${ARCH}.tar.zst"

# The archive uses an /opt/kata/ prefix.
sudo tar -xvf kata-static.tar.zst -C /
```
Create daemon.json for docker config
```bash
sudo vim /etc/docker/daemon.json 
```
Add Runtime for Kata
```json
{
  "runtimes": {
    "kata": {
      "path": "/opt/kata/runtime-rs/bin/containerd-shim-kata-v2",
      "runtimeArgs": [
        "--kata-config",
        "/opt/kata/share/defaults/kata-containers/runtime-rs/configuration-qemu-runtime-rs.toml"
      ]
    }
  }
}

```
Restart docker
```bash
 sudo systemctl restart docker
```
#### SSH-config
Add your ssh key
```bash
ssh-add ~/.ssh/any-private-key
```
#### Enviornment
If you want your agent to be able to use GitHub client make sure to add a .env file
```
SANDBOX_GH_TOKEN=any pat or fine grained token
