# Test files for VCF

This folder contains a "failed/" folder and a "passed/" folder for each VCF
version. They contain test VCF files that can be used to assess correctness of
tools that parse or produce VCF files.

The "failed/" folder contains VCFs that are incorrect according to the VCF spec.
Usually each file has a metadata line explaining what is wrong with it.

The "passed/" folder contains VCFs that should be accepted by tools. Those VCFs
sometimes exercise uncommon scenarios and corner cases. For that reason they are
not good examples for newcomers to learn about VCF. For that, go to the folder
"examples/" at the root folder in this repo.
