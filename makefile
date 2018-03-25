# {{{ -- meta

HOSTARCH  := x86_64# on travis.ci
ARCH      := $(shell uname -m | sed "s_armv7l_armhf_")# armhf/x86_64 auto-detect on build and run
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := mpd
USERNAME  := woahbase

PUID       := $(shell id -u)
PGID       := $(shell id -g)# gid 100(users) usually pre exists

DOCKERSRC := $(OPSYS)-s6#
DOCKEREPO := $(OPSYS)-$(SVCNAME)
IMAGETAG  := $(USERNAME)/$(DOCKEREPO):$(ARCH)

CNTNAME   := $(SVCNAME) # name for container name : docker_name, hostname : name

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm --compress -f $(CURDIR)/Dockerfile_$(ARCH) -t $(IMAGETAG) \
	--build-arg ARCH=$(ARCH) \
	--build-arg DOCKERSRC=$(DOCKERSRC) \
	--build-arg USERNAME=$(USERNAME) \
	--build-arg PUID=$(PUID) \
	--build-arg PGID=$(PGID) \
	--label org.label-schema.build-date=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
	--label org.label-schema.name=$(DOCKEREPO) \
	--label org.label-schema.schema-version="1.0" \
	--label org.label-schema.url="https://woahbase.online/" \
	--label org.label-schema.usage="https://woahbase.online/\#/images/$(DOCKEREPO)" \
	--label org.label-schema.vcs-ref=$(shell git rev-parse --short HEAD) \
	--label org.label-schema.vcs-url="https://github.com/$(USERNAME)/$(DOCKEREPO)" \
	--label org.label-schema.vendor=$(USERNAME)

CACHEFLAGS := --no-cache=true --pull
MOUNTFLAGS := -v $(CURDIR)/music:/var/lib/mpd/music -v $(CURDIR)/data:/var/lib/mpd
NAMEFLAGS  := --name docker_$(CNTNAME) --hostname $(CNTNAME)
OTHERFLAGS := -v /etc/hosts:/etc/hosts:ro -v /etc/localtime:/etc/localtime:ro # -e TZ=Asia/Kolkata
PORTFLAGS  := -p 6600:6600 -p 8000:8000 -p 64801:64801
PROXYFLAGS := --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) --build-arg no_proxy=$(no_proxy)

RUNFLAGS   := -c 256 -m 256m -e PGID=$(PGID) -e PUID=$(PUID) \
		-e PULSE_SERVER=localhost
		# -e PULSE_SERVER=unix:/run/user/$(PUID)/pulse/native \
		-v /run/user/$(PUID)/pulse:/run/user/$(PUID)/pulse \
		-v /dev/shm:/dev/shm \
		-v $(HOME)/.pulse-cookie:/home/mpd/.pulse-cookie
		# --device /dev/snd

# -- }}}

# {{{ -- docker targets

all : run

build :
	echo "Building for $(ARCH) from $(HOSTARCH)";
	if [ "$(ARCH)" != "$(HOSTARCH)" ]; then make regbinfmt ; fi;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) $(PROXYFLAGS) .

clean :
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep "$(USERNAME)/$(DOCKEREPO)" | xargs -n1 docker rmi

logs :
	docker logs -f docker_$(CNTNAME)

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG); \
	if [ "$(ARCH)" = "$(HOSTARCH)" ]; \
		then \
		LATESTTAG=$$(echo $(IMAGETAG) | sed 's/:$(ARCH)/:latest/'); \
		docker tag $(IMAGETAG) $${LATESTTAG}; \
		docker push $${LATESTTAG}; \
	fi;

restart :
	docker ps -a | grep 'docker_$(CNTNAME)' -q && docker restart docker_$(CNTNAME) || echo "Service not running.";

rm : stop
	docker rm -f docker_$(CNTNAME)

run :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG)

player :
	docker exec -it docker_$(CNTNAME) ncmpcpp

rshell :
	docker exec -u root -it docker_$(CNTNAME) $(SHCOMMAND)

shell :
	docker exec -it docker_$(CNTNAME) $(SHCOMMAND)

stop :
	docker stop -t 2 docker_$(CNTNAME)

test :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) --entrypoint sh $(IMAGETAG) -ec 'mpd --version; ncmpcpp --version; ympd --version'

# -- }}}

# {{{ -- other targets

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

# -- }}}
