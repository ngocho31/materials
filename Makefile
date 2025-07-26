# See the README file for usage instructions

# SELF_CALL avoids checking other instances, which fails with --jobs > 1.
# https://gitlab.com/inkscape/inkscape/-/issues/4716#note_1898150983
INKSCAPE = SELF_CALL=true inkscape
PDFLATEX = xelatex
DIA      = dia
EPSTOPDF = epstopdf

INKSCAPE_IS_NEW = $(shell $(INKSCAPE) --version | grep -q "^Inkscape 1" && echo YES)

ifeq ($(INKSCAPE_IS_NEW),YES)
INKSCAPE_PDF_OPT = -o
else
INKSCAPE_PDF_OPT = -A
endif

# Needed macros
UPPERCASE = $(shell echo $1 | tr "[:lower:]-" "[:upper:]_")

# To insert a separator
define sep


endef

include $(wildcard mk/*.mk mk/**/*.mk)

# Output directory
OUTDIR   = $(shell pwd)/out

# Latex variable definitions
VARS = $(OUTDIR)/vars

# Environment for pdflatex, which allows it to find the stylesheet in the
# common/ directory.
PDFLATEX_ENV = TEXINPUTS=.:$(shell pwd):$(shell pwd)/common/sty: texfot --tee /tmp/fot.`id -u`

# Arguments passed to pdflatex
PDFLATEX_OPT = -shell-escape -file-line-error -halt-on-error

# The common slide stylesheet
STYLESHEET = common/sty/beamerthemePersonal.sty

#
# === Picture lookup ===
#

# Function that computes the list of pictures of the extension given
# in $(2) from the directories in $(1), and transforms the filenames
# in .pdf in the output directory. This is used to compute the list of
# .pdf files that need to be generated from .dia or .svg files.
PICTURES_WITH_TRANSFORMATION = \
	$(patsubst %.$(2),$(OUTDIR)/%.pdf,$(foreach s,$(1),$(wildcard $(s)/*.$(2) $(s)/**/*.$(2))))

# Function that computes the list of pictures of the extension given
# in $(2) from the directories in $(1). This is used for pictures that
# to not need any transformation, such as bitmap files in the .png or
# .jpg formats.
PICTURES_NO_TRANSFORMATION = \
	$(patsubst %,$(OUTDIR)/%,$(foreach s,$(1),$(wildcard $(s)/*.$(2) $(s)/**/*.$(2))))

# Function that computes the list of pictures from the directories in
# $(1) and returns output filenames in the output directory.
PICTURES = \
	$(call PICTURES_WITH_TRANSFORMATION,$(1),svg) \
	$(call PICTURES_WITH_TRANSFORMATION,$(1),dia) \
	$(call PICTURES_NO_TRANSFORMATION,$(1),png)   \
	$(call PICTURES_NO_TRANSFORMATION,$(1),jpg)   \
	$(call PICTURES_NO_TRANSFORMATION,$(1),pdf)

# List of common pictures
COMMON_PICTURES   = $(call PICTURES,common/pictures)

#
# === Compilation of slides ===
#

# This rule allows to build slides of the training. It is done in two
# parts with make calling itself because it is not possible to compute
# a list of prerequisites depending on the target name. See
# https://stackoverflow.com/questions/3381497/dynamic-targets-in-makefiles
# for details.
#
# The value of slide can be "full-kernel", "full-sysdev" (for the
# complete trainings) or the name of an individual chapter.
ifdef SLIDES
ifeq ($(firstword $(subst -, , $(SLIDES))),full)
SLIDES_MATERIALS     = $(strip $(subst -slides, , $(subst full-, , $(SLIDES))))
SLIDES_VARSFILE      = common/slides-vars/$(SLIDES_MATERIALS)-slides-vars.tex
SLIDES_CHAPTERS      = $($(call UPPERCASE, $(subst  -,_, $(SLIDES_MATERIALS)))_SLIDES)
SLIDES_HEADER        = common/slide-header.tex
SLIDES_FOOTER        = common/slide-footer.tex
else
SLIDES_MATERIALS     = $(firstword $(subst -, , $(SLIDES)))
SLIDES_VARSFILE      = common/slides-vars/single-slides-vars.tex
SLIDES_CHAPTERS      = $(SLIDES)
SLIDES_HEADER        = common/slide-header.tex
SLIDES_FOOTER        = common/slide-footer.tex
endif

MATERIALS             = $(SLIDES_MATERIALS)

