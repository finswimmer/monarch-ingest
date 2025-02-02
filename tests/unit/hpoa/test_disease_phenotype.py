import pytest
from biolink_model_pydantic.model import (
    Disease,
    DiseaseToPhenotypicFeatureAssociation,
    PhenotypicFeature,
    Publication,
)


@pytest.fixture
def entities(mock_koza, global_table):
    row = iter(
        [
            {
                "DatabaseID": "OMIM:614856",
                "DiseaseName": "Osteogenesis imperfecta, type XIII",
                "Qualifier": "",
                "HPO_ID": "HP:0000343",
                "Reference": "OMIM:614856",
                "Evidence": "TAS",
                "Onset": "",
                "Frequency": "HP:0040283",
                "Sex": "",
                "Modifier": "",
                "Aspect": "P",
                "Biocuration": "HPO:skoehler[2012-11-16]",
            }
        ]
    )
    return mock_koza(
        name="hpoa_disease_phenotype",
        data=row,
        transform_code="./monarch_ingest/hpoa/disease_phenotype.py",
        global_table=global_table,
        local_table="./monarch_ingest/hpoa/hpoa-translation.yaml",
    )


def test_gene2_phenotype_transform(entities):
    assert entities
    assert len(entities) == 2
    [entity for entity in entities if isinstance(entity, Disease)]
    [entity for entity in entities if isinstance(entity, PhenotypicFeature)]
    [entity for entity in entities if isinstance(entity, Publication)]
    associations = [
        entity
        for entity in entities
        if isinstance(entity, DiseaseToPhenotypicFeatureAssociation)
    ]
    # assert len(diseases) == 1
    # assert len(phenotypes) == 1
    # assert len(publications) == 1
    assert len(associations) == 1


def test_disease_phenotype_transform_publications(entities):
    associations = [
        entity
        for entity in entities
        if isinstance(entity, DiseaseToPhenotypicFeatureAssociation)
    ]
    assert associations[0].publications[0] == "OMIM:614856"
