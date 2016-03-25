# Makefile for "Complex networks, complex processes"
#
# Copyright (C) 2014-2016 Simon Dobson
# 
# Licensed under the Creative Commons Attribution-Noncommercial-Share
# Alike 3.0 Unported License (https://creativecommons.org/licenses/by-nc-sa/3.0/).
#

# ----- Sources -----

# IPython notebooks in book order
HEADER = complex-networks-complex-processes.ipynb
NOTEBOOKS =  \
	preface.ipynb \
	introduction.ipynb \
	concepts.ipynb \
	er-networks.ipynb \
	percolation.ipynb \
	simulate.ipynb \
	powerlaw.ipynb \
	generating-networks.ipynb \
	spectral.ipynb \
	epidemic-spreading.ipynb \
	geodata.ipynb \
	parallel.ipynb \
	software.ipynb \
	acknowledgements.ipynb
BIB_NOTEBOOK_TEMPLATE = bibliography-template.ipynb

# Additional source files
BIB = complex-networks.bib

# Image files
RAW_IMAGES = \
	cc-at-nc-sa.png \
	qr.png \
	konigsberg-bridges.png
SVG_IMAGES = \
	ipython-parallelism.svg \
	ipython-local-parallelism.svg \
	ipython-local-parallelism-one.svg \
	ipython-mechanics.svg \
	disease-periods.svg \
	disease-types.svg
IMAGES = \
	$(RAW_IMAGES) \
	$(SVG_IMAGES:.svg=.pdf) \
	$(SVG_IMAGES:.svg=.png)

# Python packages in computational environments
PY_COMPUTATIONAL = \
	ipython \
	pyzmq \
	ipyparallel \
	numpy \
	scipy \
	mpmath \
	networkx \
	dill \
	paramiko
PY_INTERACTIVE = \
	$(PY_COMPUTATIONAL) \
	jupyter \
	pandas \
	matplotlib \
	seaborn \
	jsonschema \
	tornado \
	pygments \
	jinja2 \
	folium \
	beautifulsoup4 \
	mistune \
	pexpect

# Packages that shouldn't be saved as requirements (because they're
# OS-specific, in this case OS X, and screw up Linux compute servers)
PY_NON_REQUIREMENTS = \
	appnope

# Remote destinations
# (assumes the necessary keys are already installed)
REMOTE_USER = root
REMOTE_HOST = away.simondobson.org
REMOTE_DIR = /var/www/simondobson.org/complex-networks-complex-processes/content

# Timestamping
TIMESTAMP = `date "+%Y-%m-%d %H:%M"`
UPLOADED = UPLOADED.txt


# ----- Commands and options -----

# IPython and notebook functions
IPYTHON = ipython
JUPYTER = jupyter
SERVER = $(JUPYTER) notebook --port 1626
CONVERT = $(JUPYTER) nbconvert

# Other tools
PERL = perl
PYTHON = python
PIP = pip
VIRTUALENV = virtualenv
ACTIVATE = . bin/activate
RSYNC = rsync -av
BIB2X = $(PERL) ./bib2x --nodoi --visiblekeys --flat --sort
PANDOC = pandoc
INKSCAPE=inkscape
PDFLATEX = pdflatex --interaction batchmode
BIBTEX = bibtex
MAKE = make
RM = rm -fr
MKDIR = mkdir -p
CHDIR = cd
TR = tr
CP = cp -r
MV = mv
SED = sed -E
ZIP = zip
TAIL = tail

# Bibliography
BIB_HTML = $(BIB:.bib=.html)
BIB_TEX = $(BIB:.bib=.tex)
BIB_NOTEBOOK = bibliography.ipynb

# Web HTML output
HTML_BUILD = build/www
HTML_TEMPLATE = full
HTML_OPTIONS = --template $(HTML_TEMPLATE) 
HTML_STYLESHEET = custom.css
HTML_PLUGINS = JSAnimation
HTML_NOTEBOOKS = $(HEADER:.ipynb=.html) $(NOTEBOOKS:.ipynb=.html) $(BIB_NOTEBOOK:.ipynb=.html)
HTML_FILES = $(HTML_NOTEBOOKS)
HTML_EXTRAS = \
	$(HTML_STYLESHEET) \
	$(HTML_PLUGINS) \
	$(IMAGES)
WWW_POSTPROCESS = $(PYTHON) ./www-postprocess.py

# Zip'ped notebook output
ZIP_FILE = complex-networks-complex-processes.zip
ZIP_FILES = \
	$(HEADER) \
	$(NOTEBOOKS) \
	$(BIB_NOTEBOOK) $(BIB) \
	$(IMAGES) $(HTML_PLUGINS) \
	$(UPLOADED)

# PDF output
PDF_BUILD = build/pdf
PDF_TEMPLATE = complex-networks-complex-processes
PDF_OPTIONS = --template $(PDF_TEMPLATE)
PDF = complex-networks-complex-processes.pdf
PDF_SKELETON = complex-networks-complex-processes.tex
PDF_FRONTMATTER = front.tex
PDF_BACKMATTER = back.tex
PDF_NOTEBOOKS = $(NOTEBOOKS:.ipynb=.tex)
PDF_FILES = $(PDF_SKELETON) $(PDF_NOTEBOOKS) $(BIB_TEX)
PDF_EXTRAS = \
	$(UPLOADED) \
	$(BIB) \
	$(PDF_FRONTMATTER) $(PDF_BACKMATTER) \
	$(IMAGES)

# Computational environments and requirements
ENV_COMPUTATIONAL = cncp-compute
ENV_INTERACTIVE = cncp
REQ_COMPUTATIONAL = cncp-compute-requirements.txt
REQ_INTERACTIVE = cncp-requirements.txt
NON_REQUIREMENTS = $(SED) $(patsubst %, -e '/^%*/d', $(PY_NON_REQUIREMENTS))


# ----- Top-level targets -----

# Default prints a help message, since it's all a bit complicated
help:
	@make usage

# Build all the distributions of the book
all: zip www pdf

# Upload all versions of the book to web server
upload: upload-zip upload-www upload-pdf
	make clean-uploaded

# Build reproducible computational environments
env: env-computational env-interactive

# Update the dependencies for the computational environments
update: clean-env newenv-computational newenv-interactive

# Clean up the build
clean: clean-uploaded clean-bib clean-zip clean-www clean-pdf clean-env
	$(RM) $(HTML_NOTEBOOKS)
	$(RM) $(NOTEBOOKS:.ipynb=_files) 

# Run the notebook
live: env-interactive
	($(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(CHDIR) .. && $(SERVER)) &


# ----- Bibliography in a notebook -----

# Populate the bibliography template notebook
$(BIB_NOTEBOOK): $(BIB) $(BIB_HTML) $(BIB_NOTEBOOK_TEMPLATE)
	$(SED) -e 's/"/\\"/g' -e 's/.*/"&"/g' <$(BIB_HTML) >tmp1.html
	$(TAIL) -n +1 tmp1.html | ($(SED) -e 's/.*/&,/g' ; $(TAIL) -n 1 tmp1.html) >tmp2.html
	$(SED) -e '/%%BIBLIOGRAPHY%%/r tmp2.html' -e '/%%BIBLIOGRAPHY%%/d'  <$(BIB_NOTEBOOK_TEMPLATE) >$(BIB_NOTEBOOK)
	$(RM) tmp1.html tmp2.html

# Clean the generated notebook and LaTeX file
clean-bib:
	$(RM) $(BIB_NOTEBOOK) $(BIB_HTML) $(BIB_TEX)


# ----- Creation timestamp -----

# Generate a timestamp file
$(UPLOADED):
	echo "Last updated $(TIMESTAMP)" >$(UPLOADED)

# Clean the timestamp file
clean-uploaded:
	$(RM) $(UPLOADED)


# ----- Notebook (ZIP) distribution -----

# Package notebooks as a ZIP file
zip: $(ZIP_FILES)
	$(ZIP) $(ZIP_FILE) $(ZIP_FILES)

# Upload ZIP file of notebooks
upload-zip: zip $(UPLOADED)
	$(RSYNC) \
	$(ZIP_FILE) \
	$(UPLOADED) \
	$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)
	@make clean-uploaded

# Clean up the ZIP'ped notebooks
clean-zip:
	$(RM) $(ZIP_FILE)


# ----- Interactive HTML (www) distribution -----

# Pre-process notebooks to HTML
gen-www: $(HTML_FILES)

# Build HTML (web) versions of notebooks
www: env-interactive gen-www
	$(MKDIR) $(HTML_BUILD)
	($(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(CHDIR) .. && $(foreach fn, $(HTML_NOTEBOOKS), $(WWW_POSTPROCESS) $(fn) $(HTML_BUILD);))
	$(CP) $(HTML_EXTRAS) $(HTML_BUILD)

# Upload HTML version of book
upload-www: www $(UPLOADED)
	cd $(HTML_BUILD) && \
	$(RSYNC) \
	$(UPLOADED) \
	$(HTML_FILES) $(HTML_EXTRAS) \
	$(EXTRA_FILES) \
	$(HTML_STYLESHEET) $(HTML_PLUGINS) \
	$(UPLOADED) \
	$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)
	@make clean-uploaded

# Clean up the HTML book
clean-www:
	$(RM) $(HTML_BUILD)


# ----- PDF distribution -----

# PDF post-processing
gen-pdf: $(PDF_FILES) $(UPLOADED)
	$(MKDIR) $(PDF_BUILD)
	$(foreach dn, $(PDF_NOTEBOOKS:.tex=_files), if [ -d $(dn) ]; then $(CP) $(dn) $(PDF_BUILD); fi;)
	$(CP) $(PDF_FILES) $(PDF_EXTRAS) $(PDF_BUILD)

# Generate PDF file via LaTeX
pdf: env-interactive gen-pdf
	cd $(PDF_BUILD) && \
	$(PDFLATEX) $(PDF_SKELETON:.tex=) ; \
	$(PDFLATEX) $(PDF_SKELETON:.tex=) ; \
	exit 0

# Upload PDF version of book
upload-pdf: pdf $(UPLOADED)
	cd $(PDF_BUILD) && \
	$(RSYNC) \
	$(PDF) \
	$(UPLOADED) \
	$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)
	@make clean-uploaded

# Clean up the PDF build
clean-pdf:
	$(RM) $(PDF_NOTEBOOKS)
	$(RM) $(PDF_BUILD)


# ----- Computational environments -----

# Computation-only software
env-computational: $(ENV_COMPUTATIONAL)

newenv-computational:
	echo $(PY_COMPUTATIONAL) | $(TR) ' ' '\n' >$(REQ_COMPUTATIONAL)
	make env-computational
	$(NON_REQUIREMENTS) $(ENV_COMPUTATIONAL)/requirements.txt >$(REQ_COMPUTATIONAL)

# Interactive software
env-interactive: $(ENV_INTERACTIVE)

newenv-interactive:
	echo $(PY_INTERACTIVE) | $(TR) ' ' '\n' >$(REQ_INTERACTIVE)
	make env-interactive
	$(NON_REQUIREMENTS) $(ENV_INTERACTIVE)/requirements.txt >$(REQ_INTERACTIVE)

# Only re-build computational environment if the directory is missing
$(ENV_COMPUTATIONAL):
	$(VIRTUALENV) $(ENV_COMPUTATIONAL)
	$(CP) $(REQ_COMPUTATIONAL) $(ENV_COMPUTATIONAL)/requirements.txt
	$(CHDIR) $(ENV_COMPUTATIONAL) && $(ACTIVATE) && $(PIP) install -r requirements.txt && $(PIP) freeze >requirements.txt

# Only re-build interactive environment if the directory is missing
$(ENV_INTERACTIVE):
	$(VIRTUALENV) $(ENV_INTERACTIVE)
	$(CP) $(REQ_INTERACTIVE) $(ENV_INTERACTIVE)/requirements.txt
	$(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(PIP) install -r requirements.txt && $(PIP) freeze >requirements.txt
	@make mathjax

# Install a local copy of MathJax so notebooks can work without a network connection
define PY_INSTALL_MATHJAX
import IPython
from IPython.external import mathjax

mathjax.install_mathjax()
endef
export PY_INSTALL_MATHJAX

mathjax:
	($(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(IPYTHON) -c "$$PY_INSTALL_MATHJAX")


# Clean-up the generated environments
clean-env:
	$(RM) $(ENV_COMPUTATIONAL) $(ENV_INTERACTIVE)


# ----- Construction rules -----

.SUFFIXES: .ipynb .bib .html .tex .md .svg .pdf .png

.ipynb.html:
	($(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(CHDIR) .. && $(CONVERT) --to html $(HTML_OPTIONS) $<)

.ipynb.tex:
	($(CHDIR) $(ENV_INTERACTIVE) && $(ACTIVATE) && $(CHDIR) .. && $(CONVERT) --to latex $(PDF_OPTIONS) $<)

.ipynb.md:
	$(CONVERT) --to markdown $<

.bib.html:
	$(BIB2X) --html --barebones $(BIB) >$(BIB_HTML)

.bib.tex:
	$(BIB2X) --latex $(BIB) >$(BIB_TEX)

.svg.pdf:
	$(INKSCAPE) $*.svg --export-pdf=$*.pdf


# ----- Usage -----

define HELP_MESSAGE
Building the book:
   make all     build all versions
   make www     build the HTML version only
   make pdf     build the PDF version only
   make zip     zip-up the version

Publishing:
   make upload  upload all version to web site (needs the keys)

Maintenance:
   make clean   clean-up for a clean build

Running the code:
   make env     build virtualenvs using repo requirements.txt
   make update  update requirements.txt and build virtualenvs
   make live    run notebook in interactive virtualenv
endef
export HELP_MESSAGE

usage:
	@echo "$$HELP_MESSAGE"
