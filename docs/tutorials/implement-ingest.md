### Implement Ingest

Most Koza scripts can run in flat mode, which means that the transform code itself doesn't need to handle the looping mechanism, and instead the transform code will have a row injected at the top and call the write command at the bottom. In between fields from the incoming row should be mapped to Biolink instances. 

##### Imports and setup

Start with the imports, and make sure to set the source_name, which will be used for communicating with the reader and writer.

```python
from biolink_model_pydantic.model import Gene

# The source name is used for reading and writing
source_name = "gene-information"

```

#### Inject the row 

```python
# inject a single row from the source
row = koza_app.get_row(source_name)
```

#### Extras

Next up handle any additional set up for the ingest, such as including a map or bringing in the CURIE cleaning service

```python
curie_cleaner = koza_app.curie_cleaner
eqe2zp = koza_app.get_map("eqe2zp")
translation_table = koza_app.translation_table
```



#### Creating entities 

At this step, hopefully your documentation is so good that you're just letting your fingers take on the last step of converting what you've already planned into Python syntax. Ideally not much logic will be needed here, and if there's a lot, it might be worth considering whether an ingest (even on the same file) can be split across multiple transforms so that each is as easy to read as possible. Aim to add all properties when creating the instance, but in some cases adding optional lists might need to happen below. 

```python

gene = Gene(
    id='somethingbase:'+row['ID'],
    name=row['Name']
)

# populate any additional optional properties
if row['xrefs']:
    gene.xrefs = [curie_cleaner.clean(xref) for xref in row['xrefs']]

```

#### Writing

At the end of the script, call the writer. The first argument must be the source_name (so that it will know where to write), entities should be passed in as additional arguments.

```python

koza_app.write(gene, phenotypicFeature, association)

```

#### Running your ingest

To execute the ingest from outside of a poetry shell:

```bash
poetry run koza transform --global-table monarch_ingest/translation_table.yaml --source monarch_ingest/<YOUR SOURCE>/<YOUR INGEST>.yaml 
```

### Next

[Testing!](test-ingest.md)

This is also a good time to circle back and update the documentation.
