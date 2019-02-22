## Specification maintainers

The SAM, BAM, and VCF formats originated in the 1000 Genomes Project.
In February 2014, ongoing format maintenance was brought under the aegis of the [Global Alliance for Genomics & Health][ga4gh-ff].
At this time, lead maintainers for each of the formats were nominated.
The current maintainers are listed below.

### SAM/BAM

* James Bonfield (@jkbonfield)
* John Marshall (@jmarshall)
* Yossi Farjoun (@yfarjoun)

Past SAM/BAM maintainers include Jay Carey, Tim Fennell, and Nils Homer.

### CRAM

* James Bonfield (@jkbonfield)
* Chris Norman (@cmnbroad)

Past CRAM maintainers include Vadim Zalunin.

### VCF/BCF

* Cristina Yenyxe Gonzalez Garcia (@cyenyxe)
* Louis Bergelson (@lbergelson)
* Petr Danecek (@pd3)

Past VCF/BCF maintainers include Ryan Poplin and David Roazen.

### Htsget

* Mike Lin (@mlin)

### Refget

* Andy Yates (@andrewyatz)
* Matt Laird (@lairdm)

[ga4gh-ff]:  https://www.ga4gh.org/howwework/workstreams/#lsg


## Updating the specifications

Minor editorial fixes where there is no likelihood of controversy may be done directly on the **master** branch.
Larger changes should be proposed as pull requests so that they can be discussed and refined.
(Even those with write access to the **samtools/hts-specs** repository should in general create their pull request branches within their own **hts-specs** forks.
This way when the main repository is forked again, the new fork is created with a minimum of extraneous volatile branches.)


## Generating PDF specification documents

Use the _Makefile_ to generate PDFs from the TeX source documents.
Both TeX source and generated PDFs are checked into the **master** branch, so the make rules are set up to stage PDFs into a _new/_ subdirectory, from where they can be copied when you are ready to check them in.

Most of the specifications use a _.ver_ file and associated rules to display a commit hash and datestamp on their title page.
(See _SAMv1.tex_ and _new/SAMv1.pdf_'s _Makefile_ dependencies for how to add this to other specifications.)
So the usual workflow when editing these documents is (for example, when working on the SAM specification):

1. Edit _SAMv1.tex_, and type `make new/SAMv1.pdf` to generate a working PDF to preview your work.

2. When you are ready, commit your _.tex_ source changes (but don't commit any changed PDF files yet).

3. Type `make clean SAMv1.pdf` to regenerate the PDF and copy it to the main directory.
(Optionally, verify that it contains the correct commit hash for your source changes.)
Now commit your _.pdf_ changes, separately from any source changes.

### Customising the build

You may wish to create a file named _GNUmakefile_ (which GNU Make will read in preference to _Makefile_) as follows:

```make
include Makefile

PDFLATEX = texfot pdflatex

%+test.pdf: new/%.pdf
	cp $^ $@
```

Using `texfot` (where available) hides many of TeX's less interesting log messages.
Adding a rule for individualised PDF filenames allows you to type e.g. `make SAMv1+test.pdf` to generate distinctively-named working PDFs in the main directory.
If you are working on separate changes in several _hts-specs_ directories at once, using different filenames for each directory helps identify which PDFs you're viewing.

### Rationale

It is a little inconvenient having the working PDFs down in a subdirectory, but this is outweighed by the convenience of being able to switch between Git branches etc without trouble — as there would be if updated working PDFs were in the main directory, overwriting the checked-in PDFs.

The intention is that the commit hash embedded in a PDF encompasses all the source changes and commits that contribute to that PDF.
The hash of the particular commit that updates the PDF is of course not yet known when the PDF is being generated, so the best that can be done is the hash of a slightly-previous commit.
Therefore:
* The PDF needs to be committed separately from the corresponding TeX source changes.
* The PDF should not be updated in a merge commit (as commits from one or the other of the merge's parents will not be recorded), and there's not much point updating it in a pull request.
* So pull requests need to be merged, and then their PDFs updated separately as a non-merge commit on **master**.
* If a series of changes are being made or several pull requests are being merged at once, the PDF updates can be batched up and just made once at the end.
(Sometimes anticipated changes become delayed.
When PDF updates have been pending awaiting other changes for **one week**, they should be committed without waiting further.)
* Conversely, if there are changes pending to several (even unrelated) PDFs, there is no reason not to commit them all at once.

<!-- vim:set linebreak: -->
