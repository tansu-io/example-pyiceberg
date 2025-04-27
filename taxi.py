import os

from pyiceberg.catalog import load_catalog

catalog = load_catalog('default', **{
        'uri': 'http://localhost:8181',
        's3.endpoint': 'http://localhost:9000',
        's3.access-key-id': 'minioadmin',
        's3.secret-access-key': 'minioadmin',
    })

table = catalog.load_table("tansu.taxi")

print(table.location())
print(table.schema())

print(table.scan().to_arrow().to_string(preview_cols=10))
