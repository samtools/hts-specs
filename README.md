SAM/BAM and related specifications
==================================

Alignment data files
--------------------

**SAMv1.tex** is the canonical specification for the SAM (Sequence Alignment/Map) format, BAM (its binary equivalent), and the BAI format for indexing BAM files.

The CRAM format is described at [ENA's CRAM toolkit page][ena-cram].

The **tabix.tex** and **CSIv1.tex** quick references summarize more recent index formats: the [tabix] tool indexes generic textual genome position-sorted files, while CSI is [htslib]'s successor to the BAI index format.

Variant calling data files
--------------------------

**VCFv4.1.tex** and **VCFv4.2.tex** are the canonical specifications for the Variant Call Format and its textual (VCF) and binary encodings (BCF 2.x).

**BCFv1_qref.tex** summarizes the obsolete BCF1 format historically produced by [samtools].  This format is no longer recommended for use, as it has been superseded by the more widely-implemented BCF2.

**BCFv2_qref.tex** is a quick reference describing just the layout of data within BCF2 files.

[ena-cram]:   http://www.ebi.ac.uk/ena/about/cram_toolkit
[htslib]:     https://github.com/samtools/htslib
[samtools]:   https://github.com/samtools/samtools
[tabix]:      https://github.com/samtools/tabix

<!-- vim:set linebreak: -->
