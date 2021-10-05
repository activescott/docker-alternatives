# Docker Alternatives Investigation

Docker desktop on Mac has become bloated and most of all extremely anoying. Apparently they company has decided to anoy you into paying by prompting nearly every day to pause what you're doing and upgrade to a new version that has nothing you're interested in or pay to stop the anoying and interrupting prompts. Good luck with that. I'm sure somebody loves that colorful UI up there, but I use docker exclusively in the shell and scripts on my dev box, so it's also become rather anoying to be blinking up there all the time anyway.

So... are there reasonable alternatives?

## Goals

The goals of this investigation are to see if I can feasibly replace the following on macOS:

1. The ability to **build** Dockerfile's to [OCI][oci]-compliant [images][oci-bundle].
2. The ability to **run** OCI-compliant images (with _at least_ host-local networking and ability to tty to running container).
3. The ability to upload OCI-compliant images to Dockerhub and/or Github or other container registries (lower priority)

## Conclusion:

At least for now [podman] is amazing drop-in replacement for docker on macOS.

## TODO

- [+] checkout [podman]
- [ ] add example of running a command in a linuxkit image and immediately halting or stopping the image and piping the process exit code to the host.
- [ ] TODO: Although linuxkit doesn't run OCI containers, it is fundamentally a linux VM with [containerd] and [`ctr`] (I cannot find docs on `ctr` but it is a command that allow dealing with containers on containerd hosts and is in the linuxkit VMs). So conceivably we could figure out a way to run OCI images on a linuxkit-vm locally (I _)\_think_ that's effectively what Docker for Mac does).
  - [ ] add an example of running [img] in a linuxkit container to build a Dockerfile into an [OCI-bundle] and saving the OCI-bundle on the host (e.g. mounted volume). See https://github.com/genuinetools/img#running-with-docker
  - [ ] Add an example of running an oci-bundle on the host within a linuxkit vm

## Alternative Exploration

### 1. Building

#### Podman: TODO

##### Installation:

See https://podman.io/getting-started/installation
tldr;

```sh
brew install podman
# brew install qemu if you don't have qemu already (or maybe homebrew installs it? I already had it)
podman machine init # downloads a qemu vm
podman machine start # starts a qemu vm

# ensure everyting is running:
podman info
```

##### Building

tldr `alias docker=podman` https://podman.io/whatis.html

```sh
# Build it (this is glorified way to call podman build -f ....)
./scripts/podman/build.sh ./image-defs/podman/simpliest.containerfile

# see the image:
podman images
```

##### Running

again, just like docker, but the below script has some notes and more detail

```sh
./scripts/podman/start.sh ./image-defs/podman/simpleist.containerfile

# you can see it running:
podman ps


# stop it
./scripts/podman/stop.sh ./image-defs/podman/simpleist.containerfile

# you can see it stopped:
podman ps -a
```

##### Podman Shutting it down

To shutdown podman's vm:

```sh
podman machine stop

# if it shutdown properly the followign will show some error:
podman info
```

#### LinuxKit: WORKS (sort of)

LinuxKit doesn't build containers, it builds executable Linux-based images that run in a variety of VM/hypervisor environments or in baremetal bootable images (🤯). Mac, Windows, and Linux all support VM/hypervisors so you can run the built images just about anywhere... Did I mention baremetal bios-bootable images!?

