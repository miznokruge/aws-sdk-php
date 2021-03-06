help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean          to delete all Makefile artifacts"
	@echo "  clear-cache    to clear the cached JSON compiled SDK files"
	@echo "  test           to perform unit tests.  Provide TEST to perform a specific test."
	@echo "  coverage       to perform unit tests with code coverage. Provide TEST to perform a specific test."
	@echo "  coverage-show  to show the code coverage report"
	@echo "  integ          to run integration tests. Provide TEST to perform a specific test."
	@echo "  guide          to build the user guide documentation"
	@echo "  guide-show     to view the user guide"
	@echo "  api            to build the API documentation"
	@echo "  api-show       to view the API documentation"
	@echo "  api-package    to build the API documentation as a ZIP"
	@echo "  api-manifest   to build an API manifest JSON file for the SDK"
	@echo "  package        to package a phar and zip file for a release"
	@echo "  check-tag      to ensure that the TAG argument was passed"
	@echo "  tag            to chag tag a release based on the changelog. Must provide a TAG"
	@echo "  release        to package the release and push it to GitHub. Must provide a TAG"
	@echo "  full-release   to tag, package, and release the SDK. Provide TAG"

clean: clear-cache
	rm -rf build/artifacts/*
	cd docs && make clean

clear-cache:
	php build/aws-clear-cache.php

test:
	@AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar \
	vendor/bin/phpunit --testsuite=unit $(TEST)

coverage:
	@AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar \
	vendor/bin/phpunit --testsuite=unit --coverage-html=build/artifacts/coverage $(TEST)

coverage-show:
	open build/artifacts/coverage/index.html

integ:
	vendor/bin/phpunit --debug --testsuite=integ $(TEST)

# Packages the phar and zip
package:
	php build/packager.php $(SERVICE)

guide:
	cd docs && make html

guide-show:
	open docs/_build/html/index.html

api-get-apigen:
	mkdir -p build/artifacts
	[ -f build/artifacts/apigen.phar ] || wget -q -O build/artifacts/apigen.phar https://github.com/ApiGen/ApiGen/releases/download/v4.1.0/apigen-4.1.0.phar

api: api-get-apigen
	# Build the package if necessary.
	[ -d build/artifacts/staging ] || make package
	# Delete a previously built API build to avoid the prompt.
	rm -rf build/artifacts/docs
	php build/artifacts/apigen.phar generate --config build/docs/apigen.neon --debug
	make api-models

api-models:
	# Build custom docs
	php build/docs.php

api-show:
	open build/artifacts/docs/index.html

api-package:
	zip -r build/artifacts/aws-docs-api.zip build/artifacts/docs/build

api-manifest:
	php build/build-manifest.php
	make clear-cache

# Ensures that the TAG variable was passed to the make command
check-tag:
	$(if $(TAG),,$(error TAG is not defined. Pass via "make tag TAG=4.2.1"))

# Creates a release but does not push it. This task updates the changelog
# with the TAG environment variable, replaces the VERSION constant, ensures
# that the source is still valid after updating, commits the changelog and
# updated VERSION constant, creates an annotated git tag using chag, and
# prints out a diff of the last commit.
tag: check-tag
	@echo Tagging $(TAG)
	chag update $(TAG)
	sed -i '' -e "s/VERSION = '.*'/VERSION = '$(TAG)'/" src/Sdk.php
	php -l src/Sdk.php
	git commit -a -m '$(TAG) release'
	chag tag
	@echo "Release has been created. Push using 'make release'"
	@echo "Changes made in the release commit"
	git diff HEAD~1 HEAD

# Creates a release based on the master branch and latest tag. This task
# pushes the latest tag, pushes master, creates a phar and zip, and creates
# a Github release. Use "TAG=X.Y.Z make tag" to create a release, and use
# "make release" to push a release. This task requires that the
# OAUTH_TOKEN environment variable is available and the token has permission
# to push to the repository.
release: check-tag package
	git push origin master
	git push origin $(TAG)
	php build/gh-release.php $(TAG)

# Tags the repo and publishes a release.
full_release: tag release

.PHONY: help clean test coverage coverage-show integ package \
guide guide-show api-get-apigen api api-show api-package api-manifest \
check-tag tag release full-release clear-cache
