Copyright and licensing for the different files here varies by host
institution that submitted the tests.

- `test/vcf/*.vcf`:

    The vast bulk of the test files originated from European
    Bioinformatics Institute's vcf-validator:
    https://github.com/EBIvariation/vcf-validator/blob/master/LICENSE

    These are Copyright EBI and the project is Apache 2.0 licensed.
    See https://www.apache.org/licenses/LICENSE-2.0

- `test/vcf/4.*/passed/complexfile_passed_000.vcf`:

    Also present in the EBI vcf-validator, however this data looks to
    be a subset of the 1000 Genomes project so it may be covered by
    the 1000 genomes license instead (i.e. freely available under the
    Fort Lauderdale Agreement).
    See https://www.internationalgenome.org/IGSR_disclaimer
    and https://www.internationalgenome.org/category/data-access/

- `examples/vcf/simple.vcf`:

    Part of commit 7aeed5b, but not from the vcf-validator.
    Unknown copyright / license, but assumed to be 1000 Genomes.

- `examples/vcf/sv44.vcf`:

    Daniel Cameron 2022 0a7c47b

- `test/vcf/4.3/failed/failed_body_format_007.vcf`:

    Daniel Cameron 2023 dbf3f7b

- `test/vcf/4.3/failed/failed_body_info_integer_overflow.vcf`:
- `test/vcf/4.3/failed/failed_body_info_integer_reserved.vcf`:
- `test/vcf/4.3/failed/failed_body_info_integer_underflow.vcf`:

    Daniel Cameron 2023 09a3195

- `test/vcf/4.5/passed/zero_length_LAA.vcf`:

    Daniel Cameron 2024 8589eb6
