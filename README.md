SAM/BAM and related specifications
==================================

These documents are maintained by the Large Scale Genomics work stream of the Global Alliance for Genomics & Health ([GA4GH][GA4GH.org]).
Information on GA4GH procedures and how to get involved is [available here][LSG-wiki].
Lists of contributors and acknowledgements can generally be found in each individual specification document.

Links **in bold** point to the corresponding PDFs on this repository's [GitHub Pages website][hts-specs].

Please request improvements or report errors using this repository, but see also [the list of maintainers](MAINTAINERS.md) if you need to contact them directly.
See the [build instructions](MAINTAINERS.md#generating-pdf-specification-documents) for an explanation of how to generate the PDF documents from their source text.

Alignment data files
--------------------

**[SAMv1.tex]** is the canonical specification for the SAM (Sequence Alignment/Map) format, BAM (its binary equivalent), and the BAI format for indexing BAM files.
**[SAMtags.tex]** is a companion specification describing the predefined standard optional fields and tags found in SAM, BAM, and CRAM files.
These formats are discussed on the [samtools-devel mailing list][samdev-ml].

**[CRAMv3.tex]** is the canonical specification for the CRAM format, while **[CRAMv2.1.tex]** describes its now-obsolete predecessor.
**[CRAMcodecs.tex]** contains details of the CRAM custom compression codecs.
Further details can be found at [ENA's CRAM toolkit page][ena-cram] and [GA4GH's CRAM page][ga4gh-cram].
CRAM discussions can also be found on the [samtools-devel mailing list][samdev-ml].

The **[tabix.tex]** and **[CSIv1.tex]** quick references summarize more recent index formats: the tabix tool indexes generic textual genome position-sorted files, while CSI is [htslib]'s successor to the BAI index format.

### Unaligned sequence data files

We do not define or endorse any dedicated unaligned sequence data format.
Instead we recommend storing such data in one of the alignment formats (SAM, BAM, or CRAM) with the unmapped flag set.
However for completeness, we list the commonest formats below with external links.

[FASTA] is an early sequence-only format originally defined by William Pearson's tool of the same name.

[FASTQ] was designed as a replacement for FASTA, combining the sequence and quality information in the same file.
It has no formal definition and several incompatible variants, but is described in a paper by Cock et al.

Variant calling data files
--------------------------

**[VCFv4.5.tex]** is the canonical specification for the Variant Call Format and its textual (VCF) and binary (BCF) encodings, while **[VCFv4.1.tex]**, **[VCFv4.2.tex]**, **[VCFv4.3.tex]** and **[VCFv4.4.tex]** describe their predecessors.
These formats are discussed on the [vcftools-spec mailing list][vcfspec-ml].

**[BCFv1_qref.tex]** summarizes the obsolete BCF1 format historically produced by [samtools].  This format is no longer recommended for use, as it has been superseded by the more widely-implemented BCF2.

**[BCFv2_qref.tex]** is a quick reference describing just the layout of data within BCF2 files.

Discrete genomic feature data files
-----------------------------------

**[BEDv1.tex]** is the canonical specification for the GA4GH Browser Extensible Data (BED) format.

File encryption
---------------

**[crypt4gh.tex]** is the canonical specification of the crypt4gh format which can be used to wrap existing file formats in an encryption layer.

Transfer protocols
------------------

**[Htsget.md]** describes the _hts-get_ retrieval protocol, which enables parallel streaming access to data sharded across multiple URLs or files.

**[Refget.md]** enables access to reference sequences using an identifier derived from the sequence itself.

[GA4GH.org]:    https://www.ga4gh.org/
[LSG-wiki]:     https://github.com/ga4gh/large-scale-genomics-wiki/wiki

[SAMv1.tex]:    http://samtools.github.io/hts-specs/SAMv1.pdf
[SAMtags.tex]:  http://samtools.github.io/hts-specs/SAMtags.pdf
[CRAMv2.1.tex]: http://samtools.github.io/hts-specs/CRAMv2.1.pdf
[CRAMv3.tex]:   http://samtools.github.io/hts-specs/CRAMv3.pdf
[CRAMcodecs.tex]: http://samtools.github.io/hts-specs/CRAMcodecs.pdf
[CSIv1.tex]:    http://samtools.github.io/hts-specs/CSIv1.pdf
[tabix.tex]:    http://samtools.github.io/hts-specs/tabix.pdf
[VCFv4.1.tex]:  http://samtools.github.io/hts-specs/VCFv4.1.pdf
[VCFv4.2.tex]:  http://samtools.github.io/hts-specs/VCFv4.2.pdf
[VCFv4.3.tex]:  http://samtools.github.io/hts-specs/VCFv4.3.pdf
[VCFv4.4.tex]:  http://samtools.github.io/hts-specs/VCFv4.4.pdf
[VCFv4.5.tex]: https://samtools.github.io/hts-specs/VCFv4.5.pdf
[BCFv1_qref.tex]: http://samtools.github.io/hts-specs/BCFv1_qref.pdf
[BCFv2_qref.tex]: http://samtools.github.io/hts-specs/BCFv2_qref.pdf
[BEDv1.tex]:    https://samtools.github.io/hts-specs/BEDv1.pdf
[crypt4gh.tex]: http://samtools.github.io/hts-specs/crypt4gh.pdf
[Htsget.md]:    http://samtools.github.io/hts-specs/htsget.html
[Refget.md]:    https://samtools.github.io/hts-specs/refget.html

[ena-cram]:   http://www.ebi.ac.uk/ena/about/cram_toolkit
[ga4gh-cram]: https://www.ga4gh.org/cram/
[htslib]:     https://github.com/samtools/htslib
[samtools]:   https://github.com/samtools/samtools
[hts-specs]:  http://samtools.github.io/hts-specs/

[samdev-ml]:  https://lists.sourceforge.net/lists/listinfo/samtools-devel
[vcfspec-ml]: https://lists.sourceforge.net/lists/listinfo/vcftools-spec

[FASTA]:      https://en.wikipedia.org/wiki/FASTA_format
[FASTQ]:      https://academic.oup.com/nar/article/38/6/1767/3112533

<!-- vim:set linebreak: -->
