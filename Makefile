SHELL = /bin/sh

# This is a list of all non-source files that are part of the distribution.
AUXFILES = Makefile

# Project directories
SRC = src/
LIB = lib/
STY = styles/
WWW = www/
STATIC = ${WWW}static/
CSS = ${STATIC}css/

# Dist directories.
DISTDIRS = ${DIST} ${PUBLIC} ${PUBSTATIC} ${PUBCSS} ${PUBSTATIC}fonts		\
	${PUBSTATIC}signs ${DIST}etc
DIST = dist/
# All front-end files go in PUBLIC
PUBLIC = ${DIST}PUBLIC/
PUBSTATIC = ${PUBLIC}static/
PUBCSS = ${PUBSTATIC}css/

# elm variables
ELM_MAKEFLAGS = --warn
ELMOUT = index.html
ELMMAIN = ${SRC}main.elm
ELMTARGETS = ${WWW}${ELMOUT}
ELMPATTERN = ${SRC}*.elm

# lessc variables
LESSCFLAGS = --no-ie-compat --verbose
LESSCPATTERN = ${STY}*.less

# bootstrap variables
BSDIR = ${LIB}bootstrap/build/
BSTARGETS :=									\
	$(patsubst								\
		${BSDIR}%,							\
		${STATIC}%,							\
		$(wildcard ${BSDIR}**/*.*))

CSSTARGETS :=									\
	$(filter-out								\
		${CSS}%.min.css ${STATIC}fonts%,				\
		${BSTARGETS})							\
	$(patsubst								\
		${STY}%.less,							\
		${CSS}%.css,							\
		$(wildcard ${STY}*.less))

MINTARGETS = ${CSS}app.min.css

DISTTARGETS = ${DIST}* ${DIST}**/*

all: dist

build: ${ELMTARGETS} ${MINTARGETS}

${ELMTARGETS}: ${ELMPATTERN} | ${STATIC}
	@elm make ${ELMMAIN} --output $@ ${ELM_MAKEFLAGS}

${CSS}%.min.css: ${CSS}%.css
	@yuicompressor -o $@ $<

${STATIC}%: ${BSDIR}%
	@cp $< $@

${MINTARGETS}: ${CSSTARGETS}
	@cat $^ > $@

${CSS}%.css: ${STY}%.less
	@lessc ${LESSCFLAGS} $< $@

lint:
	@lessc ${LESSCFLAGS} -l ${LESSCMAIN}

minify: ${MINTARGETS}

${DISTDIRS}:
	@mkdir -p ${DISTDIRS}

dist: ${DISTDIRS} | build
	@cp ${MINTARGETS} ${PUBCSS}
	@cp ${ELMTARGETS} ${PUBLIC}
	@cp -r ${STATIC}fonts ${PUBSTATIC}
	@cp -r ${STATIC}signs ${PUBSTATIC}
	@cp ${LIB}restheart.jar ${DIST}
	@cp -r etc/ ${DIST}

restheart: | dist
	java -server -jar ${DIST}restheart.jar etc/restheart.yml

watch: | dist
	watchman-make								\
		-p '${ELMPATTERN}' '${LESSCPATTERN}'				\
		-t dist

# Run browser-sync, and have it refresh the browser when
sync: | dist
	browser-sync start							\
		--server "${PUBLIC}"						\
		--port 8000							\
		--ui-port 8001							\
		--reload-delay 500						\
		--no-open							\
		--no-online							\
		--files "${MINTARGETS}, ${ELMTARGETS}"

# Delete all the targets, and for good measure everything in static except the
# pictures.
clean:
	-@$(RM) -r								\
	$(wildcard								\
		${ELMTARGETS}							\
		${CSSTARGETS}							\
		${BSTARGETS}							\
		${MINTARGETS}							\
		${DISTTARGETS})

# Prints the value of a variable on the command line
print-%  : ; @echo $* = $($*)

# Local Variables:
# tab-width: 8
# makefile-backslash-column: 79
# End:
