XSLT=/sourceforge/docbook/cvstools/xslt --processor=xsltproc
TIDY=/sourceforge/docbook/cvstools/untidy
HTMLXSL=style/mtw.xsl
HTMLCHUNK=style/chunk.xsl

SOURCE=mtw.xml
BASEDIR=html/
ROOTID=
XSLPARAM=

all:
	echo Choose a target: mtw.html or chunks

mtw.html: mtw.xml
	$(XSLT) $< $(HTMLXSL) $@
	$(TIDY) -iq -latin1 -mn -asxml $@

chunks:
	$(XSLT) $(SOURCE) $(HTMLCHUNK) base.dir=$(BASEDIR) $(XSLPARAM)
	$(TIDY) -iq -latin1 -mn -asxml $(BASEDIR)*.html
