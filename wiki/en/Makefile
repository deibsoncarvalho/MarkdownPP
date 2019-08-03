# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
BOARD		  = 
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build
MDPP          = /home/firefly/miniconda3/bin/markdown-pp
MDPP_TARGET   = $(addsuffix .md,$(basename $(wildcard *.mdpp)))
TPL_TARGET	  = $(basename $(wildcard *.tpl))


.PHONY: all help test Makefile FORCE_MAKE mdpp


# Put it first so that "make" without argument is like "make html".
all: html

help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
html latex: check Makefile mdpp tpl
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

check:
ifeq ($(BOARD),)
	$(error "=================== error: Have not indicate BOARD ===================")
endif

tpl: $(TPL_TARGET)

mdpp: $(MDPP_TARGET)

%: %.tpl FORCE_MAKE
	@$(MDPP) -f ../json/common.json -f ../json/$(BOARD).json -e latexrender $< -o $@
	

%.md: %.mdpp FORCE_MAKE
	@$(MDPP) -f ../json/common.json -f ../json/$(BOARD).json -I include/$(BOARD) -e latexrender $< -o $@

pdf: latex
	rm -f "$(BUILDDIR)"/latex/*.pdf
	make -C "$(BUILDDIR)"/latex PDFLATEX="xelatex" LATEXMKOPTS="-interaction=nonstopmode" all || :
	make -C "$(BUILDDIR)"/latex PDFLATEX="xelatex" LATEXMKOPTS="-interaction=nonstopmode" all || :
	ls "$(BUILDDIR)"/latex/*.pdf

clean:
	rm -rf "$(BUILDDIR)"
	rm -f $(MDPP_TARGET) $(TPL_TARGET) temp
