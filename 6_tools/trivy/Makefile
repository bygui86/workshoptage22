
.PHONY: help print-variables
.DEFAULT_GOAL = help


build-insecure :		## Build insecure container image
	docker build . -f dockerfiles/insecure.Dockerfile -t insecure:debian-bullseye

build-insecure-no-cache :		## Build insecure container image ignoring cache
	docker build . -f dockerfiles/insecure.Dockerfile -t insecure:debian-bullseye --no-cache

build-secure :		## Build secure container image
	docker build . -f dockerfiles/secure.Dockerfile -t secure:alpine-3.16.2

build-secure-no-cache :		## Build secure container image ignoring cache
	docker build . -f dockerfiles/secure.Dockerfile -t secure:alpine-3.16.2 --no-cache


help :		## Help
	@echo ""
	@echo "*** \033[33mMakefile help\033[0m ***"
	@echo ""
	@echo "Targets list:"
	@grep -E '^[a-zA-Z_-]+ :.*?## .*$$' $(MAKEFILE_LIST) | sort -k 1,1 | awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""

print-variables :		## Print variables values
	@echo ""
	@echo "*** \033[33mMakefile variables\033[0m ***"
	@echo ""
	@echo "- - - makefile - - -"
	@echo "MAKE: $(MAKE)"
	@echo "MAKEFILES: $(MAKEFILES)"
	@echo "MAKEFILE_LIST: $(MAKEFILE_LIST)"
	@echo "- - -"
	@echo ""
