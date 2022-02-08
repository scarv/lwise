# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

ifndef REPO_HOME
  $(error "execute 'source ./bin/conf.sh' to configure environment")
endif
ifndef REPO_VERSION
  $(error "execute 'source ./bin/conf.sh' to configure environment")
endif

# =============================================================================

BUILD = ${REPO_HOME}/build/slide

%.pdf : %.tex %.sty %.bib
	@mkdir --parents ${BUILD}

	pdflatex -output-directory ${BUILD} ${*}.tex
	biber --input-directory ${BUILD} --output-directory ${BUILD} ${*}
	pdflatex -output-directory ${BUILD} ${*}.tex
	biber --input-directory ${BUILD} --output-directory ${BUILD} ${*}
	pdflatex -output-directory ${BUILD} ${*}.tex

all   : slide.pdf

clean : 
	@rm --force --recursive ${BUILD}

# =============================================================================