The images are built by specifying a raw linux kernal, some basic "init" packges, and then you reference standard OCI containers for anything else you want such as additional apps and services. It pulls them from dockerhub. Essentially it boostraps Linux, starts [containerd], [runc] and then it is a tiny Linux OS that can run containers!
Specify all this in [LinuxKit's image defintion yaml][linuxkit-yaml].

##### LinuxKit Example: simplest

This is the most simple example of a linuxkit image building and running.

```sh
# build a runnable VM image with linuxkit use:
./scripts/linuxkit/build.sh ./image-defs/linuxkit/simplest.yml

# Run the built VM image (this will generate a terminal):
./scripts/linuxkit/start.sh ./image-defs/linuxkit/simplest.yml

# Stop while running (from a different terminal on the host):
./scripts/linuxkit/stop.sh ./image-defs/linuxkit/simplest.yml

# you can also stop it within the terminal using alpine/busybox's poweroff command
poweroff -f

```

##### LinuxKit Example: ssh

```sh
# build a runnable VM image with linuxkit use:
./scripts/linuxkit/build.sh ./image-defs/linuxkit/sshd.yml

# Run the built VM image (this will producce a terminal into the vm):
./scripts/linuxkit/start.sh ./image-defs/linuxkit/sshd.yml -publish 2222:22

# From another terminal now you can ssh into it with (
# NOTE: If you get the "Host key verification failed" error aftering doing this once, you might need to run `ssh-keygen -R [localhost]:2222` to remove the old entry from your known_hosts)
ssh -p2222 root@localhost
```

#### LinuxKit Inspecting containerd containers...

Each service is it's own container with it's own layered filesystem. So some interesting things happen depending on the container/layer you're working with. For example in the tty terminal that appears after a `linuxkit run...`, is in the getty container and that one doesn't see the files added by subsequent layers? However, from that terminal you can run [ctr] like this to access one of the other containers `ctr -n services.linuxkit task exec -t --exec-id fooo sshd ls -la /root/`. In this command `sshd` is the container name (its a "service" in the sshd.yml file) and linuxkit by default puts services into a namespace named `services.linuxkit` so you have to specify that when dealing with `ctr`.

#### "Moby Build Tool" (N/A - see LinuxKit)

The `moby build` aka "moby tool" was merged into linuxkit presumably as the `linuxkit build` command: https://github.com/moby/tool

### [genuinetools/img][img]

[img] builds Dockerfiles to OCI images. Implemented as a CLI frontend for [BuildKit] backend. Kinda only runs on linux though so you have to run it in a container on macOS. [Instructions on their readme for using k8s or docker](https://github.com/genuinetools/img#running-with-docker).

### [BuildKit] (TODO)

BuildKit [seems sure to work for building images from Dockerfile](https://github.com/moby/buildkit#exploring-dockerfiles) and pushing images. However, it [requires buildkit daemon](https://github.com/moby/buildkit#starting-the-buildkitd-daemon) which requires [containerd] to be running and just looks generally complicated. It does have a homebrew install so maybe its not so bad.

### [buildpack] (TODO)

This looks to be an effort to replace Dockerfile as a definition of a container and instead use a OCI-image container to build an OCI-image from source.
Many buildpacks are at https://paketo.io/ and their docs have some examples of how to get started.

### 2. Running

#### [LinuxKit][linuxkit]+QEMU (WORKS)

##### Installing

The QEMU backend worked perfectly. Just install linuxkit with homebrew and qemu and done.

```sh
brew tap linuxkit/linuxkit
brew install --HEAD linuxkit # NOTE: `--HEAD` is important!
```

```sh
brew install qemu
```

Essentially it is `linuxkit run qemu simpleist` (where `simpleist` is the prefix used when building the image (inferred from the basename of the .yml file by default).

#### Building Images: LinuxKit (WORKS - sort of)

Just build them with `linuxkit build -format "kernel+initrd" ./simplest.yml` and it createst a set of files with `simplest-` in the same directory including the kernel, the raw disk image cmdline, etc.

#### LinuxKit+HyperKit (NOPE)

I couldn't get the HyperKit backend to work on macOS. The HyperKit backend just came up to the point where it said `[ 3.397123] clocksource: Switched to clocksource tsc` (twice) and it froze.
HyperKit also depends on [VPNKit] for to make networking work and VPNKit needs built to install and is a hassle to deal with for host networking _and_ QEMU works fine without any of that hassle so 🤷‍♂️.

#### Kubernetes [minikube] (WORKS)

These will definitely work with [`kubectl`][kubectl] and allow running locally as I use it to play with k8s. Similar to docker-compose files but different.

Not sure about perf compared to linuxkit+qemu. Also orchestrating multiple containers is definitely a job for minikube, linuxkit doesn't really handle much orchestration (although in simple cases arguably a bash file would be simple for dev scenarios).

#### Kubernetes [kind] (TODO)

Very similar to minikube but maybe more performant??

#### [`runc`][runc] (NOPE)

[runc] appears to allow running and managing containers fine on linux, but _only_ linux.

### Uploading

This shouldn't be that hard, there is a simple rest api IIRC I'm sure tools exist. If not, they should!

## References & Notes

[oci]: https://opencontainers.org/
[oci-bundle]: https://github.com/opencontainers/runtime-spec/tree/v1.0.0-rc2
[runc]: https://github.com/opencontainers/runc
[linuxkit]: https://github.com/linuxkit/linuxkit/
[vpnkit]: https://github.com/moby/vpnkit
[linuxkit-yaml]: https://github.com/linuxkit/linuxkit/blob/master/docs/yaml.md
[containerd]: https://github.com/containerd/containerd
[runc]: https://github.com/opencontainers/runc
[kubectl]: https://kubernetes.io/docs/reference/kubectl/overview/
[minikube]: https://minikube.sigs.k8s.io/docs/
[kind]: https://kind.sigs.k8s.io/
[buildkit]: https://github.com/moby/buildkit#exploring-dockerfiles
[buildpacks]: https://buildpacks.io/docs/concepts/
[img]: https://github.com/genuinetools/img
[ctr]: https://github.com/containerd/containerd/blob/main/cmd/ctr/app/main.go#L61
[podman]: https://github.com/containers/podman
