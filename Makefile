# ====================================================================
#  LaTeX Application Kit: build commands
# ====================================================================
#  make all    APP=example-uni MODE=academia     every document the form switches on + packet
#  make letter APP=example-tech MODE=tech        just the cover letter
#  make letter APP=example-tech MODE=tech DRAFT=1   tailored text highlighted, watermark on
#  make new    APP=spook-street-insider-risk     start a new form from the blank one
#  make help                                     everything else
#
#  PDFs land in output/<APP>/. Build litter goes to build/ and can be
#  deleted any time (make clean).
# ====================================================================

APP    ?= example-tech
MODE   ?= tech
DRAFT  ?= 0
PREFIX ?= Lamb_            # put your surname here: files come out as Lamb_Cover_Letter.pdf

PREFIX  := $(strip $(PREFIX))
FORM    := applications/$(APP).tex
OUT     := output/$(APP)
BUILD   := build/$(APP)
LATEXMK := latexmk -xelatex -interaction=nonstopmode -halt-on-error -file-line-error -silent

ifeq ($(DRAFT),1)
  DRAFTDEF := \def\draftmode{1}
endif

# --------------------------------------------------------------------
# How the knobs reach LaTeX
#   Each build writes a one-line wrapper next to the source, e.g.
#     \def\letterfile{example-tech}\def\covermode{tech}\input{cover_letter}
#   and compiles that. The document's own \providecommand defaults are
#   then skipped, and because the wrapper sits in the same folder,
#   every relative \input in the document still works.
#
#   $(call build,<folder>,<source>,<output name>,<extra \defs>)
# --------------------------------------------------------------------
define build
	@test -f $(FORM) || { echo "No form at $(FORM). Try: make new APP=$(APP)"; exit 1; }
	@mkdir -p $(OUT) $(BUILD)
	@printf '%s\\def\\letterfile{%s}\\def\\fileprefix{%s}%s\\input{%s}\n' \
	  '$(DRAFTDEF)' '$(APP)' '$(PREFIX)' '$(4)' '$(2)' > $(1)/_wrapper-$(2).tex
	@cd $(1) && $(LATEXMK) -jobname=$(PREFIX)$(3) -outdir=../$(BUILD) _wrapper-$(2).tex; \
	  status=$$?; rm -f _wrapper-$(2).tex; \
	  if [ $$status -ne 0 ]; then echo "Build failed. Log: $(BUILD)/$(PREFIX)$(3).log"; exit $$status; fi
	@cp $(BUILD)/$(PREFIX)$(3).pdf $(OUT)/
	@echo "  -> $(OUT)/$(PREFIX)$(3).pdf"
endef

# Is a document switched on (yes) in section 9 of the form?
on = grep -q '\\$(1)}{yes}' $(FORM)

.PHONY: help letter research teaching diversity service statements samples packet all new list clean distclean sample-files examples

help:
	@echo "Documents (APP = form under applications/, MODE = letter style):"
	@echo "  make letter     APP=<form> MODE=<mode>   cover letter"
	@echo "  make research   APP=<form>               research statement"
	@echo "  make teaching   APP=<form>               teaching statement"
	@echo "  make diversity  APP=<form>               diversity statement"
	@echo "  make service    APP=<form>               service statement"
	@echo "  make statements APP=<form>               all four statements"
	@echo "  make samples    APP=<form>               writing samples"
	@echo "  make all        APP=<form> MODE=<mode>   everything switched on in the form + packet"
	@echo "  add DRAFT=1 to any of these to highlight the tailored text"
	@echo ""
	@echo "Housekeeping:"
	@echo "  make new APP=<name>   copy the blank form to applications/<name>.tex"
	@echo "  make list             show forms and modes"
	@echo "  make clean            delete build/ (keeps PDFs)"
	@echo "  make distclean        delete build/ and output/"
	@echo ""
	@echo "Modes: academia  postdoc  tech  consulting  intorg"

letter:
	$(call build,cover_letter,cover_letter,Cover_Letter,\def\covermode{$(MODE)})

research:
	$(call build,statements,research_statement,Research_Statement,)

teaching:
	$(call build,statements,teaching_statement,Teaching_Statement,)

diversity:
	$(call build,statements,diversity_statement,Diversity_Statement,)

service:
	$(call build,statements,service_statement,Service_Statement,)

statements: research teaching diversity service

samples:
	$(call build,writing_samples,writing_samples,Writing_Samples,)

# Builds each document switched on in the form, then merges them.
packet:
	@test -f $(FORM) || { echo "No form at $(FORM). Try: make new APP=$(APP)"; exit 1; }
	@if $(call on,packetletter);   then $(MAKE) --no-print-directory letter;   fi
	@if $(call on,packetresearch); then $(MAKE) --no-print-directory research; fi
	@if $(call on,packetteaching); then $(MAKE) --no-print-directory teaching; fi
	@if $(call on,packetdiversity); then $(MAKE) --no-print-directory diversity; fi
	@if $(call on,packetservice);  then $(MAKE) --no-print-directory service;  fi
	@if $(call on,packetsamples);  then $(MAKE) --no-print-directory samples;  fi
	$(call build,packet,application_packet,Application_Packet,)

all: packet

new:
	@if [ -f $(FORM) ]; then echo "$(FORM) already exists"; exit 1; fi
	@cp applications/_blank_form.tex $(FORM)
	@echo "Created $(FORM). Fill it in, then: make all APP=$(APP) MODE=<mode>"

list:
	@echo "Forms (APP=):"; ls applications | sed -n 's/\.tex$$//p' | grep -v '^_' | sed 's/^/  /'
	@echo "Modes (MODE=):"; ls cover_letter/modes | sed 's/^/  /'

clean:
	rm -rf build

distclean: clean
	rm -rf output

# --------------------------------------------------------------------
# Maintenance: rebuild the placeholder PDFs and the README images
# --------------------------------------------------------------------
sample-files:
	@cd sample_files && for f in sample_resume sample_cv sample_article sample_chapter; do \
	  $(LATEXMK) -outdir=../build/sample_files $$f.tex && cp ../build/sample_files/$$f.pdf . ; done

# Needs pdftoppm (poppler) for the PNG.
examples:
	@$(MAKE) --no-print-directory letter APP=_blank_form MODE=tech PREFIX=
	@$(MAKE) --no-print-directory letter APP=example-tech MODE=tech PREFIX= DRAFT=1
	@$(MAKE) --no-print-directory all APP=example-uni MODE=academia
	@mkdir -p examples
	cp output/_blank_form/Cover_Letter.pdf examples/generic_letter.pdf
	cp output/example-tech/Cover_Letter.pdf examples/tailored_letter_draft.pdf
	cp output/example-uni/$(PREFIX)Application_Packet.pdf examples/example-uni_packet.pdf
	cd examples && $(LATEXMK) -outdir=../build/examples before_after.tex
	pdftoppm -png -r 110 -singlefile build/examples/before_after.pdf examples/before_after
