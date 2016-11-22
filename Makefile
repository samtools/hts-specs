all: pdf

PDFS =	BCFv1_qref.pdf \
	BCFv2_qref.pdf \
	CRAMv2.1.pdf \
	CRAMv3.pdf \
	CSIv1.pdf \
	SAMv1.pdf \
	SAMtags.pdf \
	tabix.pdf \
	VCFv4.1.pdf \
	VCFv4.2.pdf \
	VCFv4.3.pdf

pdf: $(PDFS:%=new/%)

%.pdf: new/%.pdf
	cp $^ $@

new/CRAMv2.1.pdf: CRAMv2.1.tex new/CRAMv2.1.ver
new/CRAMv3.pdf: CRAMv3.tex new/CRAMv3.ver
new/SAMv1.pdf: SAMv1.tex new/SAMv1.ver
new/SAMtags.pdf: SAMtags.tex new/SAMtags.ver
new/VCFv4.1.pdf: VCFv4.1.tex new/VCFv4.1.ver
new/VCFv4.2.pdf: VCFv4.2.tex new/VCFv4.2.ver
new/VCFv4.3.pdf: VCFv4.3.tex new/VCFv4.3.ver


new/%.pdf: %.tex
	pdflatex --output-directory new $<
	while grep -q 'Rerun to get [a-z-]* right' $*.log; do pdflatex --output-directory new $< || exit; done

new/%.ver: %.tex
	echo "@newcommand*@commitdesc{`git describe --always --dirty`}@newcommand*@headdate{`git rev-list -n1 --format=%aD HEAD $< | sed '1d;s/.*, *//;s/ *[0-9]*:.*//'`}" | tr @ \\ > $@


mostlyclean:
	-cd new && rm -f *.aux *.idx *.log *.out *.toc *.ver

clean: mostlyclean
	-cd new && rm -f $(PDFS)
	-rm -rf _site


.PHONY: all pdf mostlyclean clean
