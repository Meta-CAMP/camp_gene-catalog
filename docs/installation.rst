.. highlight:: shell

============
Installation
============


Stable release
--------------

1. Clone repo from `github <https://github.com/b-tierney/camp_enzymetrics_protein_catalog>_`. 

2. Set up the conda environment (contains, Snakemake) using ``configs/conda/camp_enzymetrics_protein_catalog.yaml``. 

3. Make sure the installed pipeline works correctly. ``pytest`` only generates temporary outputs so no files should be created.
::
    cd camp_enzymetrics_protein_catalog
    conda env create -f configs/conda/camp_enzymetrics_protein_catalog.yaml
    conda activate camp_enzymetrics_protein_catalog
    pytest .tests/unit/