# Compute the set of corresponding .tex files and pictures
SLIDES_TEX      = \
	$(SLIDES_VARSFILE) \
	$(SLIDES_HEADER) \
	$(foreach s,$(SLIDES_CHAPTERS),$(wildcard slides/$(s)/$(s).tex)) \
	$(SLIDES_FOOTER)
SLIDES_PICTURES = $(call PICTURES,$(foreach s,$(SLIDES_CHAPTERS),slides/$(s))) $(COMMON_PICTURES)

# Check for all slides .tex file to exist
$(foreach file,$(SLIDES_TEX),$(if $(wildcard $(file)),,$(error Missing file $(file) !)))

%-slides.pdf: $(VARS) $(SLIDES_TEX) $(SLIDES_PICTURES) $(STYLESHEET) $(OUTDIR)/last-update.tex
	@mkdir -p $(OUTDIR)
# We generate a .tex file with \input{} directives (instead of just
# concatenating all files) so that when there is an error, we are
# pointed at the right original file and the right line in that file.
	rm -f $(OUTDIR)/$(basename $@).tex
	echo "\input{last-update}" >> $(OUTDIR)/$(basename $@).tex
	echo "\input{$(VARS)}" >> $(OUTDIR)/$(basename $@).tex
	for f in $(filter %.tex,$^) ; do \
		cp $$f $(OUTDIR)/`basename $$f` ; \
		sed -i 's%__SESSION_NAME__%$(SLIDES_MATERIALS)%' $(OUTDIR)/`basename $$f` ; \
		printf "\input{%s}\n" `basename $$f .tex` >> $(OUTDIR)/$(basename $@).tex ; \
	done
	cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(PDFLATEX_OPT) $(basename $@).tex > output.log 2>&1; \
	STATUS=$$?; \
	if [ $$STATUS -ne 0 ]; then \
		cat output.log; \
	fi; \
	exit $$STATUS
# The second call to pdflatex is to be sure that we have a correct table of
# content and index
	(cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(PDFLATEX_OPT) $(basename $@).tex)
# We use cat to overwrite the final destination file instead of mv, so
# that evince notices that the file has changed and automatically
# reloads it (which doesn't happen if we use mv here). This is called
# 'Maxime's feature'.
	cat out/$@ > $@
else
FORCE:
%-slides.pdf: FORCE
	@$(MAKE) $@ SLIDES=$*
endif

#
# === Compilation of labs ===
#

ifdef LABS
ifeq ($(firstword $(subst -, , $(LABS))),full)
LABS_MATERIALS     = $(strip $(subst -labs, , $(subst full-, , $(LABS))))
LABS_HEADER        = common/labs-header.tex
LABS_VARSFILE      = common/labs-vars/$(LABS_MATERIALS)-labs-vars.tex
LABS_CHAPTERS      = $($(call UPPERCASE, $(subst  -,_, $(LABS_MATERIALS)))_LABS)
LABS_FOOTER        = common/labs-footer.tex
else
LABS_MATERIALS     = $(firstword $(subst -, , $(LABS)))
LABS_HEADER        = common/single-lab-header.tex
LABS_VARSFILE      = common/labs-vars/single-lab-vars.tex
LABS_CHAPTERS      = $(LABS)
LABS_FOOTER        = common/labs-footer.tex
endif

MATERIALS           = $(LABS_MATERIALS)

# Compute the set of corresponding .tex files and pictures
LABS_TEX      = \
	$(LABS_VARSFILE) \
	$(LABS_HEADER) \
	$(foreach s,$(LABS_CHAPTERS),$(wildcard labs/$(s)/$(s).tex)) \
	$(LABS_FOOTER)
LABS_PICTURES = $(call PICTURES,$(foreach s,$(LABS_CHAPTERS),labs/$(s))) $(COMMON_PICTURES)

# Check for all labs .tex file to exist
$(foreach file,$(LABS_TEX),$(if $(wildcard $(file)),,$(error Missing file $(file) !)))

%-labs.pdf: common/sty/labs.sty $(VARS) $(LABS_TEX) $(LABS_PICTURES) $(OUTDIR)/last-update.tex
	@mkdir -p $(OUTDIR)
