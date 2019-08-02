[![build status][251]][232] [![commit][255]][231] [![version:x86_64][256]][235] [![size:x86_64][257]][235] [![version:armhf][258]][236] [![size:armhf][259]][236] [![version:armv7l][260]][237] [![size:armv7l][261]][237] [![version:aarch64][262]][238] [![size:aarch64][263]][238]

## [Alpine-MPD][234]
#### Container for Alpine Linux + Music Player Daemon + yMPD
---

This [image][233] containerizes the [Music Player Daemon][135] to
setup a centralized wifi controlled local music playing service.
Compatible with [ALSA][136] but defaults to [PulseAudio][137]
server running either on the host machine, or remotely somewhere
in the network. Also includes [yMPD][138] for managing music via
the browser, or via CLI using [NcmpCPP][139].

Based on [Alpine Linux][131] from my [alpine-s6][132] image with
the [s6][133] init system [overlayed][134] in it.

The image is tagged respectively for the following architectures,
* **armhf**
* **armv7l**
* **aarch64**
* **x86_64** (retagged as the `latest` )

**non-x86_64** builds have embedded binfmt_misc support and contain the
[qemu-user-static][105] binary that allows for running it also inside
an x86_64 environment that has it.

---
#### Get the Image
---

Pull the image for your architecture it's already available from
Docker Hub.

```
# make pull
docker pull woahbase/alpine-mpd:x86_64
```

---
#### Configuration Defaults
---

* Config file mounted at `/etc/mpd.conf` edit or remount this
  with your own. Data stored at `/var/lib/mpd`.

* Mount the music root dir at `/var/lib/mpd/music`.

* Mount playlists at `/var/lib/mpd/playlists`.

* Default configuration listens to ports `6600` and `8000`, with
  the webui running on port `64801`.

* This images already has a user `mpd` configured to drop
  privileges to the passed `PUID`/`PGID` which is ideal if its
  used to run in non-root mode. That way you only need to specify
  the values at runtime and pass the `-u mpd` if need be. (run
  `id` in your terminal to see your own `PUID`/`PGID` values.)

* Default configuration forces the ALSA plugin to coerce to
  PulseAudio. Need to modify `/etc/asound.conf` as well as
  `/etc/mpd.conf` to use ALSA device directly.

* The remote pulse server should allow `anonymous connections` if
  using without a cookie. ( Not really secure outside of a LAN)

---
#### Run
---

If you want to run images for other architectures, you will need
to have binfmt support configured for your machine. [**multiarch**][104],
has made it easy for us containing that into a docker container.

```
# make regbinfmt
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Without the above, you can still run the image that is made for your
architecture, e.g for an x86_64 machine..

Running `make` starts the service.

If you're running the pulseaudio server on the host system, you
can use the pulse server directly by mounting it inside the
container

```
# make
docker run --rm -it \
  --name docker_mpd --hostname mpd \
  -c 256 -m 256m \
  -e PGID=1000 -e PUID=1000 \
  -e PULSE_SERVER=unix:/run/user/$(PUID)/pulse/native \
  -v /run/user/$(PUID)/pulse:/run/user/$(PUID)/pulse \
  -v /dev/shm:/dev/shm \
  -v $(HOME)/.pulse-cookie:/home/mpd/.pulse-cookie
  -p 6600:6600 \
  -p 8000:8000 \
  -p 64801:64801 \
  -v music:/var/lib/mpd/music \
  -v data:/var/lib/mpd \
  woahbase/alpine-mpd:x86_64
```

or, use a remote pulseaudio standalone server running on
a different device. ( checkout [alpine-pulseaudio][140] to run
PulseAudio as a service )

```
# make
docker run --rm -it \
  --name docker_mpd --hostname mpd \
  -c 256 -m 256m \
  -e PGID=1000 -e PUID=1000 \
  -e PULSE_SERVER=localhost \
  -p 6600:6600 \
  -p 8000:8000 \
  -p 64801:64801 \
  -v music:/var/lib/mpd/music \
  -v data:/var/lib/mpd \
  woahbase/alpine-mpd:x86_64
