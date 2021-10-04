# Docker Alternatives Investigation

Docker desktop on Mac has become bloated and most of all extremely anoying. Apparently they company has decided to anoy you into paying by prompting nearly every day to pause what you're doing and upgrade to a new version that has nothing you're interested in or pay to stop the anoying and interrupting prompts. Good luck with that. I'm sure somebody loves that colorful UI up there, but I use docker exclusively in the shell and scripts on my dev box, so it's also become rather anoying to be blinking up there all the time anyway.

So... are there reasonable alternatives?

## Goals

The goals of this investigation are to see if I can feasibly replace the following on macOS:

1. The ability to **build** Dockerfile's to [OCI][oci]-compliant [images][oci-bundle].
2. The ability to **run** OCI-compliant images (with _at least_ host-local networking and ability to tty to running container).
3. The ability to upload OCI-compliant images to Dockerhub and/or Github or other container registries (lower priority)

## Alternative Exploration

### 1. Building

#### LinuxKit: WORKS (sort of)

LinuxKit doesn't build containers, it builds executable Linux-based images that run in a variety of VM/hypervisor environments or in baremetal bootable images (🤯). Mac, Windows, and Linux all support VM/hypervisors so you can run the built images just about anywhere... Did I mention baremetal bios-bootable images!?

The images are built by specifying a raw linux kernal, some basic "init" packges, and then you reference standard OCI containers for anything else you want such as additional apps and services. It pulls them from dockerhub. Essentially it boostraps Linux, starts [containerd], [runc] and then it is a tiny Linux OS that can run containers!
Specify all this in [LinuxKit's image defintion yaml][linuxkit-yaml].

##### LinuxKit Cheat Sheet

```sh
# build a runnable VM image with linuxkit use:
./scripts/linuxkit/build.sh ./image-defs/linuxkit/simplest.yml

# Run the built VM image (this will generate a terminal):
./scripts/linuxkit/start.sh ./image-defs/linuxkit/simplest.yml

# Stop while running:
./scripts/linuxkit/stop.sh ./image-defs/linuxkit/simplest.yml
```

- [ ] TODO: Although linuxkit doesn't run OCI containers, it is fundamentally a linux VM with [containerd] and [`ctr`] (I cannot find docs on `ctr` but it is a command that allow dealing with containers on containerd hosts and is in the linuxkit VMs). So conceivably we could figure out a way to run OCI images on a linuxkit-vm locally (I _)_think_ that's effectively what Docker for Mac does).

- [ ] TODO: add example to to make it run an image with a designated commmand and immediately exit and return the result to host (e.g. useful for running tests, i don't think this is an issue just want to add an example).
- [ ] TODO: add example with host-local networking to allow host or other containers to hit a service running in the VM.

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

#### Building Images: LinuxKit (WORKS)

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