# We generate a .tex file with \input{} directives (instead of just
# concatenating all files) so that when there is an error, we are
# pointed at the right original file and the right line in that file.
	rm -f $(OUTDIR)/$(basename $@).tex
	echo "\input{last-update}" >> $(OUTDIR)/$(basename $@).tex
	echo "\input{$(VARS)}" >> $(OUTDIR)/$(basename $@).tex
	for f in $(filter %.tex,$^) ; do \
		cp $$f $(OUTDIR)/`basename $$f` ; \
		sed -i 's%__SESSION_NAME__%$(LABS_MATERIALS)%' $(OUTDIR)/`basename $$f` ; \
		printf "\input{%s}\n" `basename $$f .tex` >> $(OUTDIR)/$(basename $@).tex ; \
	done
	cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex > output.log 2>&1; \
	STATUS=$$?; \
	if [ $$STATUS -ne 0 ]; then \
		cat output.log; \
	fi; \
	exit $$STATUS
# The second call to pdflatex is to be sure that we have a correct table of
# content and index
	(cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex)
# We use cat to overwrite the final destination file instead of mv, so
# that evince notices that the file has changed and automatically
# reloads it (which doesn't happen if we use mv here). This is called
# 'Maxime's feature'.
	cat out/$@ > $@
else
FORCE:
%-labs.pdf: FORCE
	@$(MAKE) $@ LABS=$*
endif

#
# === Compilation of thesis ===
#

ifdef THESIS
ifeq ($(firstword $(subst -, , $(THESIS))),full)
THESIS_MATERIALS     = $(strip $(subst -thesis, , $(subst full-, , $(THESIS))))
THESIS_HEADER        = common/thesis-header.tex
THESIS_VARSFILE      = common/thesis-vars/$(THESIS_MATERIALS)-thesis-vars.tex
THESIS_CHAPTERS      = $($(call UPPERCASE, $(subst  -,_, $(THESIS_MATERIALS)))_THESIS)
THESIS_FOOTER        = common/thesis-footer.tex
else
THESIS_MATERIALS     = $(firstword $(subst -, , $(THESIS)))
THESIS_HEADER        = common/thesis-header.tex
THESIS_VARSFILE      = common/thesis-vars/single-thesis-vars.tex
ifeq ($(words $(subst -, ,$(THESIS))),1)
	THESIS_CHAPTERS  = $(THESIS)
	THESIS_TITLE     =
else
	THESIS_CHAPTERS  = $(lastword $(subst -, ,$(THESIS)))
	THESIS_TITLE     = $(strip $(subst -$(THESIS_CHAPTERS), , $(THESIS)))/
endif
THESIS_FOOTER        = common/thesis-footer.tex
endif

MATERIALS           = $(THESIS_MATERIALS)

# Compute the set of corresponding .tex files and pictures
THESIS_TEX      = \
	$(THESIS_VARSFILE) \
	$(THESIS_HEADER) \
	$(foreach s,$(THESIS_CHAPTERS),$(wildcard thesis/$(THESIS_TITLE)$(s)/$(s).tex)) \
	$(THESIS_FOOTER)
THESIS_PICTURES = $(call PICTURES,$(foreach s,$(THESIS_CHAPTERS),thesis/$(THESIS_TITLE)$(s))) $(COMMON_PICTURES)

# Check for all thesis .tex file to exist
$(foreach file,$(THESIS_TEX),$(if $(wildcard $(file)),,$(error Missing file $(file) !)))

%-thesis.pdf: common/sty/bkthesis.sty $(VARS) $(THESIS_TEX) $(THESIS_PICTURES) $(OUTDIR)/last-update.tex
	@mkdir -p $(OUTDIR)
# We generate a .tex file with \input{} directives (instead of just
# concatenating all files) so that when there is an error, we are
# pointed at the right original file and the right line in that file.
	rm -f $(OUTDIR)/$(basename $@).tex
	echo "\input{last-update}" >> $(OUTDIR)/$(basename $@).tex
	echo "\input{$(VARS)}" >> $(OUTDIR)/$(basename $@).tex
	for f in $(filter %.tex,$^) ; do \
		cp $$f $(OUTDIR)/`basename $$f` ; \
		sed -i 's%__SESSION_NAME__%$(THESIS_MATERIALS)%' $(OUTDIR)/`basename $$f` ; \
		printf "\input{%s}\n" `basename $$f .tex` >> $(OUTDIR)/$(basename $@).tex ; \
	done
	cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex > output.log 2>&1; \
	STATUS=$$?; \
	if [ $$STATUS -ne 0 ]; then \
		cat output.log; \
	fi; \
	exit $$STATUS
# The second call to pdflatex is to be sure that we have a correct table of
# content and index
	(cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex)