```

Stop the container with a timeout, (defaults to 2 seconds)

```
# make stop
docker stop -t 2 docker_mpd
```

Removes the container, (always better to stop it first and `-f`
only when needed most)

```
# make rm
docker rm -f docker_mpd
```

Restart the container with

```
# make restart
docker restart docker_mpd
```

---
#### Shell access
---

Get a shell inside a already running container,

```
# make debug
docker exec -it docker_mpd /bin/bash
```

set user or login as root,

```
# make rdebug
docker exec -u root -it docker_mpd /bin/bash
```

To check logs of a running container in real time

```
# make logs
docker logs -f docker_mpd
```

---
### Development
---

If you have the repository access, you can clone and
build the image yourself for your own system, and can push after.

---
#### Setup
---

Before you clone the [repo][231], you must have [Git][101], [GNU make][102],
and [Docker][103] setup on the machine.

```
git clone https://github.com/woahbase/alpine-mpd
cd alpine-mpd
```
You can always skip installing **make** but you will have to
type the whole docker commands then instead of using the sweet
make targets.

---
#### Build
---

You need to have binfmt_misc configured in your system to be able
to build images for other architectures.

Otherwise to locally build the image for your system.
[`ARCH` defaults to `x86_64`, need to be explicit when building
for other architectures.]

```
# make ARCH=x86_64 build
# sets up binfmt if not x86_64
docker build --rm --compress --force-rm \
  --no-cache=true --pull \
  -f ./Dockerfile_x86_64 \
  --build-arg DOCKERSRC=woahbase/alpine-s6:x86_64 \
  --build-arg PGID=1000 \
  --build-arg PUID=1000 \
  -t woahbase/alpine-mpd:x86_64 \
  .
```

To check if its working..

```
# make ARCH=x86_64 test
docker run --rm -it \
  --name docker_mpd --hostname mpd \
  -e PGID=1000 -e PUID=1000 \
  --entrypoint sh \
  woahbase/alpine-mpd:x86_64 \
  -ec 'mpd --version; ncmpcpp --version; ympd --version'
```

And finally, if you have push access,

```
# make ARCH=x86_64 push
docker push woahbase/alpine-mpd:x86_64
```

---
### Maintenance
---

Sources at [Github][106]. Built at [Travis-CI.org][107] (armhf / x64 builds). Images at [Docker hub][108]. Metadata at [Microbadger][109].

Maintained by [WOAHBase][204].

[101]: https://git-scm.com
[102]: https://www.gnu.org/software/make/
[103]: https://www.docker.com
[104]: https://hub.docker.com/r/multiarch/qemu-user-static/
[105]: https://github.com/multiarch/qemu-user-static/releases/
[106]: https://github.com/
[107]: https://travis-ci.org/
[108]: https://hub.docker.com/
[109]: https://microbadger.com/

[131]: https://alpinelinux.org/
[132]: https://hub.docker.com/r/woahbase/alpine-s6
[133]: https://skarnet.org/software/s6/
[134]: https://github.com/just-containers/s6-overlay
[135]: https://www.musicpd.org/
[136]: https://www.alsa-project.org/
[137]: https://www.freedesktop.org/wiki/Software/PulseAudio/
[138]: https://github.com/notandy/ympd
[139]: https://github.com/arybczak/ncmpcpp
[140]: https://hub.docker.com/r/woahbase/alpine-pulseaudio

[201]: https://github.com/woahbase
[202]: https://travis-ci.org/woahbase/
[203]: https://hub.docker.com/u/woahbase
[204]: https://woahbase.online/

[231]: https://github.com/woahbase/alpine-mpd
[232]: https://travis-ci.org/woahbase/alpine-mpd
[233]: https://hub.docker.com/r/woahbase/alpine-mpd
[234]: https://woahbase.online/#/images/alpine-mpd
[235]: https://microbadger.com/images/woahbase/alpine-mpd:x86_64
[236]: https://microbadger.com/images/woahbase/alpine-mpd:armhf
[237]: https://microbadger.com/images/woahbase/alpine-mpd:armv7l
[238]: https://microbadger.com/images/woahbase/alpine-mpd:aarch64

[251]: https://travis-ci.org/woahbase/alpine-mpd.svg?branch=master

[255]: https://images.microbadger.com/badges/commit/woahbase/alpine-mpd.svg

[256]: https://images.microbadger.com/badges/version/woahbase/alpine-mpd:x86_64.svg
[257]: https://images.microbadger.com/badges/image/woahbase/alpine-mpd:x86_64.svg

[258]: https://images.microbadger.com/badges/version/woahbase/alpine-mpd:armhf.svg
[259]: https://images.microbadger.com/badges/image/woahbase/alpine-mpd:armhf.svg

[260]: https://images.microbadger.com/badges/version/woahbase/alpine-mpd:armv7l.svg
[261]: https://images.microbadger.com/badges/image/woahbase/alpine-mpd:armv7l.svg

[262]: https://images.microbadger.com/badges/version/woahbase/alpine-mpd:aarch64.svg
[263]: https://images.microbadger.com/badges/image/woahbase/alpine-mpd:aarch64.svg
