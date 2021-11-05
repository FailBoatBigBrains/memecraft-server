SHELL := /bin/bash

COMPOSER=podman
CURRENT_PWD=$(shell pwd)
CURRENT_DIR=$(shell basename $(CURRENT_PWD))
POD_NAME=memecraft-pod
MINECRAFT_SERVICE_NAME=service-minecraft
MINECRAFT_VOLUME_NAME=$(CURRENT_DIR)_$(MINECRAFT_SERVICE_NAME)_volume


print-%  : ; @echo $($*)


################################################################################
# Dev container commands
################################################################################
create.pod:
	-$(COMPOSER) \
	pod \
	create \
	--publish=25565:25565 \
	--name=$(POD_NAME)

create.memecraft:
	test -d dumps || mkdir --mode=0755 dumps
	-$(COMPOSER) \
	run \
	--detach=true \
	--env=EULA="TRUE" \
	--name=$(MINECRAFT_SERVICE_NAME) \
	--pod=$(POD_NAME) \
	--volume=$(MINECRAFT_VOLUME_NAME):/data \
	--volume=$(CURRENT_PWD)/dumps:/dumps \
	itzg/minecraft-server

create: create.pod create.memecraft

up: create
	$(COMPOSER) pod start $(POD_NAME)

up.logs: up logs

stop:
	$(COMPOSER) pod stop --ignore $(POD_NAME)

rm:
	$(COMPOSER) pod rm --ignore $(args) $(POD_NAME)
	$(COMPOSER) rm --ignore $(args) $(MINECRAFT_SERVICE_NAME)

down: stop rm

restart: down up.logs

logs:
	$(COMPOSER) logs --follow=true --names $(MINECRAFT_SERVICE_NAME)

bash:
	$(COMPOSER) exec --interactive=true --tty=true $(MINECRAFT_SERVICE_NAME) bash

remove.volumes: down
	-$(COMPOSER) volume rm --force $(MINECRAFT_VOLUME_NAME)

dump:
	-$(COMPOSER) exec $(MINECRAFT_SERVICE_NAME) bash -c "rsync -r /data/* /dumps"

restore:
	-$(COMPOSER) exec $(MINECRAFT_SERVICE_NAME) bash -c "rsync -r /dumps/* /data"

ngrok:
	ngrok tcp 25565
