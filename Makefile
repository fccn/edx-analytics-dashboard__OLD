ROOT = $(shell echo "$$PWD")
COVERAGE = $(ROOT)/build/coverage
PACKAGES = analytics_dashboard courses

requirements:
	pip install -q -r requirements/base.txt --exists-action w

test.requirements: requirements
	pip install -q -r requirements/test.txt --exists-action w

develop: test.requirements
	pip install -q -r requirements/local.txt --exists-action w

syncdb:
	cd analytics_dashboard && ./manage.py syncdb --migrate

clean:
	find . -name '*.pyc' -delete
	coverage erase

test_python: clean
	cd analytics_dashboard && ./manage.py test --settings=analytics_dashboard.settings.test \
		--exclude-dir=analytics_dashboard/settings --with-coverage --cover-inclusive --cover-branches \
		--cover-html --cover-html-dir=$(COVERAGE)/html/ \
		--cover-xml --cover-xml-file=$(COVERAGE)/coverage.xml \
		$(foreach package,$(PACKAGES),--cover-package=$(package)) \
		$(PACKAGES)

accept:
	python -m unittest discover acceptance_tests


quality:
	pep8 --config=.pep8 analytics_dashboard
	cd analytics_dashboard && pylint --rcfile=../.pylintrc $(PACKAGES)

	# Ignore module level docstrings and all test files
	#cd analytics_dashboard && pep257 --ignore=D100,D203 --match='(?!test).*py' $(PACKAGES)

validate_python: test.requirements test_python quality

validate_js:
	npm install
	gulp

validate: validate_python validate_js

demo:
	cd analytics_dashboard && ./manage.py switch show_engagement_demo_interface on --create
	cd analytics_dashboard && ./manage.py switch navbar_display_overview on --create
	cd analytics_dashboard && ./manage.py switch navbar_display_engagement on --create