# We use cat to overwrite the final destination file instead of mv, so
# that evince notices that the file has changed and automatically
# reloads it (which doesn't happen if we use mv here). This is called
# 'Maxime's feature'.
	cat out/$@ > $@
else
FORCE:
%-thesis.pdf: FORCE
	@$(MAKE) $@ THESIS=$*
endif

#
# === Compilation of books ===
#

ifdef BOOKS
ifeq ($(firstword $(subst -, , $(BOOKS))),full)
BOOKS_MATERIALS     = $(strip $(subst -books, , $(subst full-, , $(BOOKS))))
BOOKS_HEADER        = common/books-header.tex
BOOKS_VARSFILE      = common/books-vars/$(BOOKS_MATERIALS)-books-vars.tex
BOOKS_CHAPTERS      = $($(call UPPERCASE, $(subst  -,_, $(BOOKS_MATERIALS)))_BOOKS)
BOOKS_FOOTER        = common/books-footer.tex
else
BOOKS_MATERIALS     = $(firstword $(subst -, , $(BOOKS)))
BOOKS_HEADER        = common/books-header.tex
BOOKS_VARSFILE      = common/books-vars/single-books-vars.tex
ifeq ($(words $(subst -, ,$(BOOKS))),1)
	BOOKS_CHAPTERS  = $(BOOKS)
	BOOKS_TITLE     =
else
	BOOKS_CHAPTERS  = $(lastword $(subst -, ,$(BOOKS)))
	BOOKS_TITLE     = $(strip $(subst -$(BOOKS_CHAPTERS), , $(BOOKS)))/
endif
BOOKS_FOOTER        = common/books-footer.tex
endif

MATERIALS           = $(BOOKS_MATERIALS)

# Compute the set of corresponding .tex files and pictures
BOOKS_TEX      = \
	$(BOOKS_VARSFILE) \
	$(BOOKS_HEADER) \
	$(foreach s,$(BOOKS_CHAPTERS),$(wildcard books/$(BOOKS_TITLE)$(s)/$(s).tex)) \
	$(BOOKS_FOOTER)
BOOKS_PICTURES = $(call PICTURES,$(foreach s,$(BOOKS_CHAPTERS),books/$(BOOKS_TITLE)$(s))) $(COMMON_PICTURES)

# Check for all books .tex file to exist
$(foreach file,$(BOOKS_TEX),$(if $(wildcard $(file)),,$(error Missing file $(file) !)))

%-books.pdf: common/sty/books.sty common/sty/dissertation.cls $(VARS) $(BOOKS_TEX) $(BOOKS_PICTURES) $(OUTDIR)/last-update.tex
	@mkdir -p $(OUTDIR)
# We generate a .tex file with \input{} directives (instead of just
# concatenating all files) so that when there is an error, we are
# pointed at the right original file and the right line in that file.
	rm -f $(OUTDIR)/$(basename $@).tex
	echo "\input{last-update}" >> $(OUTDIR)/$(basename $@).tex
	echo "\input{$(VARS)}" >> $(OUTDIR)/$(basename $@).tex
	for f in $(filter %.tex,$^) ; do \
		cp $$f $(OUTDIR)/`basename $$f` ; \
		sed -i 's%__SESSION_NAME__%$(BOOKS_MATERIALS)%' $(OUTDIR)/`basename $$f` ; \
		printf "\input{%s}\n" `basename $$f .tex` >> $(OUTDIR)/$(basename $@).tex ; \
	done
	cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex > output.log 2>&1; \
	STATUS=$$?; \
	if [ $$STATUS -ne 0 ]; then \
		cat output.log; \
	fi; \
	exit $$STATUS
# The second call to pdflatex is to be sure that we have a correct table of
# content and index
	(cd $(OUTDIR); $(PDFLATEX_ENV) $(PDFLATEX) $(basename $@).tex)
# We use cat to overwrite the final destination file instead of mv, so
# that evince notices that the file has changed and automatically
# reloads it (which doesn't happen if we use mv here). This is called
# 'Maxime's feature'.
	cat out/$@ > $@
else
FORCE:
%-books.pdf: FORCE
	@$(MAKE) $@ BOOKS=$*
endif

#
# === Last update file generation ===
#
$(OUTDIR)/last-update.tex: FORCE
	mkdir -p $(@D)
	t=`git log -1 --format=%ct` && printf "\def \lastupdateen{%s}\n" "`(LANG=en_EN.UTF-8 date -d @$${t} +'%B %d, %Y')`" > $@

#
# === Picture generation ===
#

.PRECIOUS: $(OUTDIR)/%.pdf

