---
layout: default
title: HTS format specifications
---
{% capture newline %}
{% endcapture %}
{% capture readme %}{% include_relative README.md %}{% endcapture %}
{% assign readme_lines = readme | split: newline %}

{% for line in readme_lines limit: 2 %}
{{line}}{% endfor %}

<div class="sidebar lowered">
Specifications:

- [SAM v1](SAMv1.pdf)
- [SAM tags](SAMtags.pdf)
- [CRAM v2.1](CRAMv2.1.pdf)
- [CRAM v3](CRAMv3.pdf)
- [BCF v1](BCFv1_qref.pdf)
- [BCF v2.1](BCFv2_qref.pdf)
- [CSI v1](CSIv1.pdf)
- [Tabix](tabix.pdf)
- [VCF v4.1](VCFv4.1.pdf)
- [VCF v4.2](VCFv4.2.pdf)
- [VCF v4.3](VCFv4.3.pdf)
- [crypt4gh](crypt4gh.pdf)
- [Htsget](htsget.html)
- [Refget](refget.html)
</div>
<div class="mainbar">
{% for line in readme_lines offset: 8 %}
{{line}}{% endfor %}
</div>
<div class="clear"></div>
