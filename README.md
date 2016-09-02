SAM/BAM and related specifications
==================================

Quick links
-----------

<!-- Whitespace at the ends of these lines are Markdown line breaks -->
[HTS-spec GitHub page](http://samtools.github.io/hts-specs/)  
[SAMv1.pdf](http://samtools.github.io/hts-specs/SAMv1.pdf)  
[SAMtags.pdf](http://samtools.github.io/hts-specs/SAMtags.pdf)  
[CRAMv2.1.pdf](http://samtools.github.io/hts-specs/CRAMv2.1.pdf)  
[CRAMv3.pdf](http://samtools.github.io/hts-specs/CRAMv3.pdf)  
[BCFv1.pdf](http://samtools.github.io/hts-specs/BCFv1_qref.pdf)  
[BCFv2.1.pdf](http://samtools.github.io/hts-specs/BCFv2_qref.pdf)  
[CSIv1.pdf](http://samtools.github.io/hts-specs/CSIv1.pdf)  
[tabix.pdf](http://samtools.github.io/hts-specs/tabix.pdf)  
[VCFv4.1.pdf](http://samtools.github.io/hts-specs/VCFv4.1.pdf)  
[VCFv4.2.pdf](http://samtools.github.io/hts-specs/VCFv4.2.pdf)  

Alignment data files
--------------------

**SAMv1.tex** is the canonical specification for the SAM (Sequence Alignment/Map) format, BAM (its binary equivalent), and the BAI format for indexing BAM files.
**SAMtags.tex** is a companion specification describing the predefined standard optional fields and tags found in SAM, BAM, and CRAM files.
These formats are discussed on the [samtools-devel mailing list][samdev-ml].

**CRAMv2.1.tex** and **CRAMv3.tex** are the canonical specifications for the CRAM format.
Further details can be found at [ENA's CRAM toolkit page][ena-cram].
CRAM discussions can also be found on the [samtools-devel mailing list][samdev-ml].

The **tabix.tex** and **CSIv1.tex** quick references summarize more recent index formats: the [tabix] tool indexes generic textual genome position-sorted files, while CSI is [htslib]'s successor to the BAI index format.

Variant calling data files
--------------------------

**VCFv4.1.tex** and **VCFv4.2.tex** are the canonical specifications for the Variant Call Format and its textual (VCF) and binary encodings (BCF 2.x).
These formats are discussed on the [vcftools-spec mailing list][vcfspec-ml].

**BCFv1_qref.tex** summarizes the obsolete BCF1 format historically produced by [samtools].  This format is no longer recommended for use, as it has been superseded by the more widely-implemented BCF2.

**BCFv2_qref.tex** is a quick reference describing just the layout of data within BCF2 files.

[ena-cram]:   http://www.ebi.ac.uk/ena/about/cram_toolkit
[htslib]:     https://github.com/samtools/htslib
[samtools]:   https://github.com/samtools/samtools
[tabix]:      https://github.com/samtools/tabix

[samdev-ml]:  https://lists.sourceforge.net/lists/listinfo/samtools-devel
[vcfspec-ml]: https://lists.sourceforge.net/lists/listinfo/vcftools-spec

<!-- vim:set linebreak: -->