$(OUTDIR)/%.pdf: %.svg
	@printf "%-15s%-20s->%20s\n" INKSCAPE $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
ifeq ($(V),)
	$(INKSCAPE) -D $(INKSCAPE_PDF_OPT) $@ $< > /dev/null 2>&1
else
	$(INKSCAPE) -D $(INKSCAPE_PDF_OPT) $@ $<
endif

$(OUTDIR)/%.pdf: $(OUTDIR)/%.eps
	@printf "%-15s%-20s->%20s\n" EPSTOPDF $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
	$(EPSTOPDF) --outfile=$@ $^

.PRECIOUS: $(OUTDIR)/%.eps

$(OUTDIR)/%.eps: %.dia
	@printf "%-15s%-20s->%20s\n" DIA $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
	$(DIA) -e $@ -t eps $^

.PRECIOUS: $(OUTDIR)/%.png

$(OUTDIR)/%.png: %.png
	@mkdir -p $(dir $@)
	@cp $^ $@

.PRECIOUS: $(OUTDIR)/%.jpg

$(OUTDIR)/%.jpg: %.jpg
	mkdir -p $(dir $@)
	@cp $^ $@

$(OUTDIR)/%.pdf: %.pdf
	mkdir -p $(dir $@)
	@cp $^ $@

#
# === Misc targets ===
#

$(VARS): FORCE
	@mkdir -p $(dir $@)
	/bin/echo "\def \materials {$(MATERIALS)}" >> $@

#
# ===================================
#
default: help

clean:
	$(RM) -rf $(OUTDIR) *.pdf *-labs *.xz

ALL_MATERIALS = $(sort $(patsubst %.mk,%,$(notdir $(wildcard mk/*.mk mk/**/*.mk))))

ALL_SLIDES = $(foreach p,$(ALL_MATERIALS),$(if $($(call UPPERCASE,$(p)_SLIDES)),full-$(p)-slides.pdf))
ALL_LABS = $(foreach p,$(ALL_MATERIALS),$(if $($(call UPPERCASE,$(p)_LABS)),full-$(p)-labs.pdf))
ALL_THESIS = $(foreach p,$(ALL_MATERIALS),$(if $($(call UPPERCASE,$(p)_THESIS)),full-$(p)-thesis.pdf))
ALL_BOOKS = $(foreach p,$(ALL_MATERIALS),$(if $($(call UPPERCASE,$(p)_BOOKS)),full-$(p)-books.pdf))

all: $(ALL_SLIDES) $(ALL_LABS) $(ALL_THESIS) $(ALL_BOOKS)

list-materials:
	@echo $(ALL_MATERIALS)

HELP_FIELD_FORMAT = " %-72s %s\n"

help:
	@echo "Available targets:"
	@echo
	@echo "Slides:"
	$(foreach p,$(ALL_SLIDES),\
		@printf $(sort $(HELP_FIELD_FORMAT)) "$(p)" "Complete slides for the '$(patsubst full-%-slides.pdf,%,$(p))' material"$(sep))
	@echo
	@echo "Labs:"
	$(foreach p,$(ALL_LABS),\
		@printf $(sort $(HELP_FIELD_FORMAT)) "$(p)" "Complete labs for the '$(patsubst full-%-labs.pdf,%,$(p))' material"$(sep))
	@echo
	@echo "Theses:"
	$(foreach p,$(ALL_THESIS),\
		@printf $(sort $(HELP_FIELD_FORMAT)) "$(p)" "Complete thesis for the '$(patsubst full-%-thesis.pdf,%,$(p))' material"$(sep))
	@echo
	@echo "Books:"
	$(foreach p,$(ALL_BOOKS),\
		@printf $(sort $(HELP_FIELD_FORMAT)) "$(p)" "Complete books for the '$(patsubst full-%-books.pdf,%,$(p))' material"$(sep))
	@echo
	@printf $(HELP_FIELD_FORMAT) "<some-chapter>-slides.pdf" "Slides for a particular chapter in slides/"
	@printf $(HELP_FIELD_FORMAT) "<some-chapter>-labs.pdf" "Labs for a particular chapter in labs/"
	@printf $(HELP_FIELD_FORMAT) "<some-chapter>-thesis.pdf" "Theses for a particular chapter in thesis/"
	@printf $(HELP_FIELD_FORMAT) "<some-chapter>-books.pdf" "Books for a particular chapter in books/"
	@echo
	@printf $(HELP_FIELD_FORMAT) "list-materials" "List all materials"
